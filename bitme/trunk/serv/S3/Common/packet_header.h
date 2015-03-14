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
	u16 box_id_;
	u16 actor_id_;
	u16 gate_pool_index_;
	u16 padding_;
	u64 account_id_;
};



#define CLIENT_HEADER_LEN 4

#define INTERNAL_HEADER_LEN 20



#endif

