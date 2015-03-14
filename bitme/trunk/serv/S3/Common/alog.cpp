#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "types.h"
#include "alog.h"
#include "GameTime.h"



bool ALog::init(char *name)
{
	if(NULL==name) return false;
	
	strncpy(name_,name,63);
	
	buffer_len_ = 1024*1024*8;
	watermark_ = buffer_len_ - 1024*64;
	
	fill_file_name();
	
	buffer_ = (char*)malloc(buffer_len_);
	if(NULL==buffer_) return false;
	
		
	return true;
}

void ALog::release()
{
	flush();
	
	if(buffer_){
		free(buffer_);
		buffer_ = NULL;
	}
}

// help functions
const char* __getstr_from_level_int(int level)
{
	static const char* s_arr[] = {
	"verbose",
	"debug",
	"info",
	"warning",
	"error",
	"final",
	};
	
	if(level>=0 && level<ALog::final+1){
		return s_arr[level];
	}
	
	return NULL;
}

bool __append(ALog *ll,const char* ss,int sslen)
{
	if(NULL==ss) return false;
	
	if(sslen<=0){
		sslen = strlen(ss);
	}
	
	if(sslen>=1024*4) return false;	// 认为单条日志大小不能超过4K 
	
	int cursor_after = ll->cursor_+sslen;
	if(cursor_after >= ll->watermark_){
		bool r = ll->flush();
		if(!r) return false;
	}
	
	memcpy(ll->buffer_+ll->cursor_,ss,sslen);
	ll->cursor_ += sslen;
	
	
	return true;
}

bool ALog::write(int level,const char* text,int textlen)
{
	if(NULL==text) return false;
	
	const char* ss = __getstr_from_level_int(level);
	if(NULL==ss) return false;
	
	fill_time_str();
	
	__append(this,ss,0);
	__append(this,time_str_,0);
	bool r = __append(this,text,textlen);
	__append(this,"\r\n",2);
	
	return r;
}

bool ALog::flush()
{
	if(cursor_ <= 0) return true;
	
	FILE *fp = fopen(file_name_,"ab");
	if(NULL==fp) return false;
	
	fwrite(buffer_,cursor_,1,fp);
	
	fclose(fp);
	
	cursor_ = 0;
	
	return true;
}

void ALog::fill_file_name()
{
	sprintf(file_name_,"log%s.log",name_);
}

void ALog::fill_time_str()
{
	if(NULL==timer_){
		sprintf(time_str_,"[12345678]");
	}
	else{
		sprintf(time_str_,"[ansi:%d, frame:%ll]",timer_->getANSITime(),timer_->getFrame());
	}
}



