#ifndef _KFIFO_H
#define  _KFIFO_H



/* kfifo��һ��First In First Out���ݽṹ�������û���ѭ�����е����ݽṹ��ʵ�֣�
���ṩһ���ޱ߽���ֽ�����������Ҫ��һ���ǣ���ʹ�ò���������̼�����
����������ֻ��һ������̺߳�һ�������̵߳ĳ���ʱ�������߳̿��Բ���������
������Ҫ�κμ�����Ϊ���Ϳ��Ա�֤kfifo���̰߳�ȫ��
ע��kfifo��size������2���ݴη���
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

/* ע��kfifo_free()���ͷ��ڴ�ģ�Ҳ����kfifo_init()���������
�����kfifo_cleanup()ֻ����kfifo�ܹ�����
*/
extern void kfifo_free(struct kfifo *fifo);

extern void kfifo_cleanup(struct kfifo *fifo);

extern unsigned int __kfifo_put(struct kfifo *fifo, unsigned char *buffer, unsigned int len);

extern unsigned int __kfifo_get(struct kfifo *fifo,     unsigned char *buffer, unsigned int len);

// ����Ľӿ��Ǻ���֮��ģ�Ϊ�˷�����߽�Լ���ܶ���ӵ�
extern int kfifo_size(struct kfifo *fifo);		// ����size 

extern int kfifo_get_getable(struct kfifo *fifo);	// �����ж��ٿ���get������ �����������get���ǣ� 


#endif

