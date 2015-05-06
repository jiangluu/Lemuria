
local lcf = ffi.C

function onMsg()
	local op = l_gx_cur_stream_get_slice()
	
	l_gx_simple_ack()
	
	
	return 0
end
