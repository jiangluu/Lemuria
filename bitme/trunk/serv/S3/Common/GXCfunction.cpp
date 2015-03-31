#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "polarssl/md5.h"
#include "link.h"
#include "GXContext.h"
#include "GXCfunction.h"



#define MAX_A_STR_LEN (1024*128)
static char s_buf1[MAX_A_STR_LEN];


#define C_ENV_SHARED_PTR_LEN 512


static GXContext *s_gx = 0;


void** __make_sure_gx_env_get_shared_ptr_exists()
{
	static void** aa = NULL;
	if(NULL == aa){
		int len = sizeof(void*) * C_ENV_SHARED_PTR_LEN;
		aa = (void**)malloc(len);
		memset(aa,0,len);
	}
	return aa;
}

void* gx_env_get_shared_ptr(int index)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return NULL;
	
	void** p = __make_sure_gx_env_get_shared_ptr_exists();
	if(NULL == p) return NULL;
	
	return p[index];
}

bool gx_env_set_shared_ptr(int index,void *new_value)
{
	if(index<0 || index>=C_ENV_SHARED_PTR_LEN) return false;
	
	void** p = __make_sure_gx_env_get_shared_ptr_exists();
	if(NULL == p) return false;
	
	p[index] = new_value;
	return true;
}

void gx_set_context(struct GXContext *aa)
{
	s_gx = aa;
}


bool gx_cur_stream_is_end()
{
	if(s_gx) return s_gx->input_context_.rs_->is_end();
	return true;
}

s16 gx_cur_stream_get_int8()
{
	if(s_gx) return (s16)s_gx->input_context_.rs_->get<char>();
	return 0;
}

s16 gx_cur_stream_get_int16()
{
	if(s_gx) return s_gx->input_context_.rs_->get<s16>();
	return 0;
}

s32 gx_cur_stream_get_int32()
{
	if(s_gx) return s_gx->input_context_.rs_->get<s32>();
	return 0;
}

s64 gx_cur_stream_get_int64()
{
	if(s_gx) return s_gx->input_context_.rs_->get<s64>();
	return 0;
}

f32 gx_cur_stream_get_float32()
{
	if(s_gx) return s_gx->input_context_.rs_->get<f32>();
	return 0.0f;
}

f64 gx_cur_stream_get_float64()
{
	if(s_gx) return s_gx->input_context_.rs_->get<f64>();
	return 0.0f;
}

struct Slice gx_cur_stream_get_slice()
{
	struct Slice aa;
	aa.len_ = 0;
	aa.mem_ = NULL;
	
	if(s_gx){
		s16 len = s_gx->input_context_.rs_->get<s16>();
		if(len>0 && len<(MAX_A_STR_LEN-40)){
			const char *cc = s_gx->input_context_.rs_->get_bin(len);
			if(cc){
				memcpy(s_buf1+32,cc,len);
				s_buf1[len+32] = 0;
				
				aa.len_ = len;
				aa.mem_ = s_buf1+32;
			}
		}
	}
	return aa;
}

s16 gx_cur_stream_peek_int16()
{
	if(s_gx) return s_gx->input_context_.rs_->peek<s16>();
	return 0;
}

bool gx_cur_stream_push_int16(s16 v)
{
	if(s_gx) return s_gx->input_context_.ws_->set<s16>(v);
	return false;
}

bool gx_cur_stream_push_int32(s32 v)
{
	if(s_gx) return s_gx->input_context_.ws_->set<s32>(v);
	return false;
}

bool gx_cur_stream_push_int64(s64 v)
{
	if(s_gx) return s_gx->input_context_.ws_->set<s64>(v);
	return false;
}

bool gx_cur_stream_push_float32(f32 v)
{
	if(s_gx) return s_gx->input_context_.ws_->set<f32>(v);
	return false;
}

bool gx_cur_stream_push_slice(struct Slice s)
{
	
	return gx_cur_stream_push_slice2(s.mem_,s.len_);
}

bool gx_cur_stream_push_slice2(const char* v,int len)
{
	if(s_gx && v){
		int real_len = 0;
		if(len > 0){
			real_len = len;
		}
		else{
			real_len = strlen(v);
		}
		
		s_gx->input_context_.ws_->set<s16>((s16)real_len);
		return s_gx->input_context_.ws_->push_bin(v,real_len);
	}
	
	return false;
}

void gx_cur_writestream_cleanup()
{
	if(s_gx) s_gx->input_context_.ws_->cleanup();
}


// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
int gx_cur_writestream_syncback()
{
	if(s_gx){
		AStream *aa = s_gx->input_context_.ws_;
		if(0 == s_gx->input_context_.header_type_){
			return s_gx->syncWriteBack(s_gx->input_context_.header_.message_id_+1,aa->getwritebuflen(),aa->getbuf());
		}
		else{
			return s_gx->syncWriteBack(s_gx->input_context_.header2_.message_id_+1,aa->getwritebuflen(),aa->getbuf());
		}
	}
	
	return -1;
}

int gx_cur_writestream_syncback2(int message_id)
{
	if(s_gx){
		AStream *aa = s_gx->input_context_.ws_;
		return s_gx->syncWriteBack(message_id,aa->getwritebuflen(),aa->getbuf());
	}
	
	return -1;
}

int gx_cur_writestream_send_to(int portal_index,int message_id)
{
	if(s_gx){
		AStream *aa = s_gx->input_context_.ws_;
		Link* ll = s_gx->getLink(portal_index);
		if(ll){
			return s_gx->sendToPortal(portal_index,ll->link_id_,aa->getwritebuflen(),aa->getbuf());
		}
	}
	
	return -1;
}

s32 gx_get_portal_pool_index()
{
	if(s_gx){
		return s_gx->input_context_.src_link_pool_index_;
	}
	
	return -1;
}



