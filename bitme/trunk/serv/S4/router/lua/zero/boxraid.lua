
local o = {}

boxraid = o

local lcf = ffi.C


local ls = require('luastate')

local function L_gc(L)
	print('!!!!!!!!!!!!!!!!!!!!!!!! L gc!  we DO NOT want it')
	ffi.gc(L, nil)
	ls.C.lua_close(L)
end

local function __gc_notify(ud)
	print('!!!!!!!!!!!  UD gc!  we DO NOT want it')
end

o.keep_ref = {}

local function init()
	-- init data vm here(if there is)
	
	
	-- BOX here
	o.box_num = config.get_box_num()
	o.actor_per_box = config.get_actor_per_box()
	o.trans_per_box = o.actor_per_box*2			-- should be enough
	
	o.a_box = ffi.new('Box[?]',o.box_num+1)
	assert(o.a_box)
	
	for i=1,o.box_num+1 do
		local lbox = o.a_box[i-1]
		lbox.box_id = i-1
		lbox.actor_per_box = o.actor_per_box
		lbox.trans_per_box = o.trans_per_box
		local c_vm = lcf.c_lua_new_vm()
		assert(nil ~= c_vm)
		table.insert(o.keep_ref,c_vm)
		lbox.L = c_vm
		ffi.gc(c_vm,L_gc)
		
		local c_transdata = ffi.new('TransData[?]',o.trans_per_box)
		assert(nil ~= c_transdata)
		table.insert(o.keep_ref,c_transdata)
		lbox.transdata = c_transdata
		ffi.gc(c_transdata, __gc_notify)
		
		for j=1,o.trans_per_box do
			lbox.transdata[j-1].box_id = i-1
			lbox.transdata[j-1].trans_id = j
		end
		
		-- ===============================
		ls.pushnumber(lbox.L, 3)
		ls.setglobal(lbox.L,'g_tag',-1)
		
		ls.pushstring(lbox.L, g_node_id)
		ls.setglobal(lbox.L,'g_node_id',-1)
		
		ls.pushstring(lbox.L, g_node_id)
		ls.setglobal(lbox.L,'g_app_id',-1)		-- g_node_id的别名
		
		ls.pushnumber(lbox.L, i)
		ls.setglobal(lbox.L,'g_box_id',-1)
		
		ls.pushnumber(lbox.L, o.actor_per_box)
		ls.setglobal(lbox.L,'g_actor_suggest_num',-1)
		
		print(string.format('box [%d] init ...',i))
		ls.loadfile(lbox.L,g_lua_dir..'init.lua')
		local ok,err = ls.pcall(lbox.L)
		if not ok then
			print(err)
		end
		
		box.extra_init(lbox)
		-- ===============================
	end
	
	-- the last one box is preserved by sys
	o.ad = o.a_box + o.box_num
	
	print('zero inited')
	
end

function o.getboxc(id)
	if id<1 or id>o.box_num+1 then
		return nil
	end
	
	return o.a_box + tonumber(id) - 1
end

init()
