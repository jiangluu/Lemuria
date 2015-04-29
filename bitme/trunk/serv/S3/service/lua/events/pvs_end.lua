function onEvent(me)

	if isServ() then
		ach.key_inc_daily(me,'PVS')
	end
	
	return 0
end