#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "router.h"
#include "AStream.h"
#include "GXContext.h"



AStream *ws = NULL;


int message_dispatch(GXContext*,Link* src_link,InternalHeader *hh,int body_len,char *body)
{
	return 0;
}

// 物理连接断掉时的回调 
void on_client_cut(GXContext *gx,Link *ll,int reason,int gxcontext_type)
{
}

void frame_time_driven(timetype now)
{
}

