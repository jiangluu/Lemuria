
local lcf = ffi.C

function onMsg()
	print('recv 1102')
	
	local a = l_gx_cur_stream_get_slice()
	
	ui.on_ack(a)
	
	return 0
end
