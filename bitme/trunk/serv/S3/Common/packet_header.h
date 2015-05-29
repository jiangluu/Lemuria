#ifndef __PACKET_HEADER_H
#define __PACKET_HEADER_H


#include "types.h"



// �ͻ����������֮��İ�ͷ 
struct ClientHeader{
	u16 len_;			// �����ȣ�������ͷ�������ڣ� 
	u16 message_id_;	// ��ϢID 
};



// �������ڲ�֮��İ�ͷ 
struct InternalHeader{
	u16 len_;			// �����ȣ�������ͷ�������ڣ� 
	u16 message_id_;	// ��ϢID 
	u16 flag_;
	u16 jumpnum_;
};


#define TAIL_ID_LEN 8

struct TailJump{
	u32 local_index_;
	char portal_id_[TAIL_ID_LEN];
};


#define CLIENT_HEADER_LEN 4

#define INTERNAL_HEADER_LEN 8

#define TAIL_JUMP_LEN 12


#define TAIL_JUMP_MEM_LEN (TAIL_JUMP_LEN*8)		// ��Ҫ������2���֧��8��β�ͣ���7�Σ� 


#define HEADER_FLAG_BACK 0x1
#define HEADER_FLAG_ROUTE 0x2
#define HEADER_FLAG_BROADCAST 0x4



#endif

