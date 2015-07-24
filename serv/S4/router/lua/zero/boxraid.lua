
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
		local box = o.a_box[i-1]
		box.box_id = i-1
		box.actor_per_box = o.actor_per_box
		box.trans_per_box = o.trans_per_box
		box.L = lcf.c_lua_new_vm()
		box.transdata = ffi.new('TransData[?]',o.trans_per_box)
		assert(box.transdata)
		for j=1,o.trans_per_box do
			box.transdata[j-1].trans_id = j
		end
		
		-- ===============================
		ls.pushnumber(box.L, 3)
		ls.setglobal(box.L,'g_tag',-1)
		
		ls.pushstring(box.L, g_node_id)
		ls.setglobal(box.L,'g_node_id',-1)
		
		ls.pushnumber(box.L, i)
		ls.setglobal(box.L,'g_box_id',-1)
		
		ls.pushnumber(box.L, o.actor_per_box)
		ls.setglobal(box.L,'g_actor_suggest_num',-1)
		
		print(string.format('box [%d] init ...',i))
		ls.loadfile(box.L,g_lua_dir..'init.lua')
		local ok,err = ls.pcall(box.L)
		if not ok then
			print(err)
		end
		-- ===============================
	end
	
	-- the last one box is preserved by sys
	o.ad = o.a_box[o.box_num]
	
	print('zero inited')
end

function o.getboxc(id)
	return o.a_box[tonumber(id)-1]
end

init()
