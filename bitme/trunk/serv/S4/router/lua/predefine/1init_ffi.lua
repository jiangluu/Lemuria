
-- open ffi
ffi = require("ffi")
ffi.cdef[[

// luaState functions
typedef struct lua_State lua_State;
int c_luaopen_lfs(lua_State *L);

int c_luaopen_bson(lua_State *L);

int c_luaopen_atablepointer(lua_State *L);

int c_lua_ex_function(lua_State *L);

lua_State* c_lua_new_vm();


// libz functions
unsigned long compressBound(unsigned long sourceLen);
int compress2(uint8_t *dest, unsigned long *destLen,
	      const uint8_t *source, unsigned long sourceLen, int level);
int uncompress(uint8_t *dest, unsigned long *destLen,
	       const uint8_t *source, unsigned long sourceLen);
// END


// GX functions

struct Slice{
	uint16_t len_;
	const char *mem_;
};
	
void* gx_env_get_shared_ptr(int index);

bool gx_env_set_shared_ptr(int index,void *p);

void gx_cur_stream_cleanup();

bool gx_cur_stream_is_end();

int16_t gx_cur_stream_get_int8();

int16_t gx_cur_stream_get_int16();

int gx_cur_stream_get_int32();

int64_t gx_cur_stream_get_int64();

float gx_cur_stream_get_float32();

double gx_cur_stream_get_float64();

struct Slice gx_cur_stream_get_slice();

int16_t gx_cur_stream_peek_int16();

bool gx_cur_stream_push_int16(int16_t v);

bool gx_cur_stream_push_int32(int v);

bool gx_cur_stream_push_int64(int64_t v);

bool gx_cur_stream_push_float32(float v);

bool gx_cur_stream_push_slice(struct Slice s);

bool gx_cur_stream_push_slice2(const char* v,int len);

bool gx_cur_stream_push_bin(const char* v,int len);

const char* gx_cur_stream_get_bin(int len);

void gx_cur_writestream_cleanup();

void gx_cur_writestream_protect(int);

// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
int gx_cur_writestream_syncback();

int gx_cur_writestream_syncback2(int message_id);

int gx_cur_writestream_send_to(int portal_index,int message_id);

int gx_get_portal_pool_index();

int gx_get_message_id();

int gx_make_portal_sync(const char* ID,const char* port);

int gx_bind_portal_id(int index,const char* id);

int gx_get_input_context_size();

void* gx_get_input_context();

// GX END


struct Slice cur_stream_get_slice();

bool cur_stream_is_end();

int16_t cur_stream_get_int8();

int16_t cur_stream_get_int16();

int32_t cur_stream_get_int32();

int64_t cur_stream_get_int64();

float cur_stream_get_float32();

double cur_stream_get_float64();

int16_t cur_stream_peek_int16();

bool cur_stream_push_int16(int16_t v);

bool cur_stream_push_int32(int32_t v);

bool cur_stream_push_int64(int64_t v);

bool cur_stream_push_float32(float v);

bool cur_stream_push_slice(struct Slice s);

bool cur_stream_push_string(const char* v,int len);


void cur_write_stream_cleanup();

// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
void cur_stream_write_back();

void cur_stream_write_back2(int message_id);

void cur_stream_broadcast(int message_id);

uint32_t cur_game_time();

uint64_t cur_game_usec();

bool log_write(int level,const char*,int len);

bool log_write2(int index,const char*,int len);

void log_force_flush();

int string_hash(const char *str);

int cur_message_loopback();

int cur_stream_get_readbuf_len();

const char* cur_stream_get_bin(int len);	// 获取bin块（事先知道len） 


]]
