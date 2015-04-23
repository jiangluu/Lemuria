#ifndef __IOLINE_H
#define __IOLINE_H


#include "types.h"
#include "kfifo.h"



// IOLine��һ���������������˫��ͨ���� ����Box�����ͨ�ŵ�Ψһ�Ϸ��ֶΡ� 
// IOLineֻ֧��һ���������̺߳�һ���������̣߳���֧�ָ��ࡣ 
// ʵ���ϣ���ʵ��������2�������ͨ����ɵġ� 

enum IOLineDirection{
	LineA = 0,
	LineB = 1,
};

class IOLine{
public:
	IOLine():id_(-1),lock_value_(0){}
	
	bool init(int id,int line_a_size,int line_b_size);
	
	bool release();		// init�������
	
	
	
	int push(IOLineDirection a_or_b,char *buf,int len); 	// �����������push���� 
	
	int pull(IOLineDirection a_or_b,char *buf,int len); 	// �����������pull���� 
	
	int observe(IOLineDirection a_or_b);		// ��һ����������ж������ݿ�����ȡ��ֻ�ǿ������ı��κ� 
	int size(IOLineDirection a_or_b);
	
	void clear(IOLineDirection a_or_b);		// ���ĳ������Ļ��� 
	
	void lock(){ lock_value_=1; }
	void unlock(){ lock_value_=0; }
	bool is_locked(){ return 1==lock_value_; }
	
private:
	int id_;
	struct kfifo fifo_[2];
	
	s16 lock_value_;
}; 



#endif

