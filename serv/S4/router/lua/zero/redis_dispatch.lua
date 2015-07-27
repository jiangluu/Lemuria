
local ls = require('luastate')

local yield_value = ls.C.LUA_YIELD


local function __foo(privdata, reply)
	local td = ffi.cast('TransData*',privdata)
	assert(1==td.is_active)
	assert(td.box_id <= boxraid.box_num)
	
	ls.pushlightuserdata(td.co, td)
	ls.setglobal(td.co, '__g_cur_context')
	
	ls.pushlightuserdata(td.co, reply)
	local r = ls.C.lua_resume(td.co, 1)
	if yield_value~=r then
		local boxcdata = boxraid.getboxc(td.box_id+1)
		ls.pushnil(boxcdata.L)
		ls.rawseti(boxcdata.L, boxcdata.stack_at_box_co, td.trans_id)
		
		box.release_transdata(boxcdata,td)
		print('release_transdata', td.trans_id)
	end
	
end


function OnRedisReply(privdata, reply)
	jlpcall(__foo,privdata, reply)
	return 0
end
