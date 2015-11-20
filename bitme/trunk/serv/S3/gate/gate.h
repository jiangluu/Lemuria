#ifndef __GATE_H
#define __GATE_H



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "types.h"
#include "CAS.h"
#include "ArtmeHash.h"
#include "GameTime.h"
#include "ARand.h"
#include "alog.h"
#include "GXContext.h"
#include "GXCfunction.h"



extern GameTime *g_time;

extern ARand *g_rand;

extern ALog *g_log;

extern GXContext *g_gx1;

extern GXContext *g_gx2;



#define ARAND32 (g_rand->rand32())


#define LUA_GX_ID "gGXContextID"


struct BoxProtocolTier{
	u16 box_id_;
	u16 actor_id_;
	u16 gate_pool_index_;
	u16 padding_;
	u64 usersn_;
	
	void reset(){
		box_id_ = -1;
		actor_id_ = -1;
		gate_pool_index_ = -1;
		padding_ = 0;
		usersn_ = -1;
	}
};


#endif

