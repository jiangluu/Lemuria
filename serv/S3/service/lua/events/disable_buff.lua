function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	if nil == me.buff[key] then
		return 1
	end
	
	util.use_update_array(me)
	me.buff[key] = nil
	
	return 0
end