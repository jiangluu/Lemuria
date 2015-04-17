
local lcf = ffi.C

function onMsg(me)
	local aa = lcf.gx_cur_stream_get_int16()
	
	print('get 2221',aa)
	
	lcf.gx_cur_stream_push_int16(999)
	
	l_gx_simple_ack()
	
	return 0
end
