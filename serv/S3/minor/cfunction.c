#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "minor.h"
#include "LuaInterface.h"
#include "cfunction.h"
#include "link.h"
#include "hiredis/hiredis.h"



#define MAX_A_STR_LEN (1024*128)
static char s_buf1[MAX_A_STR_LEN];




u32 cur_game_time()
{
	return g_time->currentTime();
}


int string_hash(const char *str)
{
	return string_hash_with_client(str);
}


void* redisGetReply2(void *c)
{
	void *to_release = 0;
	int a = redisGetReply((redisContext*)c, &to_release);
	if(REDIS_OK==a){
		return to_release;
	}
	else{
		printf("redisGetReply2 Error: %s\n", ((redisContext*)c)->errstr);
		return 0;
	}
}

void* redisConnectWithTimeout2(const char *ip, int port, int ms)
{
	struct timeval tv;
	tv.tv_sec = ms / 1000;
	tv.tv_usec = (ms % 1000) * 1000;
	
	return redisConnectWithTimeout(ip,port,tv);
}



