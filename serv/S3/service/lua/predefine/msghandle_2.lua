
local lcf = ffi.C

function OnCustomMessage()
	local msg_id = lcf.gx_get_message_id()
	local err,ret = pcall(box.on_message,msg_id)
	if false==err then
		print(ret)
		return 1
	else
		return ret
	end
	
	return -1
end


function regMsgHandlers2()
	local the_dir = g_lua_dir..'msg_custom/'
	for file in lfs.dir(the_dir) do
		local msg_id = string.match(file,'msg_(%d+)%.lua')
		if msg_id then
			onMsg = nil
			jlpcall(dofile,the_dir..file)
			if nil~=onMsg then
				box.reg_handle(msg_id,onMsg)
			end
			onMsg = nil
		end
	end
end

regMsgHandlers2()
