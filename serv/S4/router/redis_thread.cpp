#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hiredis/hiredis.h"
#include "hiredis/async.h"
#include "ae/ae.h"
#include <pthread.h>
#include "router.h"


#define IP_LEN 32
#define MAX_REDIS_SERVER 32
struct RedisThreadData{
	struct one_server_info{
		char IP[IP_LEN];
		int port;
		uint16_t stat;
		uint16_t padding;
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

void* work_thread_func(void *userdata);

int init_readis_thread()
{
		void *ud = getRTD();
		
		pthread_t id;
	    pthread_attr_t attr;
	    pthread_attr_init(&attr);
	    //pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
		pthread_attr_setstacksize(&attr,1024*1024);		// 栈大小设为1024K
	
	    if(pthread_create( &id, &attr , work_thread_func , ud )){
	    	printf("error: could NOT create thread!! exit.\n");
	        fprintf(stderr,"error: could NOT create thread!! exit.\n");
	        _exit(-3);
			return -3;
	    }
	    
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
			return i;
		}
	}
	
	return -1;
}


void* work_thread_func(void *userdata)
{
}


