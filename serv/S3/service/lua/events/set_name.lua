
function onEvent(me)
	local name = getUEParams()	
	if nil==name then 
		error('invaild param')
	end		
	if not util.is_newbie_name(me.basic) then	
		return 1
	end	
	me.basic.name=name
	
	me.basic.steward_end_time = l_cur_game_time() + sd.default.basic.default.vip
	me.basic.vip = nil
	return 0
end

