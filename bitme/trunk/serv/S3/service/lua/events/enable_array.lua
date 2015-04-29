function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	util.use_update_array(me)
	if nil == me.var.jin[key] then
		me.var.jin[key] = {}
		me.var.jin[key].starttime = l_cur_game_time()
		me.var.jin[key].count = 0
	else
		me.var.jin[key].starttime = l_cur_game_time()
	end
	
	if isServ() then
		ach.key_inc4(me,'jin_'..key)
	end
	
	return 0
end