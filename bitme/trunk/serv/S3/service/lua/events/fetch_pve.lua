
function onEvent(me)
	local key = getUEParams()
	if nil==key then
		error('invalid param')
	end
	
	if isServ() then
		local dd = me.pve[key]
		if nil==dd then
			return 1
		end
		
		local str = box.serialize(dd)
		daily.push_data_to_c('cache.pve_fetch',str)
	end
	
	return 0		
end
