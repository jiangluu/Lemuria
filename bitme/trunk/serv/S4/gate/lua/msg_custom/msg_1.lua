
local lcf = ffi.C

function onMsg(me)
	local login_type = lcf.gx_cur_stream_get_int16()
	local login_key = l_gx_cur_stream_get_slice()
	
	
	-- TODO: 
	
	
	l_gx_simple_ack()
	
	return 0
end
