#include "types.h"
#include "kfifo.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>




int kfifo_init(struct kfifo *fifo,unsigned int size)
{
	unsigned char *tt = 0;
	
	if(0==fifo || size==0 || size >= 1024*1024*1024) return 0;

	if (size & (size - 1)) {
		printf("Do not support no power of two!\n");
		//size = roundup_pow_of_two(size);
		return 0;
	}

	fifo->buffer = 0;
	fifo->size = 0;
	fifo->in = fifo->out = 0;

	tt = (unsigned char*)malloc(size);
	if(!tt){
		return 0;
	}

	fifo->buffer = tt;
	fifo->size = size;

	return 1;
}

int kfifo_init2(struct kfifo *fifo,char *buf,unsigned int size)
{
	if(0==fifo || 0==buf || size==0 || size >= 1024*1024*1024) return 0;

	if (size & (size - 1)) {
		printf("Do not support no power of two!\n");
		//size = roundup_pow_of_two(size);
		return 0;
	}

	fifo->buffer = (unsigned char*)buf;
	fifo->size = size;
	fifo->in = fifo->out = 0;

	return 1;
}

void kfifo_free(struct kfifo *fifo)
{
	if(!fifo) return;
	
	if(fifo->buffer){
		free(fifo->buffer);
		fifo->buffer = 0;
	}
	fifo->size = 0;
	fifo->in = fifo->out = 0;
}

void kfifo_cleanup(struct kfifo *fifo)
{
	if(!fifo) return;
	
	fifo->in = fifo->out = 0;
}


#define min(a,b) (a)<(b)?(a):(b)

unsigned int __kfifo_put(struct kfifo *fifo, unsigned char *buffer, unsigned int len)
{
	if(!fifo || len==0 || buffer==0) return 0;
	
	unsigned int l = 0;

	if (len > fifo->size - fifo->in + fifo->out)		//缓冲区 满了
	{
		return 0;
	}
	
	len = min(len, fifo->size - fifo->in + fifo->out);
	if(0==len) return 0;

	/* first put the data starting from fifo->in to buffer end */
	l = min(len, fifo->size - (fifo->in & (fifo->size - 1)));
	memcpy(fifo->buffer + (fifo->in & (fifo->size - 1)), buffer, l);

	/* then put the rest (if any) at the beginning of the buffer */
	memcpy(fifo->buffer, buffer + l, len - l);

	fifo->in += len;

	return len;
}

unsigned int __kfifo_get(struct kfifo *fifo,     unsigned char *buffer, unsigned int len)
{
	if(!fifo || len==0 || buffer==0) return 0;

	unsigned int l = 0;
	
	len = min(len, fifo->in - fifo->out);
	if(0==len) return 0;

	/* first get the data from fifo->out until the end of the buffer */
	l = min(len, fifo->size - (fifo->out & (fifo->size - 1)));
	memcpy(buffer, fifo->buffer + (fifo->out & (fifo->size - 1)), l);

	/* then get the rest (if any) from the beginning of the buffer */
	memcpy(buffer + l, fifo->buffer, len - l);

	fifo->out += len;

	return len;
}


//================================================================================================
int kfifo_size(struct kfifo *fifo)
{
	return fifo->size;
}

int kfifo_get_getable(struct kfifo *fifo)
{
	return fifo->in - fifo->out;
}


