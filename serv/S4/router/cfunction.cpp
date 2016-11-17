#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "router.h"
#include "LuaInterface.h"
#include "cfunction.h"
#include "GXContext.h"
#include "GXCfunction.h"



#define MAX_A_STR_LEN (1024*128)
static char s_buf1[MAX_A_STR_LEN];



bool cur_stream_is_end()
{
	return gx_cur_stream_is_end();
}

s16 cur_stream_get_int8()
{
	return gx_cur_stream_get_int8();
}

s16 cur_stream_get_int16()
{
	return gx_cur_stream_get_int16();
}

s32 cur_stream_get_int32()
{
	return gx_cur_stream_get_int32();
}

s64 cur_stream_get_int64()
{
	return gx_cur_stream_get_int64();
}

f32 cur_stream_get_float32()
{
	return gx_cur_stream_get_float32();
}

f64 cur_stream_get_float64()
{
	return gx_cur_stream_get_float64();
}

struct Slice cur_stream_get_slice()
{
	return gx_cur_stream_get_slice();
}

s16 cur_stream_peek_int16()
{
	return gx_cur_stream_peek_int16();
}

bool cur_stream_push_int16(s16 v)
{
	return gx_cur_stream_push_int16(v);
}

bool cur_stream_push_int32(s32 v)
{
	return gx_cur_stream_push_int32(v);
}

bool cur_stream_push_int64(s64 v)
{
	return gx_cur_stream_push_int64(v);
}

bool cur_stream_push_float32(f32 v)
{
	return gx_cur_stream_push_float32(v);
}

bool cur_stream_push_slice(struct Slice s)
{
	return gx_cur_stream_push_slice(s);
}

bool cur_stream_push_string(const char* v,int len)
{	
	return gx_cur_stream_push_slice2(v,len);
}


// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
void cur_stream_write_back()
{
	gx_cur_writestream_syncback();
}

void cur_stream_write_back2(int message_id)
{	
	gx_cur_writestream_syncback2(message_id);
}

void cur_stream_broadcast(int message_id)
{
	u16 bak = g_gx1->input_context_.header_.flag_;
	g_gx1->input_context_.header_.flag_ |= HEADER_FLAG_BROADCAST;
	gx_cur_writestream_syncback2(message_id);
	
	g_gx1->input_context_.header_.flag_ = bak;
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

void cur_write_stream_cleanup()
{
	gx_cur_writestream_cleanup();
}


bool log_write(int level,const char *ss,int len)
{
	if(NULL==ss) return false;
	
	if(g_log){
		return g_log->write(level,ss,len);
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
	if(g_log){
		g_log->flush();
	}
}

int string_hash(const char *str)
{
	return string_hash_with_client(str);
}


int cur_message_loopback()
{
	g_gx1->input_context_.flag_ |= 0x2;
	
	return 0;
}

int cur_stream_get_readbuf_len()
{
	if(g_gx1->rs_){
		return g_gx1->rs_->getreadbuflen();
	}
	
	return -1;
}

const char* cur_stream_get_bin(int len)
{
	if(g_gx1->rs_ && len>0){
		return g_gx1->rs_->get_bin(len);
	}
	
	return NULL;
}


