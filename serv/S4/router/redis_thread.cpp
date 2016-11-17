#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hiredis/hiredis.h"
#include "hiredis/async.h"
#include "ae/ae.h"
#include <pthread.h>
#include "router.h"
#include "cfunction.h"


// 注：文件名里有 thread，但是这个 thread是概念上的，非OS thread 


#define IP_LEN 32
#define MAX_REDIS_SERVER 32
struct RedisThreadData{
	struct one_server_info{
		char IP[IP_LEN];
		int port;
		uint16_t stat;
		uint16_t padding;
		void* redis_handle;
		void* reply;
	};
	struct one_server_info a_server[MAX_REDIS_SERVER];
	
	uint16_t thread_stat;
	uint16_t to_end;
};

enum one_server_stat{
	one_server_stat_empty = 0,
	one_server_stat_just_add = 1,
	one_server_stat_opening = 2,
	one_server_stat_running = 3,
	one_server_stat_to_close = 4,
	one_server_stat_has_error = 99,
};

RedisThreadData* getRTD()
{
	static RedisThreadData* rtd = NULL;
	if(NULL == rtd){
		rtd = (RedisThreadData*)calloc(1,sizeof(RedisThreadData));
	}
	
	return rtd;
}

static aeEventLoop *ae_loop = NULL;

int time_cb(struct aeEventLoop *l,long long id,void *data)
{
    return 5*1000;
}

void fin_cb(struct aeEventLoop *l,void *data)
{
}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;
    }

    printf("Connected...\n");
}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;
    }

    printf("Disconnected...\n");
}

void aeFileCallback(struct aeEventLoop *eventLoop, int fd, void *clientData, int mask)
{
	redisAsyncContext *redis = (redisAsyncContext*)clientData;
	if(NULL == redis) return;
	
	if((AE_READABLE & mask)!=0){
		redisAsyncHandleRead(redis);
	}
	
	if((AE_WRITABLE & mask)!=0){
		//printf("write  %d  %d\n",fd,mask);
		redisAsyncHandleWrite(redis);
	}
}


int init_redis_thread()
{
		void *ud = getRTD();
		
		ae_loop = aeCreateEventLoop(MAX_REDIS_SERVER*32);
		
		if(NULL == ae_loop){
			printf("error: ae_loop create failed. exit.\n");
	        fprintf(stderr,"error: ae_loop create failed. exit.\n");
	        _exit(-3);
			return -3;
		}
		
		long long r1 = aeCreateTimeEvent(ae_loop,5*1000,time_cb,NULL,fin_cb);
	    
	return 0;
}

int add_redis_server(const char* ip,int port)
{
	RedisThreadData* rtd = getRTD();
	FOR(i,MAX_REDIS_SERVER){
		if(one_server_stat_empty == rtd->a_server[i].stat){
			strncpy(rtd->a_server[i].IP,ip,IP_LEN-1);
			rtd->a_server[i].port = port;
			rtd->a_server[i].stat = one_server_stat_just_add;
			
			redisAsyncContext* c = redisAsyncConnect(ip,port);
				if (c->err) {
	    			printf("redisAsyncConnect Error: %s  [%s:%d]\n", c->errstr,
					rtd->a_server[i].IP,rtd->a_server[i].port);
	    			rtd->a_server[i].stat = one_server_stat_has_error;
	    		}
	    		else{
	    			rtd->a_server[i].redis_handle = c;
	    			
	    			int r1 = aeCreateFileEvent(ae_loop,c->c.fd,AE_READABLE | AE_WRITABLE,aeFileCallback,c);
	    			if(REDIS_OK != r1){
	    				printf("aeCreateFileEvent failed  [%s:%d]\n",
						rtd->a_server[i].IP,rtd->a_server[i].port);
						rtd->a_server[i].stat = one_server_stat_has_error;
	    			}
	    			else{
	    				rtd->a_server[i].stat = one_server_stat_running;
	    				
	    				redisAsyncSetConnectCallback(c,connectCallback);
	    				redisAsyncSetDisconnectCallback(c,disconnectCallback);
	    				
	    				return i;
					}
				}
				
			
			return -1;
		}
	}
	
	return -1;
}



void getCallback(redisAsyncContext *c, void *r, void *privdata) {
    redisReply *reply = r;
    if (reply == NULL) return;
    
    RedisThreadData* rtd = getRTD();
    FOR(i,MAX_REDIS_SERVER){
    	if(c == rtd->a_server[i].redis_handle){
    		rtd->a_server[i].reply = reply;
    		break;
		}
    }
    
    lua_State *L = g_gx1->lua_vm2_->luaState();
    lua_getglobal(L,"OnRedisReply");
    lua_pushlightuserdata(L,privdata);
    lua_pushlightuserdata(L,reply);
    
    int r2 = lua_pcall(L,2,1,0);
    lua_pop(L,1);
}


int c_redisAsyncCommand(uint32_t redis_i, void *privdata, const char *format, ...)
{
	if(redis_i >= MAX_REDIS_SERVER) return -1;
	
	RedisThreadData* rtd = getRTD();
	int r = -1;
	if(one_server_stat_running == rtd->a_server[redis_i].stat){
		va_list ap;
		va_start(ap, format);
		
		r = redisvAsyncCommand((redisAsyncContext*)rtd->a_server[redis_i].redis_handle, getCallback, privdata, format, ap);
		va_end(ap);
	}
	
	return r;
}

int redis_thread_frame()
{
	return aeProcessEvents(ae_loop,AE_ALL_EVENTS | AE_DONT_WAIT);
}


