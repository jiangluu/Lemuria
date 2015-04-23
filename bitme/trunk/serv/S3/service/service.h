#ifndef __ROUTER_H
#define __ROUTER_H



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
extern ALog *g_yylog;

extern GXContext *g_gx1;


#define ARAND32 (g_rand->rand32())


#define LUA_GX_ID "gGXContextID"


struct BoxProtocolTier{
	int box_id_;
	int actor_id_;
	u64 usersn_;
	
	void reset(){
		box_id_ = -1;
		actor_id_ = -1;
		usersn_ = -1;
	}
};

extern  BoxProtocolTier *g_box_tier;


#endif

