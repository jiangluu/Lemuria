
local lcf = ffi.C

function onMsg()
	
	print('get 8019')
	
	coroutine.yield()
	
	print('resumed')
	
	l_gx_simple_ack()
	
	return 0
end
