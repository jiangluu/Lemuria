
local lcf = ffi.C

function onMsg()
	print('recv PING')
	
	ui.on_ack('recv PING')
	
	l_gx_simple_ack()
	
	return 0
end
