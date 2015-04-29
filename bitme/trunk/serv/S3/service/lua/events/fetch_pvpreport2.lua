
function onEvent(me)
	if isServ() then
		local ss1 = box.serialize(me.pvpreport2)
		daily.push_data_to_c('pvpreport2',ss1)
	end
	
	return 0		
end
