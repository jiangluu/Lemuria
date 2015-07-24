
local o = {}

box = o

local lcf = ffi.C


local ls = require('luastate')

ffi.cdef[[
typedef struct TransData{
	// @TODO
	uint32_t padding;
	uint16_t padding2;
	uint16_t is_active;
	uint32_t trans_id;
	uint32_t serial_no;
	lua_State *co;
} TransData;

typedef struct Box{
	uint32_t padding;
	uint32_t box_id;
	uint32_t actor_per_box;
	uint32_t trans_per_box;
	lua_State *L;
	TransData *transdata;
	uint32_t next_offset_transdata;
	uint32_t next_serial_no;
	uint32_t stack_at_box_co;
	uint32_t stack_at_box_actors;
} Box;
]]


function o.get_transdata(boxc,id)
	return boxc.transdata + id - 1
end

function o.new_transdata(boxc)
	for i=1, boxc.trans_per_box do
		local aa = boxc.transdata+boxc.next_offset_transdata
		boxc.next_offset_transdata = (boxc.next_offset_transdata+1) % boxc.trans_per_box
		
		if 0==aa.is_active then
			o.reset_transdata(aa)
			aa.is_active = 1
			aa.serial_no = boxc.next_serial_no
			
			boxc.next_serial_no = boxc.next_serial_no+1
			
			return aa
		end
	end
	
	return nil
end

function o.release_transdata(boxc,td)
	assert(td>=boxc.transdata and td<boxc.transdata+boxc.trans_per_box)
	td.is_active = 0
end

function o.reset_transdata(td)
	local bak = td.trans_id
	
	ffi.fill(td,ffi.sizeof('TransData'))
	td.trans_id = bak
end

function o.extra_init(boxc)
	ls.newtable(boxc.L)
	boxc.stack_at_box_co = ls.gettop(boxc.L)
	
	ls.newtable(boxc.L)
	boxc.stack_at_box_actors = ls.gettop(boxc.L)
end

