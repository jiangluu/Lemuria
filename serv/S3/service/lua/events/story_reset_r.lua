
function onEvent(me)
	local index = getUEParams()
	
	if nil==index then
		error('invalid param')
	end
	
	local key = index
	local conf = sd.dungeon[key]
	if nil==conf then
		error('invalid param')
	end
	
	if nil==me.var.stat_daily.story_r[index] then
		error('invalid param')
	end
	
	if nil==me.var.stat_daily.story_r_times then
		me.var.stat_daily.story_r_times = {}
	end
	local old = me.var.stat_daily.story_r_times[key] or 0
	if old >= table.getn(conf.refresh) then
		error('too much reset')
	end
	
	local cost = conf.refresh[old+1].cost_count
	if not util.check(me,'diamond',cost) then
		return 1
	end
	util.dec(me,'diamond',cost,'story_reset_r')
	
	-- cleanup it
	me.var.stat_daily.story_r[index] = nil
	
	me.var.stat_daily.story_r_times[key] = old + 1
	

	util.fillCacheData(me)
	
	return 0		
end
