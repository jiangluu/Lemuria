#ifndef __PACKET_HEADER_H
#define __PACKET_HEADER_H


#include "types.h"



// 客户端与服务器之间的包头 
struct ClientHeader{
	u16 len_;			// 包长度（包含包头长度在内） 
	u16 message_id_;	// 消息ID 
};



// 服务器内部之间的包头 
struct InternalHeader{
	u16 len_;			// 包长度（包含包头长度在内） 
	u16 message_id_;	// 消息ID 
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


#define TAIL_JUMP_MEM_LEN (TAIL_JUMP_LEN*8)		// 重要：能力2最多支持8个尾巴（跳7次） 


#define HEADER_FLAG_BACK 0x1
#define HEADER_FLAG_ROUTE 0x2
#define HEADER_FLAG_BROADCAST 0x4



#endif

