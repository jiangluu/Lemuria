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

CF_EXPORT u32 cur_game_time();

CF_EXPORT int string_hash(const char *str);



CF_EXPORT void* redisGetReply2(void *c);

CF_EXPORT void* redisConnectWithTimeout2(const char *ip, int port, int ms);

}


#endif

