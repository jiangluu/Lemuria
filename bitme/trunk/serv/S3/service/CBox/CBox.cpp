#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "CBox.h"
#include "CBoxPool.h"


bool CBox::init(int id,int num_of_ioline,int line_a_size,int line_b_size,int suggested_actor_num)
{	
	id_ = id;
	
	suggested_actor_num_ = suggested_actor_num;
	
	ioline_ = NULL;
	if(num_of_ioline>0){
		ioline_ = new IOLine[num_of_ioline];
	}
	
	ioline_num_ = num_of_ioline;
	
	FOR(i,num_of_ioline){
		if(!ioline_[i].init(i,line_a_size,line_b_size)){
			return false;
		}
	}
	
	actor_async_data_num_ = suggested_actor_num*8;	// 为了安全， async_data的个数是 suggested_actor_num的很多倍。因为Lua里的actor_id分配算法可能会超出 suggested_actor_num
	a_actor_async_data_ = new ActorAsyncData[actor_async_data_num_];
	if(0 == a_actor_async_data_){
		return false;
	}
	
	luaVM_.SetGlobal("g_box_id",id);
	luaVM_.SetGlobal("g_box_suggested_actor_num",suggested_actor_num);
	luaVM_.SetGlobal("g_app_id",(const char*)CBoxPool::global_id_);
	
	luaVM_.Init();
	
	
	return true;
}


bool CBox::release()
{
	FOR(i,ioline_num_){
		ioline_[i].release();
	}
	
	return true;
}



