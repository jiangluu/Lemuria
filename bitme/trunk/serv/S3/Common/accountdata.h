#ifndef __PLAYER_FULL_DATA_H
#define __PLAYER_FULL_DATA_H


#include "types.h"



struct PlayerFullData{
	s32 pool_index_;
	s32 playerId_;
	s32 hp_;
	s32 mp_;
	
	void cleanup(){
		pool_index_ = -1;
		playerId_ = -1;
		hp_ = 0;
		mp_ = 0;
	}

};



#endif

