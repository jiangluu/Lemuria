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

// 物理连接断掉时的回调 
void on_client_cut(GXContext *gx,Link *ll,int reason,int gxcontext_type)
{
	gx_set_context(gx);
	
	int r = g_luavm->callGlobalFunc<int>("OnCut",ll->pool_index_,reason);
	
	if(0 != ll->link_id_[0]){
		gx->unbind(ll->link_id_);
	}
	
	if('G' == ll->link_id_[0]){		// It's gate
		g_boxpool->flag_ |= 0x1;
	}
}

void frame_time_driven(timetype now)
{
	g_boxpool->onUpdate(now);
	
	
	static timetype s_prev_time = 0;
	
	if(0 == s_prev_time){
		s_prev_time = now;
	}
	else if(now-s_prev_time >= 20){
		s_prev_time = now;
		
		// the darkside of cur_message_loopback()
		lua_State *L = g_gx1->lua_vm_;
		int the_table = g_gx1->lua_indicator_[1];
		
		size_t stack_num = lua_gettop(L);
		const int limiter = 30;	// 一帧最多那么多个 
		size_t bin_len = 0;
		int i = 0;
		size_t head = 0;
		size_t tail = 0;
		
		size_t the_last = lua_objlen(L,the_table);
		
		lua_pushnil(L);
	    while (i<limiter && tail<the_last && lua_next(L, the_table) != 0) {
	    	tail = lua_tointeger(L,-2);
	    	if(0 == i){
	    		head = tail;
			}
	    	++i;
	    	
	    	const char *bin = lua_tolstring(L,-1,&bin_len);
	    	if(bin && bin_len>=INTERNAL_HEADER_LEN){
	    		// @TODO  call OnMessage
	    		InternalHeader *hh = (InternalHeader*)bin;
	    		memcpy(&g_gx1->input_context_.header_,hh,INTERNAL_HEADER_LEN);
	    		g_gx1->input_context_.header_type_ = 0;
	    		
	    		TailJump *jj = (TailJump*)(bin+hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN));
	    		int ee = TAIL_JUMP_LEN*hh->jumpnum_ <= TAIL_JUMP_MEM_LEN ? TAIL_JUMP_LEN*hh->jumpnum_ : TAIL_JUMP_MEM_LEN;
				memcpy(g_gx1->input_context_.tail_mem_,jj,ee);
				
				g_gx1->rs_ = g_gx1->rs_bak_;
				g_gx1->ws_ = g_gx1->ws_bak_;
				g_gx1->ws_->cleanup();
				g_gx1->rs_->reset(hh->len_-CLIENT_HEADER_LEN,bin+INTERNAL_HEADER_LEN);
				
				gx_set_context(g_gx1);
		
				int r = g_boxpool->OnMessage(g_gx1,hh);
			}
	    	
	    	lua_pop(L, 1);
	    }
	    lua_settop(L,stack_num);
	    
	    // cleanup used
	    for(int i=head;i<=tail;++i){
	    	lua_pushnil(L);
	    	lua_rawseti(L,the_table,i);
		}
		
	}
}


