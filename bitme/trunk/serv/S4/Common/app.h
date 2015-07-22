#ifndef __APP_H
#define __APP_H

#include "link.h"
#include "frontend.h"
#include <string>
#include "alog.h"


#define APP_DEFAULT_STR_LEN 128


typedef void (*FunFrameTimeDriven)(timetype);


struct App{
	char global_id_[APP_DEFAULT_STR_LEN];
	char configs_port_[APP_DEFAULT_STR_LEN];
	s32 app_type_;
	s32 sub_id_;
	s32 stat_;
	s16 stop_loop_;
	
	FrontEnd frontend_;
	FrontEnd backend_;
	
	void* callback_time_driven_;
	
	ALog *log_;
	
	static App* self_;
	
	
	App():stat_(0),app_type_(0),sub_id_(0),callback_time_driven_(0),stop_loop_(0),log_(0){
		global_id_[0] = 0;
		configs_port_[0] = 0;
	}
	
	bool init(char *global_id,char *configs_port,bool init_log=true);
	
	void registerCallback(void* pfun){
		callback_time_driven_ = pfun;
	}
	
	int main_loop(GameTime *timer,int frame_min_time);
	
	bool enterStartupMode(GameTime *timer);
};


#endif


