function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	util.use_update_array(me)
		--�ж����Ƿ�����Լ������Ƿ��㹻
	if nil == me.var.jin[key] then
		return 1
	end
	
	if me.var.jin[key].count < 1 then
		return 1
	end
	
		--���㣬������������buff
	me.var.jin[key].count = me.var.jin[key].count - 1
	
	if 0 == me.var.jin[key].starttime then
		me.var.jin[key].starttime = l_cur_game_time()
	end
	
	local buffKey = sd.jin[key]['buff']
	
	if nil~= me.buff[buffKey] then
		return 1
	end
	
	me.buff[buffKey] = 1
	
	return 0
end