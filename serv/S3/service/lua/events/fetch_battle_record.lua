
function onEvent(me)
	local id = getUEParams()
	
	if nil==id then
		error('invalid param')
	end
	
	
	if isServ() then
		
		local t = { db.command_and_wait(db.hash(id),'HMGET %s a b',id) }
		if 2 ~= #t then
			return 1
		end
		
		local bin = box.serialize({})
		daily.push_data_to_c('battle_record',bin)
		
		daily.push_data_to_c('battle_record.target',t[1])
		daily.push_data_to_c('battle_record.record',t[2])
		
	end
	
	return 0		
end

