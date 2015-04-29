
function onEvent(me)
	
	local key = getUEParams()
	
	if nil==me.var.ns.bind_google then
		me.var.ns.bind_google = {}
	end
	
	if me.var.ns.bind_google[key] then
		error('already bind')
	end
	
	me.var.ns.bind_google[key] = 1
	
	return 0
end

