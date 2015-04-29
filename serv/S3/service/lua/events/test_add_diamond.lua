
function onEvent(me)

	local meat,elixir,diamond = getUEParams()
	
	if nil==meat or nil==elixir or nil==diamond then
		error('is nil')
	end
	
	me.basic.diamond = diamond
	
	me.basic.meat = meat
	me.basic.elixir = elixir
	
	
	util.travalPlayerMap(me,function(m)
		if nil~=m.meat_w then
			m.meat_w = m.carrage
		elseif nil~=m.elixir_w then
			m.elixir_w = m.carrage
		end
	end)
	
	util.fillCacheData(me)
	
	
	return 0
end
