#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "polarssl/md5.h"
#include "link.h"
#include "GXContext.h"
#include "GXCfunction.h"
#include "LuaInterface.h"



#define MAX_A_STR_LEN (1024*128)
static char s_buf1[MAX_A_STR_LEN];


#define C_ENV_SHARED_PTR_LEN 512


extern GXContext *g_gx1;


void** __make_sure_gx_env_get_shared_ptr_exists()
{
	static void** aa = NULL;
	if(NULL == aa){
		int len = sizeof(void*) * C_ENV_SHARED_PTR_LEN;
		aa = (void**)malloc(len);
		memset(aa,0,len);
	}
	return aa;
}

void* gx_env_get_shared_ptr(int index)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return NULL;
	
	void** p = __make_sure_gx_env_get_shared_ptr_exists();
	if(NULL == p) return NULL;
	
	return p[index];
}

bool gx_env_set_shared_ptr(int index,void *new_value)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return false;
	
	void** p = __make_sure_gx_env_get_shared_ptr_exists();
	if(NULL == p) return false;
	
	p[index] = new_value;
	return true;
}


bool gx_cur_stream_is_end()
{
	if(g_gx1) return g_luacontext->rs_->is_end();
	return true;
}

s16 cur_stream_get_int8()
{
	if(g_luacontext->rs_) return (s16)g_luacontext->rs_->get<char>();
	return 0;
}

s16 cur_stream_get_int16()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->get<s16>();
	return 0;
}

s32 cur_stream_get_int32()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->get<s32>();
	return 0;
}

s64 cur_stream_get_int64()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->get<s64>();
	return 0;
}

f32 cur_stream_get_float32()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->get<f32>();
	return 0.0f;
}

f64 cur_stream_get_float64()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->get<f64>();
	return 0.0f;
}

struct Slice cur_stream_get_slice()
{
	struct Slice aa;
	aa.len_ = 0;
	aa.mem_ = NULL;
	
	if(g_luacontext->rs_){
		s16 len = g_luacontext->rs_->get<s16>();
		if(len>0 && len<(MAX_A_STR_LEN-40)){
			const char *cc = g_luacontext->rs_->get_bin(len);
			if(cc){
				memcpy(s_buf1+32,cc,len);
				s_buf1[len+32] = 0;
				
				aa.len_ = len;
				aa.mem_ = s_buf1+32;
			}
		}
	}
	return aa;
}

s16 cur_stream_peek_int16()
{
	if(g_luacontext->rs_) return g_luacontext->rs_->peek<s16>();
	return 0;
}

bool cur_stream_push_int16(s16 v)
{
	if(g_luacontext->ws_) return g_luacontext->ws_->set<s16>(v);
	return false;
}

bool cur_stream_push_int32(s32 v)
{
	if(g_luacontext->ws_) return g_luacontext->ws_->set<s32>(v);
	return false;
}

bool cur_stream_push_int64(s64 v)
{
	if(g_luacontext->ws_) return g_luacontext->ws_->set<s64>(v);
	return false;
}

bool cur_stream_push_float32(f32 v)
{
	if(g_luacontext->ws_) return g_luacontext->ws_->set<f32>(v);
	return false;
}

bool cur_stream_push_slice(struct Slice s)
{
	return cur_stream_push_string(s.mem_,s.len_);
}

bool cur_stream_push_string(const char* v,int len)
{
	if(g_luacontext->ws_ && v){
		int real_len = 0;
		if(len > 0){
			real_len = len;
		}
		else{
			real_len = strlen(v);
		}
		
		g_luacontext->ws_->set<s16>((s16)real_len);
		return g_luacontext->ws_->push_bin(v,real_len);
	}
	
	return false;
}

void cur_write_stream_cleanup()
{
	if(g_luacontext->ws_) g_luacontext->ws_->cleanup();
}


// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
void cur_stream_write_back()
{
	cur_stream_write_back2(g_luacontext->header_.message_id_+1);
}

void cur_stream_write_back2(int message_id)
{
	if(g_luacontext->ws_){
		Link *ll = g_app->frontend_.getLink(g_luacontext->src_link_id_);
		//printf("g_luacontext->src_link_id_ [%d]\n",g_luacontext->src_link_id_);
		if(ll){
			InternalHeader hh = g_luacontext->header_;
			hh.message_id_ = message_id;
			hh.len_ = CLIENT_HEADER_LEN + g_luacontext->ws_->getwritebuflen();
			
			// 下面是分两次push，不形成一个事务。但是应该也不要紧
			__kfifo_put(&ll->write_fifo_,(unsigned char*)&hh,INTERNAL_HEADER_LEN);
			__kfifo_put(&ll->write_fifo_,(unsigned char*)g_luacontext->ws_->getbuf(),g_luacontext->ws_->getwritebuflen());
		}
	}
}

void cur_stream_broadcast(int message_id)
{
	if(g_luacontext->ws_){
		// make sure to find gate
		FOR(i,999){
			Link *ll = g_app->frontend_.getLink(i);
			if(NULL == ll) break;
			
			if('C' != ll->link_id_[0]){
				InternalHeader hh = g_luacontext->header_;
				hh.message_id_ = 1050;
				hh.account_id_ = message_id;	// 广播的情况下，把原始 message_id存在这个字段 
				hh.len_ = CLIENT_HEADER_LEN + g_luacontext->ws_->getwritebuflen();
				
				// 下面是分两次push，不形成一个事务。但是应该也不要紧
				__kfifo_put(&ll->write_fifo_,(unsigned char*)&hh,INTERNAL_HEADER_LEN);
				__kfifo_put(&ll->write_fifo_,(unsigned char*)g_luacontext->ws_->getbuf(),g_luacontext->ws_->getwritebuflen());
			}
		}
		/*
		Link *ll = g_app->frontend_.getLink(g_luacontext->src_link_id_);
		
		if(ll){
			InternalHeader hh = g_luacontext->header_;
			hh.message_id_ = 1050;
			hh.account_id_ = message_id;	// 广播的情况下，把原始 message_id存在这个字段 
			hh.len_ = CLIENT_HEADER_LEN + g_luacontext->ws_->getwritebuflen();
			
			// 下面是分两次push，不形成一个事务。但是应该也不要紧
			__kfifo_put(&ll->write_fifo_,(unsigned char*)&hh,INTERNAL_HEADER_LEN);
			__kfifo_put(&ll->write_fifo_,(unsigned char*)g_luacontext->ws_->getbuf(),g_luacontext->ws_->getwritebuflen());
		}
		*/
	}
}

s32 cur_actor_id()
{
	if(g_luacontext){
		return g_luacontext->header_.actor_id_;
	}
	return 0;
}

u64 cur_user_sn()
{
	if(g_luacontext){
		return g_luacontext->usersn_;
	}
	return 0;
}

// 注：山寨王的游戏时间定义为ansitime，这是因为手游是碎片化的，时间一般都要求跨越session 后还有意义。 
// 除了以后的一场战斗中用到的时间外，都应该使用ansi时间。 
u32 cur_game_time()
{
	u32 aa = g_time->getANSITime();
	return aa;
}

u64 cur_game_usec()
{
	return g_time->localUsecTime();
}

bool log_write(int level,const char *ss,int len)
{
	if(NULL==ss) return false;
	
	if(g_app->log_){
		return g_app->log_->write(level,ss,len);
	}
	return false;
}

bool log_write2(int index,const char *ss,int len)
{
	if(NULL==ss) return false;
	
	if(g_yylog){
		return g_yylog->write(ALog::verbose,ss,len);
	}
	return false;
}


void log_force_flush()
{
	if(g_app->log_){
		g_app->log_->flush();
	}
}

int string_hash(const char *str)
{
	return string_hash_with_client(str);
}

int cur_message_loopback()
{
	if(g_luacontext){
		g_luacontext->flag_ |= 1;
	}
	return 0;
}


void MD5( const unsigned char *input, size_t ilen, unsigned char output[16] )
{
	md5(input,ilen,output);
}


