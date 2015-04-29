function onEvent(me)
	local apply_time=nil
	if nil==me.basic.guild then 
		error('have no guild')
	end
	
	apply_time=me.basic.guild.next_apply_time
	if nil==apply_time then
		error('apply_time error')
	end

	if apply_time<l_cur_game_time() then 
		error('apply_time error')
	end
	
	local need_dia= util.getDiamondExchangeTime(apply_time-l_cur_game_time())
	if nil==need_dia then 
		return 1
	end
	
	if not util.check(me,'diamond',need_dia) then
		return 1
	end
	
	--减去钻石
	util.dec(me,'diamond',need_dia,'guild_apply_time')
	--设置时间
	me.basic.guild.next_apply_time=l_cur_game_time()-1
	--刷新数据
	
	util.fillCacheData(me)
	
	return 0
end