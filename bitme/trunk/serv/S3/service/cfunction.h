#ifndef __C_FUNCTION_H
#define __C_FUNCTION_H



#include "types.h"


#ifdef WIN32
#define CF_EXPORT  __declspec(dllexport)
#else
#define CF_EXPORT
#endif


// 为了让Lua能够使用而写的C函数
extern "C"{
	
CF_EXPORT void* c_env_get_shared_ptr(int index);

CF_EXPORT bool c_env_set_shared_ptr(int index,void *p);

CF_EXPORT s32 cur_actor_id();

CF_EXPORT u64 cur_user_sn();

CF_EXPORT u32 cur_game_time();

CF_EXPORT u64 cur_game_usec();

CF_EXPORT void cur_write_stream_cleanup();


// 因为传入了长度len，这个接口支持二进制数据 
CF_EXPORT bool log_write(int level,const char*,int len);

CF_EXPORT bool log_write2(int index,const char *ss,int len);

CF_EXPORT void log_force_flush();


CF_EXPORT int string_hash(const char *str);

CF_EXPORT int cur_message_loopback();


CF_EXPORT void MD5( const unsigned char *input, size_t ilen, unsigned char output[16] );

}


#endif

