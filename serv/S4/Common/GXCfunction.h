#ifndef __GX_C_FUNCTION_H
#define __GX_C_FUNCTION_H


// ����ļ��ı�Ҫ�����ڣ��Դ�C��������ʽ����һЩ���ܣ�����luaJIT����ʹ�� 


#include "types.h"


#ifdef WIN32
#define CF_EXPORT  __declspec(dllexport)
#else
#define CF_EXPORT
#endif


// Ϊ����Lua�ܹ�ʹ�ö�д��C����
extern "C"{
	
struct Slice{
	uint16_t len_;
	const char *mem_;
};

CF_EXPORT void gx_set_context(struct GXContext*);

CF_EXPORT struct GXContext* gx_get_context();
	
CF_EXPORT void* gx_env_get_shared_ptr(int index);

CF_EXPORT bool gx_env_set_shared_ptr(int index,void *p);

CF_EXPORT void gx_cur_stream_cleanup();

CF_EXPORT bool gx_cur_stream_is_end();

CF_EXPORT int gx_cur_stream_get_readbuf_len();

CF_EXPORT s16 gx_cur_stream_get_int8();

CF_EXPORT s16 gx_cur_stream_get_int16();

CF_EXPORT s32 gx_cur_stream_get_int32();

CF_EXPORT s64 gx_cur_stream_get_int64();

CF_EXPORT f32 gx_cur_stream_get_float32();

CF_EXPORT f64 gx_cur_stream_get_float64();

CF_EXPORT struct Slice gx_cur_stream_get_slice();

CF_EXPORT s16 gx_cur_stream_peek_int16();

CF_EXPORT bool gx_cur_stream_push_int16(s16 v);

CF_EXPORT bool gx_cur_stream_push_int32(s32 v);

CF_EXPORT bool gx_cur_stream_push_int64(s64 v);

CF_EXPORT bool gx_cur_stream_push_float32(f32 v);

CF_EXPORT bool gx_cur_stream_push_slice(struct Slice s);

CF_EXPORT bool gx_cur_stream_push_slice2(const char* v,int len);

CF_EXPORT bool gx_cur_stream_push_bin(const char* v,int len);

CF_EXPORT const char* gx_cur_stream_get_bin(int len);	// ��ȡbin�飨����֪��len�� 


CF_EXPORT void gx_cur_writestream_cleanup();

CF_EXPORT void gx_cur_writestream_protect(int n);	// ��������buf��ǰn���ֽڲ������ 

// ͬ��ԭ·���ء�messageid ��req��+1��������push�� stream������ݡ� 
CF_EXPORT int gx_cur_writestream_syncback();

CF_EXPORT int gx_cur_writestream_syncback2(int message_id);

CF_EXPORT int gx_cur_writestream_send_to(int portal_index,int message_id);

CF_EXPORT s32 gx_get_portal_pool_index();

CF_EXPORT int gx_get_message_id();

CF_EXPORT int gx_make_portal_sync(const char* ID,const char* port);

CF_EXPORT int gx_bind_portal_id(int index,const char* id);

CF_EXPORT int gx_cur_writestream_route_to(const char* destID,int message_id, int flag);

CF_EXPORT int gx_get_input_context_size();

CF_EXPORT void* gx_get_input_context();

}


#endif

