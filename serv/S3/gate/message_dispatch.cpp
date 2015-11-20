#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <assert.h>
#include <stdint.h>
#include "gate.h"
#include "AStream.h"
#include "GXCfunction.h"
#include "LuaInterface.h"
#include "omt.h"



//#define OFFLINE_TIMEOUT 60000	// 60秒没有任何消息算下线 


extern LuaInterface *g_luavm;



int server_kick_client(Link *ll,int reason);



// 客户端来的消息，包头是ClientHeader 
int message_dispatch_2(GXContext*,Link* src_link,ClientHeader *hh,int body_len,char *body)
{
	int message_id = hh->message_id_;
	
#ifdef ENABLE_ENCRYPT
	if(body_len<1){
		// 认为不合法，踢掉此玩家 
		return -1;
	}
	
	if(! src_link->enc_is_first_){
		++ src_link->enc_inc_;
		if((*body) != src_link->enc_inc_) return -1;
	}
	else{
		src_link->enc_inc_ = *body;
		src_link->enc_is_first_ = false;
	}
	
	++body;
	--body_len;
	-- hh->len_;
	//printf("OK  %d  %d  %d\n",(int)src_link->enc_inc_,body_len,message_id);
#endif
	
	
	// 流控、安全性等加在这里 
//#define LK_LIMIT_TIMES 100
//#define LK_LIMIT_TRAFFIC	1024*100
	static int lk_limit_times = -1;
	static int lk_limit_traffic = -1;
	if(-1 == lk_limit_times){
		lk_limit_times = g_luavm->GetGlobal<int>("conf_lk_limit_times");
		lk_limit_traffic = g_luavm->GetGlobal<int>("conf_lk_limit_traffic");
		
		lk_limit_times = 0==lk_limit_times?100:lk_limit_times;
		lk_limit_traffic = 0==lk_limit_traffic?(1024*100):lk_limit_traffic;
	}
	
	if(src_link->lk_times_+1<=lk_limit_times && (s64)(src_link->lk_traffic_)+body_len+CLIENT_HEADER_LEN<=lk_limit_traffic){
		++ src_link->lk_times_;
		src_link->lk_traffic_ += body_len+CLIENT_HEADER_LEN;
		
		src_link->last_active_time_ = g_time->currentTime();
		
		if(0 == src_link->first_packet_time_){	// init it
			src_link->first_packet_time_ = (u32)g_time->getANSITime();
		}
		src_link->total_traffic_ += body_len+CLIENT_HEADER_LEN+20;
	}
	else{
		// 额外日志
		static char *buf = NULL;
		if(NULL == buf){
			buf = (char*)malloc(256);
		}
		memset(buf,0,256);
		if(src_link->lk_times_+1 > lk_limit_times){
			sprintf(buf,"too many packets in short time. actor_id[%d]",src_link->app_actor_id_);
		}
		else{
			sprintf(buf,"traffic flowup. actor_id[%d]",src_link->app_actor_id_);
		}
		g_log->write(1,buf,strlen(buf));
		g_log->flush();
		
		// 认为不合法，踢掉此玩家 
		server_kick_client(src_link,2);
		return -1;
	}
	
	
	if(message_id>0 && message_id < 50000){	// 这个之前的认为应该转发到Service 
		// 现在还没有真正的定位能力 
		if(src_link->session_link_index_ < 0){
			// 还没有确定session给哪一个service，给它分配一个 。这里先用一种很简单的random分配 
			const int piece_num = 2;
			int whom = ARAND32 % piece_num;
			
			int counter = 0;
			int result = -1;
			int first_met = -1;
			FOR(i,g_gx1->link_pool_size_){
				Link *aa = g_gx1->link_pool_ + i;
				if(1==aa->pool_stat_ && aa->isService()){
					if(first_met < 0){
						first_met = i;
					}
					
					if(counter == whom){
						result = i;
						break;
					}
					else{
						++counter;
					}
				}
			}
			
			if(result>=0){
				src_link->session_link_index_ = result;
			}
			else{
				src_link->session_link_index_ = first_met;
			}
		}
		
		Link *ll = g_gx1->getLink(src_link->session_link_index_);
		if(ll){
			static char* buffer = NULL;
			if(NULL == buffer){
				buffer = (char*)malloc(g_gx1->read_buf_len_ * 2);
			}
			static char* buffer3 = NULL;
			if(NULL == buffer3){
				buffer3 = (char*)malloc(128);
				memset(buffer3,0,128);
			}
			
			
			
					kfifo *ff = &ll->write_fifo_;
					InternalHeader *tt = (InternalHeader*)buffer;
					memcpy(tt,hh,CLIENT_HEADER_LEN);
					tt->flag_ = 0;
					tt->jumpnum_ = 0;
					
					BoxProtocolTier *bt = (BoxProtocolTier*)(buffer+INTERNAL_HEADER_LEN);
					bt->reset();
					bt->box_id_ = src_link->app_box_id_;
					bt->actor_id_ = src_link->app_actor_id_;
					bt->gate_pool_index_ = src_link->pool_index_;
					bt->padding_ = 0;
					bt->usersn_ = src_link->usersn_;
					
					tt->len_ += sizeof(BoxProtocolTier);
					
					
					memcpy(buffer+INTERNAL_HEADER_LEN+sizeof(BoxProtocolTier),body,body_len);
					
#define IS_LOGIN_MESSAGE(id) (1==id || 9==id)
					if(! IS_LOGIN_MESSAGE(message_id)){
						__kfifo_put(ff,(unsigned char*)buffer,INTERNAL_HEADER_LEN+sizeof(BoxProtocolTier)+body_len);
					}
					else{
						nc_get_ip(src_link->sock_,buffer3,127);
						int len = strlen(buffer3);
						// append 一个字符串在最后 
						u16 *uu = (u16*)(buffer+INTERNAL_HEADER_LEN+sizeof(BoxProtocolTier)+body_len);
						*uu = len;
						memcpy(buffer+INTERNAL_HEADER_LEN+sizeof(BoxProtocolTier)+body_len+sizeof(u16),buffer3,len);
						tt->len_ += sizeof(u16)+len;
						
						__kfifo_put(ff,(unsigned char*)buffer,INTERNAL_HEADER_LEN+sizeof(BoxProtocolTier)+body_len+sizeof(u16)+len);
					}
		}
	}
	else{
		printf("message_id out of range:%d\n",message_id);
	}
	
	return 0;
}

void on_client_cut_2(GXContext*,Link *ll,int reason,int gxcontext_type)
{
	printf("on_client_cut  link_index [%d]  reason [%d]  gxcontext_type[%d]\n",ll->pool_index_,reason,gxcontext_type);
	
	if(0 != ll->first_packet_time_){
		static char *buf2 = NULL;
		static int counter = 0;
		
		++counter;
		if(0 == buf2){
			buf2 = (char*)malloc(2048);
		}
		
		int inteval = g_time->getANSITime() - ll->first_packet_time_;
		if(0 == inteval){
			inteval = 1;
		}
		sprintf(buf2,"traffic-report  tps[%d] total[%u] timeremain[%d] link_index[%d] reason[%d]",
		ll->total_traffic_/inteval,ll->total_traffic_,inteval,ll->pool_index_,reason);
		
		g_log->write(1,buf2,strlen(buf2));
		if(counter >= 100){
			g_log->flush();
			counter = 0;
		}
	}
	
	{
		bool send_nodify = true;		
		if(send_nodify){
			// 是客户端断线，发消息 
			Link *ta_service = g_gx1->getLink(ll->session_link_index_);
			if(ta_service){
				InternalHeader tt;
				tt.message_id_ = 1001;
				tt.len_ = CLIENT_HEADER_LEN+sizeof(BoxProtocolTier);
				tt.flag_ = 0;
				tt.jumpnum_ = 0;
				
				BoxProtocolTier bt;
				bt.reset();
				bt.box_id_ = ll->app_box_id_;
				bt.actor_id_ = ll->app_actor_id_;
				bt.gate_pool_index_ = ll->pool_index_;
				bt.padding_ = 0;
				bt.usersn_ = ll->usersn_;
				
				__kfifo_put(&ta_service->write_fifo_,(unsigned char*)&tt,INTERNAL_HEADER_LEN);
				__kfifo_put(&ta_service->write_fifo_,(unsigned char*)&bt,sizeof(BoxProtocolTier));
			}
		}
	}
}


int message_dispatch(GXContext *gx,Link* src_link,InternalHeader *hh,int body_len,char *body)
{
	gx_set_context(gx);
	
	int msg_id = hh->message_id_;
	if(msg_id>=8000 && msg_id<=8100){
		int r = g_luavm->callGlobalFunc<int>("OnInternalMessage");
	}
	else{
		if(0 == (hh->flag_ & HEADER_FLAG_BROADCAST)){
			BoxProtocolTier *bt = (BoxProtocolTier*)body;
			Link *ll = g_gx2->getLink(bt->gate_pool_index_);
			if(ll){
						hh->len_ -= sizeof(BoxProtocolTier);
						ll->app_box_id_ = bt->box_id_;
						ll->app_actor_id_ = bt->actor_id_;
						if(bt->usersn_ != (u64)-1) ll->usersn_ = bt->usersn_;
						kfifo *ff = &ll->write_fifo_;
						__kfifo_put(ff,(unsigned char*)hh,CLIENT_HEADER_LEN);
						__kfifo_put(ff,(unsigned char*)(bt+1),body_len-sizeof(BoxProtocolTier));
						
						ll->total_traffic_ += body_len+CLIENT_HEADER_LEN+20;
			}
		}
		else{
			// BROADCAST
			BoxProtocolTier *bt = (BoxProtocolTier*)body;
			hh->len_ -= sizeof(BoxProtocolTier);
			FOR(i,g_gx2->link_pool_size_){
				Link *ll = g_gx2->getLink(i);
				if(ll){
						kfifo *ff = &ll->write_fifo_;
						__kfifo_put(ff,(unsigned char*)hh,CLIENT_HEADER_LEN);
						__kfifo_put(ff,(unsigned char*)(bt+1),body_len-sizeof(BoxProtocolTier));
						
						ll->total_traffic_ += body_len+CLIENT_HEADER_LEN+20;
				}
			}
		}
		
	}
	
	return 0;
}

// 物理连接断掉时的回调 
void on_client_cut(GXContext *gx,Link *ll,int reason,int gxcontext_type)
{
	gx_set_context(gx);
	
	int r = g_luavm->callGlobalFunc<int>("OnCut",ll->pool_index_,reason);
	
	if(0 != ll->link_id_[0]){
		gx->unbind(ll->link_id_);
	}
}

// 服务端主动踢掉一个人 
int server_kick_client(Link *ll,int reason)
{
	// 给service发消息通知下线
	on_client_cut_2(g_gx2,ll,reason,1);
	
	// 释放它
	g_gx2->forceCutLink(ll);
	 
	return 0;
}

int check_client_links(timetype now)
{
	static timetype pre_point_1 = 0;
	if(0 == pre_point_1){
		pre_point_1 = now;
		return 0;
	}
	
	static int offline_timeout = -1;
	if(-1 == offline_timeout){
		offline_timeout = g_luavm->GetGlobal<int>("conf_offline_timeout");
		offline_timeout = 0==offline_timeout?60:offline_timeout;
	}
	
	if(now >= pre_point_1+3000){
		pre_point_1 = now;
		
		FOR(i,g_gx2->link_pool_size_){
			Link *ll = g_gx2->getLink(i);
			if(ll){
				ll->lk_times_ = 0;
				ll->lk_traffic_ = 0;
			}
			if(ll && 0!=ll->last_active_time_ && ll->last_active_time_+offline_timeout*1000 <now){
				// 认为断线，踢掉之 
				server_kick_client(ll,3);
			}
		}
				
	}
	
	
	return 0;
}


void frame_time_driven(timetype now)
{
	check_client_links(now);
}

