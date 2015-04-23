#ifndef __CBOX_H
#define __CBOX_H


#include "types.h"
#include "IOLine.h"
#include "GXContext.h"
#include "../service.h"
#include "../LuaInterface.h"



// Box是一个“盒子”，它给业务逻辑代码提供一个稳定可靠的运行环境。 
// CBox是它的实现代码在C中的部分。
// 我们的设计中， 业务逻辑代码使用Lua语言。每个Box有一个自己的LuaVM。 

struct ActorAsyncData{
	GXContext::InputContext context_;
	BoxProtocolTier box_tier_;
	u32 serial_[2];
	s16 typee_;
	bool flag_[8];
	
	ActorAsyncData():typee_(0){ serial_[0]=0;serial_[1]=0;FOR(i,8) flag_[i]=false; }
	
	void cleanup(){
		serial_[0]=0;serial_[1]=0;
		typee_ = 0;
		FOR(i,8) flag_[i]=false;
		context_.reset();
		box_tier_.reset();
	}
};

class CBox{
public:
	CBox():id_(-1),suggested_actor_num_(50),current_actor_num_(0),ioline_num_(0),ioline_(0),actor_async_data_num_(0),a_actor_async_data_(0){}
	
	bool init(int id,int num_of_ioline,int line_a_size,int line_b_size,int suggested_actor_num);
	bool release();
	
	
	
	int getId(){ return id_; }
	
	LuaInterface* getLuaVM(){
		return &luaVM_;
	}
	
	int get_suggested_actor_num(){
		return suggested_actor_num_;
	}
	
	IOLine* getIOLine(int id){
		if(id<0 || id>=ioline_num_) return 0;
		return ioline_+id;
	}
	
	void current_actor_num_dec(int a){
		current_actor_num_ -= a;
		current_actor_num_ = current_actor_num_>0?current_actor_num_:0;
	}
	
	
	friend class CBoxPool;
	
private:
	int id_;
	
	int suggested_actor_num_;
	int current_actor_num_;
	
	int ioline_num_;
	IOLine *ioline_;
	
	LuaInterface luaVM_;

public:
	int actor_async_data_num_;
	ActorAsyncData *a_actor_async_data_;
}; 



#endif

