
local lcf = ffi.C

function onMsg()
	local op = l_gx_cur_stream_get_slice()
	
	l_gx_simple_ack()
	
	if 'handle'==op then
		regMsgHandlers()
		regMsgHandlers2()
		regAllEvents()
	elseif 'data'==op then
		g_reload_sd()
	elseif 'all'==op then
		jlpcall(dofile,g_lua_dir.."predefine/init.lua")
	else
		print('msg8017  not supported op')
	end
	
	
	return -10051
end
