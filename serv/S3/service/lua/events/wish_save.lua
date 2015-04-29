
function onEvent(me)
	
	if isServ() then
		
		if ownership.is_mine(me.basic.usersn,me.cache.session) then
			
			box.do_save_player(me)
			
		end
		
	end
	
	return 0		
end
