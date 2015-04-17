
local lcf = ffi.C

function onMsg(me)
	local aa = lcf.gx_cur_stream_get_int16()
	
	print('ack 2222',aa)
	
	return 0
end
