
local lcf = ffi.C

function onMsg()
	print('ack 8018')
	
	ui.on_ack('ack 8018')
	
	return 0
end
