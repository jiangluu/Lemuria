
function onEvent(me)
	
	local type1,amount = getUEParams()
	
	if amount<=0 then
		error('invalid param')
	end
	
	local key = 'meat'
	if 1==type1 then
		key = 'elixir'
	end
	
	local aa = math.min(me.basic[key],amount)
	
	util.dec(me,key,aa,'cost_noop')
	
	util.fillCacheData(me)
	
	return 0		
end
