#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "router.h"
#include "AStream.h"
#include "GXCfunction.h"
#include "LuaInterface.h"



AStream *ws = NULL;


int message_dispatch(GXContext *gx,Link* src_link,InternalHeader *hh,int body_len,char *body)
{
	gx_set_context(gx);
	
	int msg_id = hh->message_id_;
	int r = gx->lua_vm2_->callGlobalFunc<int>("OnGXMessage");
	
	return 0;
}

// 物理连接断掉时的回调 
void on_client_cut(GXContext *gx,Link *ll,int reason,int gxcontext_type)
{
	gx_set_context(gx);
	
	int r = gx->lua_vm2_->callGlobalFunc<int>("OnCut",ll->pool_index_,reason);
	
	if(0 != ll->link_id_[0]){
		gx->unbind(ll->link_id_);
	}
}

extern int redis_thread_frame();

void frame_time_driven(timetype now)
{
	redis_thread_frame();
	//g_gx1->lua_vm2_->callGlobalFunc<void>("OnFrame");
}

