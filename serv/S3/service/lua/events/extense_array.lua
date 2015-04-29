function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	if nil == me.var.jin[key] then
		return 1
	end
	
	util.use_update_array(me)
		--取充能一次所需时间以及充能次数上限
	local ai = 0	--智能管家可以增加上限
	local onceTime = sd.jin[key]['charge_time']
	local limit = sd.jin[key]['count'] + ai
	
		--判断是否达到上限以及钻石是否够用
	if me.var.jin[key].count >= limit then
		return 1
	end
	
	local leftTime = onceTime - (l_cur_game_time() - me.var.jin[key].starttime)
	local needNum = util.getDiamondExchangeTime(leftTime)
	
	if needNum < 0 then
		error('time error')
	end
	
	if needNum > me.basic.diamond then
		return 1
	end
	
		--条件都满足，扣钻石、加层数、重置时间
	util.dec(me,'diamond',needNum,'jin')
	me.var.jin[key].count = me.var.jin[key].count + 1
	me.var.jin[key].starttime = l_cur_game_time()
	
		--刷新数据
	util.fillCacheData(me)
	
	return 0
	
end