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
	u16 box_id_;
	u16 actor_id_;
	u16 gate_pool_index_;
	u16 padding_;
	u64 account_id_;
};



#define CLIENT_HEADER_LEN 4

#define INTERNAL_HEADER_LEN 20



#endif

