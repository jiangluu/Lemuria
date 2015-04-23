#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "service.h"
#include "AStream.h"
#include "GXCfunction.h"
#include "LuaInterface.h"
#include "CBox/CBoxPool.h"



extern LuaInterface *g_luavm;
extern CBoxPool *g_boxpool;


int message_dispatch(GXContext *gx,Link* src_link,InternalHeader *hh,int body_len,char *body)
{
	gx_set_context(gx);
	
	return g_boxpool->OnMessage(gx,hh);
}

// �������Ӷϵ�ʱ�Ļص� 
void on_client_cut(GXContext *gx,Link *ll,int reason,int gxcontext_type)
{
	gx_set_context(gx);
	
	int r = g_luavm->callGlobalFunc<int>("OnCut",ll->pool_index_,reason);
	
	if(0 != ll->link_id_[0]){
		gx->unbind(ll->link_id_);
	}
}

void frame_time_driven(timetype now)
{
	g_boxpool->onUpdate(now);
}


