
local lcf = ffi.C

function onMsg()
	local node_id = l_gx_cur_stream_get_slice()
	local port = l_gx_cur_stream_get_slice()
	local stat = lcf.gx_cur_stream_get_int16()
	
	print('8013',node_id,port,stat)
	
	--l_gx_simple_ack()
	
	
	return 0
end
