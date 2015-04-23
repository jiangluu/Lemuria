#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alog.h>
#include "CBoxPool.h"
#include "GXContext.h"



#define BUF_LEN (1024*64)

#define LOGIN_MSG 1		// ʹ������������protobuf��Ķ��壬����protobuf
#define LOGIN_MSG_2 9


extern CBoxPool *g_boxpool;
extern ALog *g_yylog;


BoxProtocolTier *g_box_tier = NULL;
char CBoxPool::global_id_[BOXPOOL_STR_MAX_LEN];


void __redis_reply_callback(redisAsyncContext *c, void *r, void *privdata);



void __aeFileProc(struct aeEventLoop *eventLoop, int fd, void *clientData, int mask)
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

int __aeTimeProc(struct aeEventLoop *eventLoop, long long id, void *clientData)
{
	return 0;
}

void __redis_connect_callback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        exit(-2);
        return;
    }
    printf("Redis Connected...\n");	
}

void __redis_disconnect_callback(const redisAsyncContext *c, int status) {
	printf("Redis Disconnected...\n");	
	g_boxpool->OnRedisDisconnect(c);
	
    if (status != REDIS_OK) {
        printf("Disconnect Error: %s\n", c->errstr);
        return;
    }
}

// ======== ������lua�õ�C�������� 
redisAsyncContext* redis_make_an_connection(const char* ip,int port)
{
	if(0 == ip || 0 == port) return NULL;
	
	
	//printf("TRY connect to Redis %s:%d\n",ip,port);
	redisAsyncContext* c = redisAsyncConnect(ip,port);
	
	if (c->err) {
	    printf("redisAsyncConnect Error: %s\n", c->errstr);
	    return false;
	}
	
	printf("Async redis-cli fd %d\n",c->c.fd);
	
	
	
	int r1 = redisAsyncSetConnectCallback(c,__redis_connect_callback);
	//printf("redisAsyncSetConnectCallback  %d\n",r1);
	redisAsyncSetDisconnectCallback(c,__redis_disconnect_callback);
	
	
	r1 = aeCreateFileEvent(g_boxpool->ae_loop_,c->c.fd,AE_READABLE | AE_WRITABLE,__aeFileProc,c);
	if(REDIS_OK != r1){
		printf("aeCreateFileEvent failed\n");
		return NULL;
	}
	//aeCreateFileEvent(ae_loop_,c->c.fd,AE_WRITABLE,__aeFileProc,c);
	
	// test
	r1 = redisAsyncCommand(c,NULL,NULL,"SET Company ArtMe");
	printf("redisAsyncCommand  %d\n",r1);
	redisAsyncCommand(c,__redis_reply_callback,NULL,"GET Company");
	
	return c;
}

int redis_free_an_connection(redisAsyncContext *ac)
{
	if(0 == ac) return 1;
	
	aeDeleteFileEvent(g_boxpool->ae_loop_,ac->c.fd,AE_READABLE | AE_WRITABLE);
	//redisAsyncDisconnect(ac);
	redisAsyncFree(ac);
	
	return 0;
}

int box_redis_async_command(redisAsyncContext *ac,const char *format, ...)
{
	if(0 == ac) return -1;
	
	va_list ap;
	
	va_start(ap, format);
	int r = g_boxpool->boxRedisAsyncCommand(ac,format,ap);
	va_end(ap);
	
	return r;
}


redisReply* get_cur_redis_reply()
{
	return g_boxpool->redis_reply_;
}

redisReply* get_cur_redis_push_msg()
{
	return g_boxpool->redis_push_msg_;
}

void box_actor_num_dec(int a)
{
	CBox *box = g_boxpool->getBox(g_box_tier->box_id_);
	
	if(box){
		box->current_actor_num_dec(a);
	}
}

void box_cur_actor_set_flag(int index,bool v)
{
	CBox *box = g_boxpool->getBox(g_box_tier->box_id_);
	
	if(box){
		int cur_actor_id = g_box_tier->actor_id_;
		if(cur_actor_id>=0 && cur_actor_id<box->actor_async_data_num_){
			if(index>=0 && index<8){
				box->a_actor_async_data_[cur_actor_id].flag_[index] = v;
			}
		}
	}
}

bool boxover_set_shared_ptr(int index,void *p)
{
	if(index<0 || index>=BOX_SHARED_PTR_NUM) return false;
	
	g_boxpool->a_ptr_[index] = p;
	
	return true;
}

void* boxover_get_shared_ptr(int index)
{
	if(index<0 || index>=BOX_SHARED_PTR_NUM) return NULL;
	
	return g_boxpool->a_ptr_[index];
}
// ======== END ������lua�õ�C�������� 





void __redis_reply_callback(redisAsyncContext *c, void *r, void *privdata) {
    redisReply *reply = (redisReply*)r;
    if (reply == NULL) return;
    //printf("__redis_reply_callback  [%s]\n", reply->str);
    
    ActorAsyncData *actor_async_data = (ActorAsyncData*)privdata;
    
    g_boxpool->OnRedisReplyCallback(privdata,reply);
}






bool CBoxPool::init(char *global_id)
{
	box_num_ = 50;
	
	strncpy(CBoxPool::global_id_,global_id,BOXPOOL_STR_MAX_LEN-1);
	
	a_box_ = new CBox[box_num_];
	
	if(0 == a_box_) return false;
	
	
	ae_loop_ = aeCreateEventLoop(20000);	// ������ֱ�Ҫ��ص�fdС�Ļ���������������ʧЧ�������ݶ�20000 
	if(NULL == ae_loop_) return false;
	
	
	FOR(i,box_num_){
		// �������ͣ�ÿ��BOX 1��IOͨ�� ��a���򻺳��С256K ��b���򻺳��С64K��box��actor����100�� 
		bool r = a_box_[i].init(i,0,1024*256,1024*64,100);
		
		if(!r){
			printf("CBox init error\n");
			return false;
		}
	}
	
	buf_ = (char*)malloc(BUF_LEN);
	memset(buf_,0,BUF_LEN);
	
	
	if(!ioline_undefined_.init(9999,1024*256,1024*64)) return false;
	
	{
		int len = 1024*64;
		void *mem = malloc(len);
		ws_ = new AStream(len,(char*)mem);
		if(0 == ws_) return false;
	}
	
	gx_context_ = g_gx1;
	
	
	return true;
}


bool CBoxPool::release()
{
	FOR(i,box_num_){
		a_box_[i].release();
	}
	
	return true;
}

bool CBoxPool::registerRedisContext(redisAsyncContext *redis)
{
	return true;
}

int CBoxPool::boxRedisAsyncCommand(redisAsyncContext *ac,const char *format, va_list ap)
{
	if(0 == ac) return -1;
	
	redisAsyncContext *aa = ac;
	
	CBox *box = getBox(g_box_tier->box_id_);
	if(0==box) return -1;
	
	u32 actor_id = g_box_tier->actor_id_;
	if(actor_id >= box->actor_async_data_num_) return -1;
	
	// �Ǻ������� 
	ActorAsyncData *actor_async_data = box->a_actor_async_data_+actor_id;
	GXContext *gx = (GXContext*)getGX();
	memcpy(&actor_async_data->context_,&gx->input_context_,sizeof(GXContext::InputContext));
	memcpy(&actor_async_data->box_tier_,g_box_tier,sizeof(BoxProtocolTier));
	actor_async_data->context_.rs_ = NULL;
	actor_async_data->typee_ = 0;
	++actor_async_data->serial_[0];
	
	//return redisAsyncCommand(aa,__redis_reply_callback,actor_async_data,"%b",buf,buf_len);
	return redisvAsyncCommand(aa,__redis_reply_callback,actor_async_data,format,ap);
}

void CBoxPool::OnRedisReplyCallback(ActorAsyncData *ad,redisReply *reply)
{
	//printf("CBoxPool::OnRedisReplyCallback  %x  %x\n",ad,reply);
	if(0==ad) return;
	
	
	// ���ж��Ƿ�����Ϣ 
	redis_push_msg_ = reply;
	CBox *box = getBox(g_box_tier->box_id_);
	if(0 == box) return;
	
	try{
	
	bool is_push_msg = box->getLuaVM()->callGlobalFunc<bool>("isPushMsg");
	if(is_push_msg){
		// Ҫ�ַ���ÿ��BOX
		
		GXContext *gx = (GXContext*)getGX();
		memcpy(&gx->input_context_,&ad->context_,sizeof(GXContext::InputContext));
		memcpy(g_box_tier,&ad->box_tier_,sizeof(BoxProtocolTier));
		
		ws_->cleanup();
		gx->input_context_.rs_ = NULL;	// ��ʱ�����ٶ��û����� 
		gx->input_context_.ws_ = ws_;
		
		bool found = false;
		FOR(i,box_num_){
			CBox *bb = a_box_+i;
			
			g_box_tier->box_id_ = i;
			
			ws_->cleanup();
			redis_push_msg_ = reply;
			int r = bb->getLuaVM()->callGlobalFunc<int>("OnRedisReply",1);
			if(1 == r){
				found = true;
			}
		}
		
		if(false == found){
			// �Ѿ�û���˹������Ƶ���ˣ� ������֮ ������������ĸ�BOX��ִ�ж���һ���ģ� ��Ϊ����������BOX�������޹أ�ֻҪ��ס���һ��Ƶ�������� 
			
			box->getLuaVM()->callGlobalFunc<void>("unSubscribeCurrentChannel");
			
		}
	}
	else{
		++ad->serial_[1];
		if(ad->serial_[0] != ad->serial_[1]) return;
		
		// �ָ�������
		GXContext *gx = (GXContext*)getGX();
		memcpy(&gx->input_context_,&ad->context_,sizeof(GXContext::InputContext));
		memcpy(g_box_tier,&ad->box_tier_,sizeof(BoxProtocolTier));
		// g_luacontext->header_.actor_id_ ������ȷ��actor_id 
		ws_->cleanup();
		gx->input_context_.rs_ = NULL;	// ��ʱ�����ٶ��û����� 
		gx->input_context_.ws_ = ws_;
		
		redis_reply_ = reply;
		int r = box->getLuaVM()->callGlobalFunc<int>("OnRedisReply",0);
	}
	
	}
	catch(...)
	{
	}
	
	/*
	if(false == ad->flag_[0]){
		// 0�ű�Ǳ�ʾ����ͬ�� 
		if(ad->serial_[0] != ad->serial_[1]) return;
	}
	
	// 1�ű�Ǳ�ʾ�Ƿ��һ����Ϣ�㲥������box 
	if(false == ad->flag_[1]){
		CBox *box = getBox(ad->context_.header_.box_id_);
		if(0 == box) return;
		
		if(box->getLuaVM()){
			// �ָ�������
			memcpy(g_luacontext,&ad->context_,sizeof(LuaContext));
			// g_luacontext->header_.actor_id_ ������ȷ��actor_id 
			ws_->cleanup();
			g_luacontext->rs_ = NULL;	// ��ʱ�����ٶ��û����� 
			g_luacontext->ws_ = ws_;
			
			redis_reply_ = reply;
			int r = box->getLuaVM()->callGlobalFunc<int>("OnRedisReply");
		}
	}
	else{
		memcpy(g_luacontext,&ad->context_,sizeof(LuaContext));
		// g_luacontext->header_.actor_id_ ������ȷ��actor_id 
		ws_->cleanup();
		g_luacontext->rs_ = NULL;	// ��ʱ�����ٶ��û����� 
		g_luacontext->ws_ = ws_;
			
		redis_reply_ = reply;
			
		FOR(i,box_num_){
			CBox *bb = a_box_+i;
			
			g_luacontext->header_.box_id_ = i;
			
			ws_->cleanup();
			int r = bb->getLuaVM()->callGlobalFunc<int>("OnRedisReply");
		}
	}
	*/
}

void CBoxPool::OnRedisDisconnect(redisAsyncContext *c)
{
}

bool CBoxPool::post_init()
{
	FOR(i,box_num_){
		CBox *bb = a_box_+i;
		
		g_box_tier->box_id_ = i;
		g_box_tier->actor_id_ = 0;
		
		bb->getLuaVM()->SetGlobal("g_box_id",i);
		bb->getLuaVM()->callGlobalFunc<void>("post_init");
	}
	return true;
}

void CBoxPool::onUpdate(timetype now)
{
	static u64 counter = 0;
	++counter;
	//printf("CBoxPool::onUpdate  [%llu]\n",counter);
	
	
	// �ٴ���redis����
	aeProcessEvents(ae_loop_,AE_ALL_EVENTS | AE_DONT_WAIT);
	
	
	if(0 != (flag_ & 0x01)){
		FOR(i,box_num_){
			CBox *bb = a_box_+i;
			LuaInterface *L = bb->getLuaVM();
			if(L){
				// �ڽ���luaVM֮ǰ��׼����������
				GXContext *gx = (GXContext*)getGX();
				gx->input_context_.flag_ = 0;
				g_box_tier->box_id_ = i;
				g_box_tier->actor_id_ = 0;
				
				L->callGlobalFunc<void>("OfflineAllPlayer");
			}
		}
		
		flag_ = 0;
	}
	
	// LuaVM GC
	if(0 == (counter%100)){
		FOR(i,box_num_){
			CBox *bb = a_box_+i;
			lua_State *L = bb->getLuaVM()->luaState();
			if(L){
				lua_gc(L,LUA_GCSTEP,5);
			}
		}
	}
	
	if(0 == (counter%10000)){
		if(g_yylog){
			g_yylog->flush();
		}
	}
}

int CBoxPool::OnMessage(GXContext *gx,InternalHeader *hh)
{
	gx_context_ = gx;
	
	int msg_id = hh->message_id_;
	if(msg_id>=8000 && msg_id<=8100){
		CBox *bb = getBox(0);	// ��0��box����һ�� 
		if(bb){
			int r = bb->getLuaVM()->callGlobalFunc<int>("OnInternalMessage");
			return r;
		}
	}
	else{
		if(g_box_tier){
			g_box_tier->reset();
			
			const char* b = gx->input_context_.rs_->get_bin(sizeof(BoxProtocolTier));
			memcpy(g_box_tier,b,sizeof(BoxProtocolTier));
		}
		
		CBox *bb = getBox(g_box_tier->box_id_);
		if(bb){
			int r = bb->getLuaVM()->callGlobalFunc<int>("OnCustomMessage");
			return r;
		}
	}
	
	return -1;
}

#if 0
void CBoxPool::consumePerBoxEvent(timetype now)
{
	FOR(i,box_num_){
		CBox *bb = a_box_+i;
		FOR(jj,bb->ioline_num_){
			IOLine *line = bb->getIOLine(jj);
			if(line){
				// ѭ��������� 
				while(false==line->is_locked() && line->observe(LineA) >= INTERNAL_HEADER_LEN+sizeof(s16)){
					char buf[INTERNAL_HEADER_LEN+16];
					line->pull(LineA,buf,INTERNAL_HEADER_LEN+sizeof(s16));
					
					InternalHeader *hh = (InternalHeader*)buf;
					s16 *link_id = (s16*)(buf+INTERNAL_HEADER_LEN);
					int to_read = hh->len_-CLIENT_HEADER_LEN;
					
					// ����û�п��� to_read> BUF_LEN�������Gate����Ӧ�ðѳ��Ȳ��Ϸ��İ����ص� 
					int r = line->pull(LineA,buf_,to_read);
					if(r == to_read && r>=0){
						try{
						
						// �ڽ���luaVM֮ǰ��׼����������
						GXContext *gx = (GXContext*)getGX();
						gx->input_context_.flag_ = 0;
						memcpy(&g_luacontext->header_,hh,INTERNAL_HEADER_LEN);
						g_luacontext->src_link_id_ = *link_id;
						g_luacontext->usersn_ = g_luacontext->header_.account_id_;
						g_luacontext->header_.box_id_ = i;
						// g_luacontext->header_.actor_id_ ������ȷ��actor_id 
						AStream rs(to_read,buf_);
						ws_->cleanup();
						g_luacontext->rs_ = &rs;
						g_luacontext->ws_ = ws_;
						
						bb->getLuaVM()->callGlobalFunc<void>("OnMessage",(int)hh->message_id_);
						
						// ˼·��loopback�İ���д��IOLineB��
						// ���߳�������ʱ���ٴΰ����Ƶ����̣߳�1�����µİ��� 2����΢����֡ 
						if((g_luacontext->flag_ & 1)>0){
							line->push(LineB,buf,INTERNAL_HEADER_LEN+sizeof(s16));
							if(r>0){
								line->push(LineB,buf_,r);
							}
						}
						
						
						}
						catch(...)
						{
						}
					}
					else{
						// û�ж����������ߡ������ڵĴ����Ƕ�����push���Ǳ���һ������Ӧ���ǲ����ܵ������֧�� 
					}
				}
			}
		}
	}
}

void CBoxPool::consumeUndefinedIOLine(timetype now)
{
	while(false==ioline_undefined_.is_locked() && ioline_undefined_.observe(LineA) >= INTERNAL_HEADER_LEN+sizeof(s16)){
		char buf[INTERNAL_HEADER_LEN+16];
		ioline_undefined_.pull(LineA,buf,INTERNAL_HEADER_LEN+sizeof(s16));
		
		InternalHeader *hh = (InternalHeader*)buf;
		s16 *link_id = (s16*)(buf+INTERNAL_HEADER_LEN);
		int to_read = hh->len_-CLIENT_HEADER_LEN;
		
		int r = ioline_undefined_.pull(LineA,buf_,to_read);
		if(r == to_read && r>=0){
			// ���������Ǵ����¼��������Ҫ�������µ�actor������һ��BOX������û��������Lua��ʵ������߼�����Lua�ﲻ�ܿ�VM������ 
			if(LOGIN_MSG == hh->message_id_ || LOGIN_MSG_2==hh->message_id_){
				// ��һ���ܷ��µ�BOX
				int err_code = 1;	// 1-ÿ��BOX������ 2-��δ���ĵ��ǽ���ʧ�� 
				FOR(i,box_num_){
					CBox *bb = a_box_+i;
					if(bb && bb->current_actor_num_<bb->suggested_actor_num_){
						// �ڽ���luaVM֮ǰ��׼����������
						memcpy(&g_luacontext->header_,hh,INTERNAL_HEADER_LEN);
						g_luacontext->src_link_id_ = *link_id;
						g_luacontext->usersn_ = -1;
						g_luacontext->header_.box_id_ = i;
						g_luacontext->header_.actor_id_ = -1;
						AStream rs(to_read,buf_);
						ws_->cleanup();
						g_luacontext->rs_ = &rs;
						g_luacontext->ws_ = ws_;
						 
						try{
						
						int new_actor_id = bb->getLuaVM()->callGlobalFunc<int>("OnActorEnter");		// OnActorEnter()�������Ӧ�þ��췵�� new_actor_id�����������齻������������ 
						if(new_actor_id>=0){
							g_luacontext->header_.actor_id_ = new_actor_id;		// ��Ҫ���Ӵ��Ժ����actor�������ID�� 
							++ bb->current_actor_num_;
							if(new_actor_id < bb->actor_async_data_num_){
								bb->a_actor_async_data_[new_actor_id].cleanup();
							}
							
							// C��Ĳ���ֻ������actor����BOX���Լ�ά��һ�������������಻��⡣ֻ֪�������ַ���Ϣ 
							rs.reset(to_read,buf_);
							ws_->cleanup();
							bb->getLuaVM()->callGlobalFunc<void>("OnMessage",(int)hh->message_id_);
							
							err_code = 0;
							break;
						}
						else{
							err_code = 2;
							break;
						}
						
						}
						catch(...)
						{
						}
					}
				}
				
				if(0 != err_code){
					// ���ߡ���
					LuaInterface *luavm = getBox(0)->getLuaVM();	// ����һ��
					if(luavm){
						luavm->callGlobalFunc<void>("OnEnterFail",err_code);
					}
				}
			}
			else{
				// ������Ϣ��Ӧ�ò��ᵼ��actor�������BOX�ġ� LOGIN_MSGҪ������������������Ϊ������BOX�� ��׮�²�����BOX�ﴦ�� 
			}
		}
		else{
			// û�ж����������ߡ������ڵĴ����Ƕ�����push���Ǳ���һ������Ӧ���ǲ����ܵ������֧�� 
		}
	}
}
#endif




