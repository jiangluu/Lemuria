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


#define LOOPBACK_BUF_LEN (1024*256)

int message_dispatch(GXContext *gx,Link* src_link,InternalHeader *hh,int body_len,char *body)
{
	gx_set_context(gx);
	
	int r = g_boxpool->OnMessage(gx,hh);
	
	if(0 != (gx->input_context_.flag_ & 0x2)){
		if(gx->rs_){
			static char *s_mem = (char*)calloc(LOOPBACK_BUF_LEN,1);
			
			AStream *aa = gx->rs_;
			if(aa->getreadbuflen() <= (LOOPBACK_BUF_LEN-INTERNAL_HEADER_LEN-TAIL_JUMP_MEM_LEN)){
				memcpy(s_mem,&gx->input_context_.header_,INTERNAL_HEADER_LEN);
				memcpy(s_mem+INTERNAL_HEADER_LEN,aa->getbuf(),aa->getreadbuflen());
				
				// save it
				lua_State *L = gx->lua_vm_;
				lua_pushlstring(L,s_mem,aa->getreadbuflen()+INTERNAL_HEADER_LEN);
				int the_table = gx->lua_indicator_[1];
				lua_rawseti(L,the_table,lua_objlen(L,the_table)+1);
			}
		}
		
		gx->input_context_.flag_ = 0;
	}
	
	return r;
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
		
		//size_t stack_num = lua_gettop(L);
		const int limiter = 30;	// 一帧最多那么多个 
		size_t bin_len = 0;
		int i = 1;
		int counter = 0;
		
		size_t the_last = lua_objlen(L,the_table);
		
		lua_pushnil(L);
	    while (counter<limiter && i<=the_last){
	    	lua_rawgeti(L,the_table,i);
	    	++i;
	    	
	    	if(!lua_isnil(L,-1)){
	    		++counter;
	    		
	    		const char *bin = lua_tolstring(L,-1,&bin_len);
	    		lua_pop(L,1);
		    	if(bin && bin_len>=INTERNAL_HEADER_LEN){
		    		// @TODO  call OnMessage
		    		g_gx1->input_context_.reset();
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
					
					if(0 == (g_gx1->input_context_.flag_ & 0x2)){
						lua_pushnil(L);
						lua_rawseti(L,the_table,i-1);
					}
					else{
						g_gx1->input_context_.flag_ = 0;
					}
				}
			}
			else{
				lua_pop(L,1);
			}
	    }
	    //lua_settop(L,stack_num);
	    
		
		lua_gc(L,LUA_GCSTEP,5);
		
	}
}


