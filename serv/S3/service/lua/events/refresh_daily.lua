
function onEvent(me)
	
	if isServ() then
		local old = me.addition.daily.accept_time
		
		daily.check_and_give_daily(me)
		
		if me.addition.daily.accept_time~=old then
			local str = box.serialize(me.var.stat_daily)
			daily.push_data_to_c('var.stat_daily',str)
			
			str = box.serialize(me.addition.daily)
			daily.push_data_to_c('addition.daily',str)
		end
	end
	
	return 0
end
