#ifndef _KFIFO_H
#define  _KFIFO_H



/* kfifo是一个First In First Out数据结构，它采用环形循环队列的数据结构来实现；
它提供一个无边界的字节流服务，最重要的一点是，它使用并行无锁编程技术，
即当它用于只有一个入队线程和一个出队线程的场情时，两个线程可以并发操作，
而不需要任何加锁行为，就可以保证kfifo的线程安全。
注意kfifo的size必须是2的幂次方。
*/
struct kfifo {
	unsigned char *buffer;      /* the buffer holding the data */
	unsigned int size;   /* the size of the allocated buffer */
	unsigned int in;     /* data is added at offset (in % size) */
	unsigned int out;    /* data is extracted from off. (out % size) */
	
	kfifo():buffer(0),size(0),in(0),out(0){}
};


// API here
extern int kfifo_init(struct kfifo *fifo,unsigned int size);

extern int kfifo_init2(struct kfifo *fifo,char *buf,unsigned int size);

/* 注意kfifo_free()是释放内存的，也就是kfifo_init()的逆操作；
下面的kfifo_cleanup()只是让kfifo能够复用
*/
extern void kfifo_free(struct kfifo *fifo);

extern void kfifo_cleanup(struct kfifo *fifo);

extern unsigned int __kfifo_put(struct kfifo *fifo, unsigned char *buffer, unsigned int len);

extern unsigned int __kfifo_get(struct kfifo *fifo,     unsigned char *buffer, unsigned int len);

// 下面的接口是核心之外的，为了方便或者节约性能而添加的
extern int kfifo_size(struct kfifo *fifo);		// 返回size 

extern int kfifo_get_getable(struct kfifo *fifo);	// 看看有多少可以get的数据 （但并不真的get它们） 


#endif

