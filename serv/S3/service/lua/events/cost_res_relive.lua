
function onEvent(me)
	
	local where = nil
	if isServ() then
		if nil==me.inbattle then
			me.inbattle = { score=6 , record='' }
		end
		
		where = me.inbattle
	else
		if nil==me.cache.inbattle then
			me.cache.inbattle = {}
		end
		
		where = me.cache.inbattle
	end
	
	local to_level = 1
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			to_level = m.level
			return true
		end
	end)
	
	local relive_times = where.relive_times or 0
	if relive_times>9 then
		relive_times = 9
	end
	
	local col_name = 'cost_'..(relive_times+1)
	
	local cost = sd.battle.default.relive[to_level][col_name]
	if cost then
		if not util.check(me,'diamond',cost) then
			return 1
		end
		
		util.dec(me,'diamond',cost,'relive')
		
		where.relive_times = relive_times + 1
		
		--刷新数据
		util.fillCacheData(me)
	end
	
	return 0		
end
