#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#ifdef WIN32
	#include <winsock2.h>
	#include <Windows.h>
#endif
#include "CAS.h"
#include "GameTime.h"
#include "msgClient.pb.h"
#include "AStream.h"
#include "app.h"


App *App::self_ = 0;


bool App::init(char *global_id,char *configs_port,bool init_log)
{
	strncpy(global_id_,global_id,APP_DEFAULT_STR_LEN-1);
	strncpy(configs_port_,configs_port,APP_DEFAULT_STR_LEN-1);
	stat_ = 1;
	
	self_ = this;
	
	log_ = new ALog();
	
	if(init_log){
		log_->init(global_id);
	}
	
	return true;
}

int App::main_loop(GameTime *timer,int frame_min_time)
{
	int poll_time = frame_min_time / 3;
	
	log_->setTimer(timer);
	
	while(0 == stop_loop_){
		// 帧开始前先更新时间 
		timer->setTime();
		
		timetype now = timer->currentTime();
		timetype frame_begin = timer->localTime();
		
		timer->incLocalFrame();
		
		// 帧的开头部分先取得所有输入并处理 
		if(frontend_.stat_>0){
			frontend_.frame_poll(now,poll_time);
		}
		if(backend_.stat_>0){
			backend_.frame_poll(now,poll_time);
		}
		
		// 内部时间驱动的
		if(callback_time_driven_/* && timer->isActiveMode()*/){
			(FunFrameTimeDriven(callback_time_driven_))(now);
		}
		
		// 最后把这一帧的处理结果flush出去 
		if(frontend_.stat_>0){
			frontend_.frame_flush(now);
		}
		if(backend_.stat_>0){
			backend_.frame_flush(now);
		}
		
		
		// 做帧数控制
		timer->setTime(); 
		timetype frame_end = timer->localTime();
		if(frame_begin+frame_min_time <= frame_end){
			// 这一帧已经用了至少 FRAME_MIN_TIME时间，不用限制了 
		}
		else{
			// 人为限制帧数
			int left =  frame_begin+frame_min_time - frame_end;
		#ifdef WIN32
			Sleep(left);
		#else
			usleep(left*1000);
		#endif
		}
	}
	
	// 退出循环前把日志flush一下，避免丢失 
	if(log_){
		log_->flush();
	}
	
	return 0;
}


AStream *ws_2 = NULL;

int send_msg_2(Link *ll,int msg_id,int buf_len,char*);

int message_dispatch_startup(Link* src_link,InternalHeader *hh,int body_len,char *body_buf);

bool App::enterStartupMode(GameTime *timer)
{
	if(1 != stat_) return false;
	
	log_->setTimer(timer);
	
	// 这时还没有拿到配置，先按照一个最小值启动 
	if(frontend_.init(FrontEnd::typeFrontEnd,0,4,16*1024,16*1024)==false){
		printf("FrontEnd init failed\n");
		fprintf(stderr,"FrontEnd init failed\n");
		_exit(-1);
	}
	
	if(frontend_.connect2("C0",configs_port_)==false){
		printf("connect configs failed\n");
		fprintf(stderr,"connect configs failed\n");
		_exit(-1);
	}
	
	// say Hi to configs
	if(NULL == ws_2){
		int len = 1024*16;
		void *mem = malloc(len);
		ws_2 = new AStream(len,(char*)mem);
	}
	
	ws_2->cleanup();
	ws_2->set((s32)1);
	ws_2->setStr(global_id_);
	
	send_msg_2(frontend_.getLink(0),Msg::I_SayHi,ws_2->getwritebuflen(),ws_2->getbuf());
	
	
	
	registerCallback(NULL);
	
	frontend_.registerCallback((void*)message_dispatch_startup);
	
	
	int r = main_loop(timer,30);
	
	
	FOR(i,frontend_.link_pool_size_){
		Link *aa = frontend_.link_pool_+i;
		if(aa->isOnline()){
			aa->releaseSystemHandle(&frontend_);
			frontend_.releaseLink(aa);
		}
	}
	
	// just wait a second
	FOR(i,5){
		frontend_.frame_poll(timer->currentTime(),5);
	}
	
	// 出来说明拿到了配置 
	int bak_read_buf_len_ = frontend_.read_buf_len_;
	int bak_write_fifo_len_ = frontend_.write_fifo_len_;
	
	
	frontend_.read_buf_len_ = 1024*16;	// 连接configs固定用这个配置 
	frontend_.write_fifo_len_ = 1024*16;
	
	if(frontend_.resetLinkPool(frontend_.link_pool_size_conf_)==false){
		printf("resetLinkPool failed\n");
		_exit(-2);
	}
	
	// reconnect configs
	if(frontend_.connect2("C0",configs_port_)==false){
		printf("connect configs failed\n");
		fprintf(stderr,"connect configs failed\n");
		_exit(-1);
	}
	
	if(frontend_.start_listening()==false){
		printf("FrontEnd start listening failed at port [%s]\n",frontend_.ip_and_port_);
		_exit(-1);
	}
	
	frontend_.read_buf_len_ = bak_read_buf_len_;	// 恢复用户的配置值 
	frontend_.write_fifo_len_ = bak_write_fifo_len_;
	
	stat_ = 2;
	
	if(backend_.link_pool_size_conf_ > 0){
		if(backend_.init(FrontEnd::typeBackEnd,backend_.layer_,backend_.link_pool_size_conf_,backend_.read_buf_len_,backend_.write_fifo_len_)==false){
			printf("BackEnd init failed\n");
			fprintf(stderr,"BackEnd init failed\n");
			_exit(-1);
		}
	}
	else{
		printf("has NO backend\n");
	}
	
	stat_ = 3;
	
	ws_2->cleanup();
	ws_2->set((s32)stat_);
	ws_2->setStr(global_id_);
	
	send_msg_2(frontend_.getLink(0),Msg::I_FrontEndOnline,ws_2->getwritebuflen(),ws_2->getbuf());
	
	stop_loop_ = 0;
	
	r = main_loop(timer,30);
	
	// 出来说明连接上了现有app 
	
	stop_loop_ = 0;
	
	return true;
}


int message_dispatch_startup(Link* src_link,InternalHeader *hh,int body_len,char *body_buf)
{
	s16 message_id = hh->message_id_;
	printf("Got message ID[%d]  body_len[%d]\n",message_id,body_len);
	
	if(NULL == ws_2){
		int len = 1024*16;
		void *mem = malloc(len);
		ws_2 = new AStream(len,(char*)mem);
	}
	
	ws_2->cleanup();
	
	AStream rs(body_len,body_buf);	// rs means read stream
	
	switch(message_id){
		case Msg::I_SayHiAck:{
			App *app = App::self_;
			
			int has_front = rs.get<s32>();
			if(1 == has_front){
				std::string f_port = rs.getStr();
				strncpy(app->frontend_.ip_and_port_,f_port.c_str(),100);
				app->frontend_.link_pool_size_conf_ = rs.get<s32>();
				app->frontend_.read_buf_len_ = rs.get<s32>();
				app->frontend_.write_fifo_len_ = rs.get<s32>();
			}
			
			int has_back = rs.get<s32>();
			if(1 == has_back){
				app->backend_.link_pool_size_conf_ = rs.get<s32>();
				app->backend_.read_buf_len_ = rs.get<s32>();
				app->backend_.write_fifo_len_ = rs.get<s32>();
			}
			
			// 基本配置拿到，重新初始化
			app->stop_loop_ = 1;
			
			break;
		}
		
		case Msg::I_OnlinedFrontEndList:{
				App *app = App::self_;
				
				FOR(i,999){
					int has_data = rs.get<s32>();
					if(0 == has_data) break;
					
					int is_backend = rs.get<s32>();
					std::string gid = rs.getStr();
					std::string port = rs.getStr();
					
					if(0 != is_backend){
						printf("trying connect to %s\n",port.c_str());
						app->backend_.connect2((char*)gid.c_str(),(char*)port.c_str());
					}
					else{
						app->frontend_.connect2((char*)gid.c_str(),(char*)port.c_str());
					}
					
				}
				
				app->stop_loop_ = 1;
				
			break;
		}
	}
	
	return 0;
}

int send_msg_2(Link *ll,int msg_id,int buf_len,char* buf)
{
	static char buffer[1024*64];
	
	if(0==ll){
		return -1;
	}
	
	if(buf_len>0){		
		InternalHeader *hh = (InternalHeader*)buffer;
		hh->message_id_ = (s16)msg_id;
		int real_len = INTERNAL_HEADER_LEN+buf_len;
		hh->len_ = CLIENT_HEADER_LEN+buf_len;
		hh->account_id_ = 0;
		hh->gate_pool_index_ = 0;
		hh->actor_id_ = ll->pool_index_;
		
		memcpy(buffer+INTERNAL_HEADER_LEN,buf,buf_len);
		
		
		return __kfifo_put(&ll->write_fifo_,(unsigned char*)buffer,real_len);
	}
	else{
		InternalHeader hh;
		hh.message_id_ = (s16)msg_id;
		hh.len_ = CLIENT_HEADER_LEN;
		hh.account_id_ = 0;
		hh.gate_pool_index_ = 0;
		hh.actor_id_ = ll->pool_index_;
		
		
		return __kfifo_put(&ll->write_fifo_,(unsigned char*)&hh,INTERNAL_HEADER_LEN);
		
	}
	
	return 0;
}



