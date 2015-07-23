
local lcf = ffi.C
local ls = require('luastate')


function OnGXMessage()
	local msg_id = lcf.gx_get_message_id()
	print('OnGXMessage',msg_id)
	
	if msg_id>=8000 and msg_id<8100 then
		-- internal msg
		ls.getglobal(boxraid.ad.L,'on_message_1')
		local ok,err = ls.pcall(boxraid.ad.L,msg_id)
		if not ok then
			print(err)
		end
		
	else
		-- custom msg
	end
	
	return 0
end
