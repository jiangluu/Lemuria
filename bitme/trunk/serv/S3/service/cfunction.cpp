#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "polarssl/md5.h"
#include "service.h"
#include "LuaInterface.h"
#include "cfunction.h"
#include "GXContext.h"
#include "GXCfunction.h"



#define MAX_A_STR_LEN (1024*128)
static char s_buf1[MAX_A_STR_LEN];


#define C_ENV_SHARED_PTR_LEN 512

void** __make_sure_c_env_get_shared_ptr_exists()
{
	static void** aa = NULL;
	if(NULL == aa){
		int len = sizeof(void*) * C_ENV_SHARED_PTR_LEN;
		aa = (void**)malloc(len);
		memset(aa,0,len);
	}
	return aa;
}

void* c_env_get_shared_ptr(int index)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return NULL;
	
	void** p = __make_sure_c_env_get_shared_ptr_exists();
	if(NULL == p) return NULL;
	
	return p[index];
}

bool c_env_set_shared_ptr(int index,void *new_value)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return false;
	
	void** p = __make_sure_c_env_get_shared_ptr_exists();
	if(NULL == p) return false;
	
	p[index] = new_value;
	return true;
}


s32 cur_actor_id()
{
	if(g_box_tier){
		return g_box_tier->actor_id_;
	}
	return -1;
}

u64 cur_user_sn()
{
	if(g_box_tier){
		return g_box_tier->usersn_;
	}
	return -1;
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
	if(g_box_tier){
		gx_cur_stream_push_slice2((const char*)g_box_tier,sizeof(BoxProtocolTier));
	}
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
	printf("cur_message_loopback NOT impl yet\n");
	return -1;
}


void MD5( const unsigned char *input, size_t ilen, unsigned char output[16] )
{
	md5(input,ilen,output);
}


