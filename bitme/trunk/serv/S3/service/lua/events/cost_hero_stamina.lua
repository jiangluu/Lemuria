function onEvent(me)
	local num = getUEParams()
	
	util.travalHero(me,function(h)
		if h.inuse then
			h.last_battle_time = l_cur_game_time()
			
			h.stamina = math.max(h.stamina - num,0)
			return true
		end
	end)
	
	return 0		
end
