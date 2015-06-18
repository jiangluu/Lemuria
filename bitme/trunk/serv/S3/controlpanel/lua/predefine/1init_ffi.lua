
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

union pbc_value {
	struct {
		uint32_t low;
		uint32_t hi;
	} i;
	double f;
	struct pbc_slice s;
	struct {
		int id;
		const char * name;
	} e;
};

typedef void (*pbc_decoder)(void *ud, int type, const char * type_name, union pbc_value *v, int id, const char *key);
int pbc_decode(struct pbc_env * env, const char * type_name , struct pbc_slice * slice, pbc_decoder f, void *ud);

]]
