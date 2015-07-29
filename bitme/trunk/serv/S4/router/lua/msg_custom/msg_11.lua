
function onMsg(me)
	
	local rn = math.random(1,100)
	if rn<=5 then
		local a = redis.command_and_wait(1,'INCR counter1')
		print('msg11',a)
	end
	
	l_gx_simple_ack()
	
	return 0
end
