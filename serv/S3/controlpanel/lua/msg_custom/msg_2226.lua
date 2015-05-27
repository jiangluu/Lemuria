
local lcf = ffi.C

function onMsg()
	print('ack 2226')
	
	ui.on_ack('ack 2226')
	
	return 0
end
