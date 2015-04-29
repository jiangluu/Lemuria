
function onEvent(me)
	
	--减去钻石 设置时间
	me.addition.daily.accept_time = me.addition.daily.accept_time - 3600*24	-- 减24小时，肯定过期
	
	
	return 0
end


