
function onMsg()
	
	print('get 8019')
	
	local a = redis.command_and_wait(1,'INCR counter1')
	
	print('resumed')
	print('AAA',a)
	
	a = redis.command_and_wait(1,'INCR counter1')
	print('BBB',a)
	
	l_gx_simple_ack()
	
	return 0
end
