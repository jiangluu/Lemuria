
function onEvent(me)
	local map_index,mob_index = getUEParams()
	
	--查看是否有怪
	if nil==me.map.list[map_index].mob.list[mob_index] then
		error('invalid param')
	end
	local ta_monster = me.map.list[map_index].mob.list[mob_index]
	
	local left_time = ta_monster.next_enable_time - l_cur_game_time()
	
	local to_dec = util.getDiamondExchangeTime(left_time)
	if to_dec<=0 then
		error('time error')
	end
	
	if not util.check(me,'diamond',to_dec) then
		error('diamond not enough')
	end
	
	
	--减去钻石 设置时间
	util.dec(me,'diamond',to_dec,'wakeup')
	ta_monster.next_enable_time = l_cur_game_time()-1
	
	util.fillCacheData(me)
	
	
	return 0
end
