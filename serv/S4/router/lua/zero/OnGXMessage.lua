
local lcf = ffi.C
local ls = require('luastate')

local yield_value = ls.C.LUA_YIELD

local function remote_transaction_start(dest_boxc,func_name,mid)
		ls.pushnil(dest_boxc.L)
		ls.setglobal(dest_boxc.L, '__g_cur_context')
		
		local co = ls.newthread(dest_boxc.L)		-- @TODO: coroutine pool
		ls.getglobal(co,func_name)
		ls.pushnumber(co,mid)
		local r = ls.C.lua_resume(co,1)
		
		if yield_value==r then		-- yield
			local td = box.new_transdata(dest_boxc)
			if nil==td then
				error('transdata pool was full')
			end
			
			print('yield  trans_id:',td.trans_id,td.serial_no)
			td.co = co
			
			-- save co to box_co, prevent GC
			ls.rawseti(dest_boxc.L, dest_boxc.stack_at_box_co, td.trans_id)
			
			ls.pushlightuserdata(co,td)
			return ls.C.lua_resume(co,1)
			
		elseif 0==r then				-- successful ends
			ls.pop(dest_boxc.L,1)
			return 0
		else									-- there is error
			print(ls.get(co,-1))
			ls.pop(dest_boxc.L,2)
			return r
		end
end

function OnGXMessage()
	local msg_id = lcf.gx_get_message_id()
	
	if msg_id>=8000 and msg_id<8100 then
		-- internal msg
		local r = jlpcall(remote_transaction_start,boxraid.ad,'on_message_1',msg_id)
		print('remote_transaction_start',r)
	else
		-- custom msg
	end
	
	return 0
end
