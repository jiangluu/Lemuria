function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	if nil == me.var.jin[key] then
		return 1
	end
	
	util.update_array(me,key)	--½áËã
	me.var.jin[key].starttime = nil
	
	return 0
end