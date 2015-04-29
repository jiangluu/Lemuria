#ifndef __CBOXPOOL_H
#define __CBOXPOOL_H


#include "types.h"
#include "hiredis/hiredis.h"
#include "hiredis/async.h"
#include "ae/ae.h"
#include "GameTime.h"
#include "CBox.h"



#define UNDEFINED_BOX 0xFFFF
#define BOX_SHARED_PTR_NUM 512

#define BOXPOOL_STR_MAX_LEN 128


// Box的管理器。一个工作线程应该有且只有一个 CBoxPool。Redis客户端资源也应该分配在这一层。 

class CBoxPool{
public:
	CBoxPool():box_num_(0),a_box_(0),buf_(0),ae_loop_(0),redis_reply_(0),redis_push_msg_(0),flag_(0),gx_context_(0){
		FOR(i,BOX_SHARED_PTR_NUM){
			a_ptr_[i] = 0;
		}
	}
	
	bool init(char *global_id);
	bool release();
	
	bool post_init();
	
	// 在工作线程里调用的 
	void onUpdate(timetype now);
	
	
	CBox* getBox(u16 id){
		if(id<0 || id>=box_num_) return NULL;
		return a_box_+id;
	}
	
	IOLine* getUndefinedLine(){ return &ioline_undefined_; }
	
	int boxRedisAsyncCommand(redisAsyncContext *ac,const char *format, va_list ap);
	
	void OnRedisReplyCallback(ActorAsyncData*,redisReply*);
	void OnRedisDisconnect(redisAsyncContext*);
	
	void* getGX(){
		return gx_context_;
	}
	
	int OnMessage(GXContext *gx,InternalHeader *hh);
	
private:
#if 0
	void consumeUndefinedIOLine(timetype now);
	void consumePerBoxEvent(timetype now);
#endif
	
	bool registerRedisContext(redisAsyncContext*);
	
	
	int box_num_;
	CBox *a_box_;
	char *buf_;
	
	
	IOLine ioline_undefined_;
	
	void *gx_context_;
	
public:
	aeEventLoop *ae_loop_;
	static char global_id_[BOXPOOL_STR_MAX_LEN];
	
	void *a_ptr_[BOX_SHARED_PTR_NUM];	// 各BOX可以共享的指针；至于里面放什么，Lua才知道，C不关心 
	
	redisReply *redis_reply_;
	redisReply *redis_push_msg_;
	
	int flag_;
};


// ======== 导出给lua用的C函数部分 
#ifdef WIN32
#define CF_EXPORT  __declspec(dllexport)
#else
#define CF_EXPORT
#endif


extern "C"{
	CF_EXPORT redisAsyncContext* redis_make_an_connection(const char* ip,int port);
	
	CF_EXPORT int redis_free_an_connection(redisAsyncContext *ac);
	
	CF_EXPORT int box_redis_async_command(redisAsyncContext *ac,const char *format, ...);
	
	//CF_EXPORT int box_db_async_command(u32 redis_index,const char *format, ...);
	
	CF_EXPORT redisReply* get_cur_redis_reply();
	
	CF_EXPORT redisReply* get_cur_redis_push_msg();
	
	CF_EXPORT void box_actor_num_dec(int a);
	
	CF_EXPORT void box_cur_actor_set_flag(int index,bool v);
	
	CF_EXPORT bool boxover_set_shared_ptr(int index,void *p);
	CF_EXPORT void* boxover_get_shared_ptr(int index);
}
// ======== END 导出给lua用的C函数部分 


#endif

