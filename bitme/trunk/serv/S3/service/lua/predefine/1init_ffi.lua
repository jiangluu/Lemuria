
-- open ffi
ffi = require("ffi")
ffi.cdef[[

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

void gx_cur_writestream_cleanup();

// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
int gx_cur_writestream_syncback();

int gx_cur_writestream_syncback2(int message_id);

int gx_cur_writestream_send_to(int portal_index,int message_id);

int gx_get_portal_pool_index();

int gx_get_message_id();

int gx_make_portal_sync(const char* ID,const char* port);

int gx_bind_portal_id(int index,const char* id);

int gx_cur_writestream_route_to(const char* destID,int message_id);


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

int32_t cur_actor_id();

uint64_t cur_user_sn();

uint32_t cur_game_time();

uint64_t cur_game_usec();

bool log_write(int level,const char*,int len);

bool log_write2(int index,const char*,int len);

void log_force_flush();

int string_hash(const char *str);

int cur_message_loopback();

int cur_stream_get_readbuf_len();

void MD5( const unsigned char *input, size_t ilen, unsigned char output[16] );


// Redis部分
/*
#define REDIS_REPLY_STRING 1
#define REDIS_REPLY_ARRAY 2
#define REDIS_REPLY_INTEGER 3
#define REDIS_REPLY_NIL 4
#define REDIS_REPLY_STATUS 5
#define REDIS_REPLY_ERROR 6
*/

typedef struct redisReply {
    int type; /* REDIS_REPLY_* */
    long long integer; /* The integer when type is REDIS_REPLY_INTEGER */
    int len; /* Length of string */
    char *str; /* Used for both REDIS_REPLY_ERROR and REDIS_REPLY_STRING */
    size_t elements; /* number of elements, for REDIS_REPLY_ARRAY */
    struct redisReply **element; /* elements vector for REDIS_REPLY_ARRAY */
} redisReply;

typedef struct redisAsyncContext {
	int fake_;
} redisAsyncContext;


redisAsyncContext* redis_make_an_connection(const char* ip,int port);

int redis_free_an_connection(redisAsyncContext *ac);

int box_redis_async_command(redisAsyncContext *ac,const char *format, ...);

redisReply* get_cur_redis_reply();

redisReply* get_cur_redis_push_msg();


// PBC部分
struct pbc_slice {
	void *buffer;
	int len;
};

struct pbc_env{
	int32_t __fake; 
};
struct pbc_rmessage{
	int32_t __fake; 
};
struct pbc_wmessage{
	int32_t __fake; 
};

struct pbc_env * pbc_new(void);
void pbc_delete(struct pbc_env *);
int pbc_register(struct pbc_env *, struct pbc_slice * slice);
const char * pbc_error(struct pbc_env *);

struct pbc_wmessage * pbc_wmessage_new(struct pbc_env * env, const char *type_name);
void pbc_wmessage_delete(struct pbc_wmessage *);
// jianglu add for reuse a wmessage. 注意只能复用同一个proto的消息 
void pbc_wmessage_reset(struct pbc_wmessage *m);

// for negative integer, pass -1 to hi
int pbc_wmessage_integer(struct pbc_wmessage *, const char *key, uint32_t low, uint32_t hi);
int pbc_wmessage_real(struct pbc_wmessage *, const char *key, double v);
int pbc_wmessage_string(struct pbc_wmessage *, const char *key, const char * v, int len);
struct pbc_wmessage * pbc_wmessage_message(struct pbc_wmessage *, const char *key);
void * pbc_wmessage_buffer(struct pbc_wmessage *, struct pbc_slice * slice);



void box_actor_num_dec(int a);

void box_cur_actor_set_flag(int index,bool v);

bool boxover_set_shared_ptr(int index,void *p);

void* boxover_get_shared_ptr(int index);

void* c_env_get_shared_ptr(int index);

bool c_env_set_shared_ptr(int index,void *p);

]]


local lcf = ffi.C

-- 定义一个方便lua里直接用的函数
function l_cur_stream_get_slice()
	local slice = lcf.cur_stream_get_slice()
	if slice.len_ <= 0 then
		return nil
	else
		return ffi.string(slice.mem_,slice.len_)
	end
end

