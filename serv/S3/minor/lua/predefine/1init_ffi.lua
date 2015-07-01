
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

bool gx_cur_stream_push_bin(const char* v,int len);

const char* gx_cur_stream_get_bin(int len);

void gx_cur_writestream_cleanup();

// 同步原路返回。messageid 是req的+1，内容是push到 stream里的内容。 
int gx_cur_writestream_syncback();

int gx_cur_writestream_syncback2(int message_id);

int gx_cur_writestream_send_to(int portal_index,int message_id);

int gx_get_portal_pool_index();

int gx_get_message_id();

int gx_make_portal_sync(const char* ID,const char* port);

int gx_bind_portal_id(int index,const char* id);




// redis

typedef struct redisReply {
    int type; /* REDIS_REPLY_* */
    long long integer; /* The integer when type is REDIS_REPLY_INTEGER */
    int len; /* Length of string */
    char *str; /* Used for both REDIS_REPLY_ERROR and REDIS_REPLY_STRING */
    size_t elements; /* number of elements, for REDIS_REPLY_ARRAY */
    struct redisReply **element; /* elements vector for REDIS_REPLY_ARRAY */
} redisReply;

typedef struct redisReader {
    int err; /* Error flags, 0 when there is no error */
} redisReader;

typedef struct redisContext {
    int err; /* Error flags, 0 when there is no error */
    char errstr[128]; /* String representation of error when applicable */
    int fd;
    int flags;
    char *obuf; /* Write buffer */
    redisReader *reader; /* Protocol reader */
} redisContext;


redisContext *redisConnect(const char *ip, int port);
redisContext *redisConnectNonBlock(const char *ip, int port);
void redisFree(redisContext *c);
void* redisConnectWithTimeout2(const char *ip, int port, int ms);

redisReply *redisCommand(redisContext *c, const char *format, ...);
int redisAppendCommand(redisContext *c, const char *format, ...);

void* redisGetReply2(void *c);

void freeReplyObject(void *reply);

]]



ffi.cdef[[
typedef struct st_mysql
{
  uint32_t fake_;
} MYSQL;



MYSQL *		 mysql_init(MYSQL *mysql);

MYSQL *		 mysql_real_connect(MYSQL *mysql, const char *host,
					   const char *user,
					   const char *passwd,
					   const char *db,
					   unsigned int port,
					   const char *unix_socket,
					   unsigned long clientflag);

int mysql_set_character_set(MYSQL *mysql, const char *csname);


int		 mysql_real_query(MYSQL *mysql, const char *q,unsigned long length);

uint32_t  mysql_field_count(MYSQL *mysql);
uint64_t  mysql_affected_rows(MYSQL *mysql);

unsigned int  mysql_errno(MYSQL *mysql);
const char *  mysql_error(MYSQL *mysql);

uint64_t  mysql_insert_id(MYSQL *mysql);

uint32_t mysql_real_escape_string(MYSQL *mysql,char *to,const char *from,uint32_t length);

int		mysql_ping(MYSQL *mysql);



// CURL部分

typedef struct{
	int __fake;
} CURL;

int curl_global_init(int);
CURL *curl_easy_init(void);
int curl_easy_setopt(CURL *curl, int option, ...);
int curl_easy_perform(CURL *curl);
void curl_easy_cleanup(CURL *curl);
void curl_easy_reset(CURL *curl);
typedef size_t (*CURL_WRITE_CB)(void *ptr, size_t size, size_t nmemb, void *stream);


]]
