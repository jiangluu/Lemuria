#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alog.h>
#include "CBoxPool.h"
#include "GXContext.h"



#define BUF_LEN (1024*64)

#define LOGIN_MSG 1		// 使用这个宏而不是protobuf里的定义，摆脱protobuf
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

// ======== 导出给lua用的C函数部分 
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
// ======== END 导出给lua用的C函数部分 





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
	
	
	ae_loop_ = aeCreateEventLoop(20000);	// 这个数字比要监控的fd小的话，会让整个机制失效。所以暂定20000 
	if(NULL == ae_loop_) return false;
	
	
	FOR(i,box_num_){
		// 参数解释：每个BOX 1个IO通道 ，a方向缓冲大小256K ，b方向缓冲大小64K，box内actor上限100个 
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
	
	// 记好上下文 
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
	
	
	// 先判断是否订阅消息 
	redis_push_msg_ = reply;
	CBox *box = getBox(g_box_tier->box_id_);
	if(0 == box) return;
	
	try{
	
	bool is_push_msg = box->getLuaVM()->callGlobalFunc<bool>("isPushMsg");
	if(is_push_msg){
		// 要分发到每个BOX
		
		GXContext *gx = (GXContext*)getGX();
		memcpy(&gx->input_context_,&ad->context_,sizeof(GXContext::InputContext));
		memcpy(g_box_tier,&ad->box_tier_,sizeof(BoxProtocolTier));
		
		ws_->cleanup();
		gx->input_context_.rs_ = NULL;	// 这时不能再读用户输入 
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
			// 已经没有人关心这个频道了， 反订阅之 。这个函数在哪个BOX里执行都是一样的， 因为所做的事与BOX上下文无关，只要记住最后一个频道名即可 
			
			box->getLuaVM()->callGlobalFunc<void>("unSubscribeCurrentChannel");
			
		}
	}
	else{
		++ad->serial_[1];
		if(ad->serial_[0] != ad->serial_[1]) return;
		
		// 恢复上下文
		GXContext *gx = (GXContext*)getGX();
		memcpy(&gx->input_context_,&ad->context_,sizeof(GXContext::InputContext));
		memcpy(g_box_tier,&ad->box_tier_,sizeof(BoxProtocolTier));
		// g_luacontext->header_.actor_id_ 里有正确的actor_id 
		ws_->cleanup();
		gx->input_context_.rs_ = NULL;	// 这时不能再读用户输入 
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
		// 0号标记表示忽略同步 
		if(ad->serial_[0] != ad->serial_[1]) return;
	}
	
	// 1号标记表示是否把一个消息广播给所有box 
	if(false == ad->flag_[1]){
		CBox *box = getBox(ad->context_.header_.box_id_);
		if(0 == box) return;
		
		if(box->getLuaVM()){
			// 恢复上下文
			memcpy(g_luacontext,&ad->context_,sizeof(LuaContext));
			// g_luacontext->header_.actor_id_ 里有正确的actor_id 
			ws_->cleanup();
			g_luacontext->rs_ = NULL;	// 这时不能再读用户输入 
			g_luacontext->ws_ = ws_;
			
			redis_reply_ = reply;
			int r = box->getLuaVM()->callGlobalFunc<int>("OnRedisReply");
		}
	}
	else{
		memcpy(g_luacontext,&ad->context_,sizeof(LuaContext));
		// g_luacontext->header_.actor_id_ 里有正确的actor_id 
		ws_->cleanup();
		g_luacontext->rs_ = NULL;	// 这时不能再读用户输入 
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
	
	
	// 再处理redis返回
	aeProcessEvents(ae_loop_,AE_ALL_EVENTS | AE_DONT_WAIT);
	
	
	if(0 != (flag_ & 0x01)){
		FOR(i,box_num_){
			CBox *bb = a_box_+i;
			LuaInterface *L = bb->getLuaVM();
			if(L){
				// 在进入luaVM之前，准备好上下文
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
		CBox *bb = getBox(0);	// 把0号box借来一用 
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
				// 循环处理完毕 
				while(false==line->is_locked() && line->observe(LineA) >= INTERNAL_HEADER_LEN+sizeof(s16)){
					char buf[INTERNAL_HEADER_LEN+16];
					line->pull(LineA,buf,INTERNAL_HEADER_LEN+sizeof(s16));
					
					InternalHeader *hh = (InternalHeader*)buf;
					s16 *link_id = (s16*)(buf+INTERNAL_HEADER_LEN);
					int to_read = hh->len_-CLIENT_HEADER_LEN;
					
					// 这里没有考虑 to_read> BUF_LEN的情况。Gate那里应该把长度不合法的包拦截掉 
					int r = line->pull(LineA,buf_,to_read);
					if(r == to_read && r>=0){
						try{
						
						// 在进入luaVM之前，准备好上下文
						GXContext *gx = (GXContext*)getGX();
						gx->input_context_.flag_ = 0;
						memcpy(&g_luacontext->header_,hh,INTERNAL_HEADER_LEN);
						g_luacontext->src_link_id_ = *link_id;
						g_luacontext->usersn_ = g_luacontext->header_.account_id_;
						g_luacontext->header_.box_id_ = i;
						// g_luacontext->header_.actor_id_ 里有正确的actor_id 
						AStream rs(to_read,buf_);
						ws_->cleanup();
						g_luacontext->rs_ = &rs;
						g_luacontext->ws_ = ws_;
						
						bb->getLuaVM()->callGlobalFunc<void>("OnMessage",(int)hh->message_id_);
						
						// 思路：loopback的包，写回IOLineB。
						// 主线程有两个时机再次把他推到本线程：1）有新的包来 2）稍微过几帧 
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
						// 没有读完整，杯具。。现在的处理是丢弃。push的那边是一个事务，应该是不可能到这个分支的 
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
			// 处理，这里是处理登录包。这里要决定把新的actor塞给哪一个BOX，所以没有条件在Lua里实现这段逻辑。（Lua里不能跨VM操作） 
			if(LOGIN_MSG == hh->message_id_ || LOGIN_MSG_2==hh->message_id_){
				// 找一个能放下的BOX
				int err_code = 1;	// 1-每个BOX都满了 2-有未满的但是进入失败 
				FOR(i,box_num_){
					CBox *bb = a_box_+i;
					if(bb && bb->current_actor_num_<bb->suggested_actor_num_){
						// 在进入luaVM之前，准备好上下文
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
						
						int new_actor_id = bb->getLuaVM()->callGlobalFunc<int>("OnActorEnter");		// OnActorEnter()这个函数应该尽快返回 new_actor_id，把其余事情交给其他函数做 
						if(new_actor_id>=0){
							g_luacontext->header_.actor_id_ = new_actor_id;		// 重要，从此以后这个actor就是这个ID了 
							++ bb->current_actor_num_;
							if(new_actor_id < bb->actor_async_data_num_){
								bb->a_actor_async_data_[new_actor_id].cleanup();
							}
							
							// C里的部分只负责让actor进入BOX并自己维护一个计数器，其余不理解。只知道继续分发消息 
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
					// 杯具。。
					LuaInterface *luavm = getBox(0)->getLuaVM();	// 借来一用
					if(luavm){
						luavm->callGlobalFunc<void>("OnEnterFail",err_code);
					}
				}
			}
			else{
				// 其他消息，应该不会导致actor分配进入BOX的。 LOGIN_MSG要单独独立出来就是因为“进入BOX” 这桩事不能在BOX里处理 
			}
		}
		else{
			// 没有读完整，杯具。。现在的处理是丢弃。push的那边是一个事务，应该是不可能到这个分支的 
		}
	}
}
#endif




