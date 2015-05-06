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



extern GameTime *g_time;

extern ARand *g_rand;

extern ALog *g_log;

extern GXContext *g_gx1;


#define ARAND32 (g_rand->rand32())


#define LUA_GX_ID "gGXContextID"



#endif

