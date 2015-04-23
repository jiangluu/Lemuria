#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "IOLine.h"


bool IOLine::init(int id,int line_a_size,int line_b_size)
{
	id_ = id;
	
	if(1 != kfifo_init(fifo_,line_a_size)){
		return false;
	}
	
	if(1 != kfifo_init(fifo_+1,line_b_size)){
		kfifo_free(fifo_);
		return false;
	}
	
	return true;
}

bool IOLine::release()
{
	kfifo_free(fifo_);
	kfifo_free(fifo_+1);
	
	return true;
}


#define MAX_PULL_LEN (1024*1024*16)		// 一次pull数据应该是不会超过这个的

int IOLine::push(IOLineDirection a_or_b,char *buf,int len)
{
	int aa = (int)a_or_b;
	if (aa<0 || aa>1) return -1;
	if (len<0 || len>MAX_PULL_LEN) return -1;
	
	return __kfifo_put(fifo_+aa,(unsigned char*)buf,len);
}

int IOLine::pull(IOLineDirection a_or_b,char *buf,int len)
{
	int aa = (int)a_or_b;
	if (aa<0 || aa>1) return -1;
	if (len<0 || len>MAX_PULL_LEN) return -1;
	
	return __kfifo_get(fifo_+aa,(unsigned char*)buf,len);
}

int IOLine::observe(IOLineDirection a_or_b)
{
	int aa = (int)a_or_b;
	if (aa<0 || aa>1) return -1;
	
	return kfifo_get_getable(fifo_+aa);
}

int IOLine::size(IOLineDirection a_or_b)
{
	int aa = (int)a_or_b;
	if (aa<0 || aa>1) return -1;
	
	return kfifo_size(fifo_+aa);
}

void IOLine::clear(IOLineDirection a_or_b)
{
	int aa = (int)a_or_b;
	if (aa<0 || aa>1) return;
	
	kfifo_cleanup(fifo_+aa);
}



