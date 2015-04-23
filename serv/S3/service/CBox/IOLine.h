#ifndef __IOLINE_H
#define __IOLINE_H


#include "types.h"
#include "kfifo.h"



// IOLine是一个数据输入输出的双向通道。 它是Box和外界通信的唯一合法手段。 
// IOLine只支持一个生产者线程和一个消费者线程，不支持更多。 
// 实现上，它实际上是由2个单向的通道组成的。 

enum IOLineDirection{
	LineA = 0,
	LineB = 1,
};

class IOLine{
public:
	IOLine():id_(-1),lock_value_(0){}
	
	bool init(int id,int line_a_size,int line_b_size);
	
	bool release();		// init的逆操作
	
	
	
	int push(IOLineDirection a_or_b,char *buf,int len); 	// 在这个方向上push数据 
	
	int pull(IOLineDirection a_or_b,char *buf,int len); 	// 在这个方向上pull数据 
	
	int observe(IOLineDirection a_or_b);		// 看一下这个方向有多少数据可以拉取，只是看，不改变任何 
	int size(IOLineDirection a_or_b);
	
	void clear(IOLineDirection a_or_b);		// 清空某个方向的缓冲 
	
	void lock(){ lock_value_=1; }
	void unlock(){ lock_value_=0; }
	bool is_locked(){ return 1==lock_value_; }
	
private:
	int id_;
	struct kfifo fifo_[2];
	
	s16 lock_value_;
}; 



#endif

