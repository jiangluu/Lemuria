
local lcf = ffi.C

function onMsg()
	print('ack PONG')
	
	ui.on_ack('ack PONG')
	
	return 0
end
