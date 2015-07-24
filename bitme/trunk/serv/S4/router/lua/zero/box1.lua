
local o = {}

box = o

local lcf = ffi.C


local ls = require('luastate')

ffi.cdef[[
typedef struct TransData{
	// @TODO
	uint16_t is_active;
	uint16_t padding;
	uint32_t trans_id;
	uint32_t actor_id;
	uint32_t serial_no;
} TransData;

typedef struct Box{
	uint32_t box_id;
	uint32_t actor_per_box;
	struct lua_State *L;
	TransData *transdata;
} Box;
]]

