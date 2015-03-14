#ifndef _ALOG_H
#define  _ALOG_H


struct GameTime;

// 日志类

class ALog{
public:
	enum{
		verbose = 0,
		debug = 1,
		info = 2,
		warning = 3,
		error = 4,
		final = 5,
	};
	
	bool init(char *name);
	void release();
	
	void setTimer(GameTime* t){
		timer_ = t;
	}
	
	bool write(int level,const char* text,int textlen=0);
	
	ALog():timer_(0),buffer_len_(0),buffer_(0),cursor_(0),watermark_(0){
		name_[0] = 0;
		time_str_[0] = 0;
		file_name_[0] = 0;
	}
	
	bool flush();
	
	// 下面应该是私有的，勿调用 
	void fill_time_str();
	void fill_file_name();
	
	GameTime *timer_;
	char name_[64];
	
	int buffer_len_;
	char *buffer_;
	int cursor_;
	int watermark_;
	
	char time_str_[512];
	char file_name_[128];
}; 


#endif

