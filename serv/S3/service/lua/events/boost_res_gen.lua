
function onEvent(me)
	local map_index = getUEParams()	-- UE Param means User Event Param
	
	if nil==map_index then
		error('invalid input param')
	end
	
	local ta_map = me.map.list[map_index]
	if nil==ta_map then
		error('invalid map_index')
	end
	
	local conf = sd.scene[ta_map.type]
	if not conf then
		error('sd not found')
	end
	
	if not conf.detail[ta_map.level].boost_time then
		error('no boost_time')
	end
	
	if not util.dec(me,'diamond',tonumber(conf.detail[ta_map.level].boost_cost),'boost') then
		return 1
	end
	
	RG.RGCreasteLog(me)
	
	ta_map.boost_time = l_cur_game_time() + conf.detail[ta_map.level].boost_time
	
	util.resPeipin(me)
	
	-- output part
	return 0
end

