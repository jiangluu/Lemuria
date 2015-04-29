
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
	
	local fury_times = where.fury_times or 0
	if fury_times>9 then
		fury_times = 9
	end
	
	local col_name = 'cost_'..(fury_times+1)
	
	local cost = sd.battle.default.fury[to_level][col_name]
	if cost then
		if not util.check(me,'diamond',cost) then
			return 1
		end
		
		util.dec(me,'diamond',cost,'fury')
		
		where.fury_times = fury_times + 1
		
		--刷新数据
		util.fillCacheData(me)
	end
	
	return 0		
end
