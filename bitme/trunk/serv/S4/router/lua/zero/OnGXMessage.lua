
local lcf = ffi.C
local ls = require('luastate')

local yield_value = ls.C.LUA_YIELD

local function remote_transaction_start(dest_boxc,func_name,mid)
		local co = ls.newthread(dest_boxc.L)
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
			
			return yield_value
		elseif 0==r then				-- successful ends
			return 0
		else									-- there is error
			print(ls.get(co,-1))
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
