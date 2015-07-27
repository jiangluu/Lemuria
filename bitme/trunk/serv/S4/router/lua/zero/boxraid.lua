
local o = {}

boxraid = o

local lcf = ffi.C


local ls = require('luastate')


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
		lbox.L = lcf.c_lua_new_vm()
		lbox.transdata = ffi.new('TransData[?]',o.trans_per_box)
		assert(lbox.transdata)
		for j=1,o.trans_per_box do
			lbox.transdata[j-1].box_id = i-1
			lbox.transdata[j-1].trans_id = j
		end
		
		-- ===============================
		ls.pushnumber(lbox.L, 3)
		ls.setglobal(lbox.L,'g_tag',-1)
		
		ls.pushstring(lbox.L, g_node_id)
		ls.setglobal(lbox.L,'g_node_id',-1)
		
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
	return o.a_box + tonumber(id) - 1
end

init()
