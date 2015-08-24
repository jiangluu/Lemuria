#ifndef _ASTREAM_H
#define  _ASTREAM_H




//template<typename U>
class AStream{	// means ArtmeStream
public:
	AStream(s32 len,char *data):data_(data),data_len_(len),offset_read_(0),offset_write_(0),
	offset_write_protect_(0){}
	
	
	// 注意：这个函数并不释放资源，仅仅是使此对象能被复用而已。 
	void cleanup(){
		offset_read_ = 0;
		//offset_write_ = 0;
		offset_write_ = offset_write_protect_;
	}
	
	void protect_n(int n){
		if(n > 0){
			offset_write_protect_ = n;
		}
		else{
			offset_write_protect_ = 0;
		}
	}
	
	void reset(s32 len,char *data){
		data_ = data;
		data_len_ = len;
		offset_read_ = 0;
		offset_write_ = 0;
		offset_write_protect_ = 0;
	}
	
	bool is_end(){
		return offset_read_>=data_len_;
	}
	
	std::string getStr(){
		s16 len = get<s16>();
		if(len<=0 || len+offset_read_>data_len_) return "undefined";
		
		std::string rr;
		rr.assign(data_+offset_read_,len);
		offset_read_ += len;
		return rr;
	}
	
	// 返回当前偏移所指，且往后移 bin_len
	const char* get_bin(int bin_len){
		if(bin_len<=0 || bin_len+offset_read_>data_len_) return NULL;
		
		char *r = data_+offset_read_;
		offset_read_ += bin_len;
		
		return r;
	}
	
	template<typename U>
	U get(){
		s32 bak = offset_read_;
		if(offset_read_+sizeof(U) > data_len_) return U();	// 不能读越界 
		offset_read_ += sizeof(U);
		return *((U*)(data_+bak));
	}
	
	// peek 是不移动 offset_read_的 
	template<typename U>
	U peek(){
		s32 bak = offset_read_;
		if(offset_read_+sizeof(U) > data_len_) return U();	// 不能读越界 
		return *((U*)(data_+bak));
	}
	
	template<typename U>
	bool set(U u){
		if(offset_write_+sizeof(U) > data_len_) return false;
		
		memcpy(data_+offset_write_,&u,sizeof(U));
		offset_write_ += sizeof(U);
		return true;
	}
	
	/*
	template<typename U>
	bool set(U &u){
		if(offset_write_+sizeof(U) > data_len_) return false;
		
		memcpy(data_+offset_write_,&u,sizeof(U));
		offset_write_ += sizeof(U);
		return true;
	}
	*/
	
	bool setStr(std::string ss){
		s16 sslen = ss.size();
		if(offset_write_+sizeof(s16)+sslen > data_len_) return false;
		
		set(sslen);
		memcpy(data_+offset_write_,ss.c_str(),sslen);
		
		offset_write_ += sslen;
		
		return true;
	}
	
	bool push_bin(const char* buf,int buf_len){
		if(NULL==buf || buf_len<=0) return false;
		if(offset_write_ + buf_len > data_len_) return false;
		
		memcpy(data_+offset_write_,buf,buf_len);
		offset_write_ += buf_len;
		return true;
	}
	
	int copy_to(AStream *a){
		if(NULL == a) return -1;
		
		int to_copy = data_len_ - offset_read_;
		a->push_bin(data_+offset_read_,to_copy);
		
		return to_copy;
	}
	
	char* getbuf(){
		return data_;
	}
	
	s32 getwritebuflen(){
		return offset_write_;
	}
	
	s32 getreadbuflen(){
		return data_len_;
	}
	
	
private:
	char *data_;
	s32 data_len_;
	s32 offset_read_;
	s32 offset_write_;
	s32 offset_write_protect_;
};



#endif

