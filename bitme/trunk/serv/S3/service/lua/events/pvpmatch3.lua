-- 联赛的准备打别人	


function onEvent(me)
	local target_index = getUEParams()
	local my_sn = me.basic.usersn
	
	
	if isServ() then
		local lcf = ffi.C	
		
		local now = tonumber(lcf.cur_game_time())
		
		if nil==me.cache.league then
			return 1
		end
		local ta_usersn = tostring(me.cache.league.list[target_index].usersn)
		
		
		
		local tt = { db.command_and_wait(db.hash(ta_usersn),'HMGET %s basic map buff llog',tostring(ta_usersn)) }
		-- TO BE REMOVED
		if 3==table.getn(tt) then
			local bin = RG.fixOldData(ta_usersn)
			
			table.insert(tt,bin)
		end
		-- END
		if 4==table.getn(tt) then
			local pvp_battle = {}
			pvp_battle.basic = box.unSerialize(tt[1])
			pvp_battle.map = box.unSerialize(tt[2])
			pvp_battle.buff = box.unSerialize(tt[3])
			pvp_battle.llog = box.unSerialize(tt[4])
			
			RG.RGCreasteLog(pvp_battle)			-- 计算一下资源增长
			RG.RGCommitLog(pvp_battle,false)
			util.resPeipin(pvp_battle)
			
			local ss = box.serialize(pvp_battle)
			daily.push_data_to_c('pvpbattle',ss)
			
			me.inbattle = nil	-- 清理
			me.cache.pvp_usersn = ta_usersn
			me.cache.pvp_copy = pvp_battle
			me.cache.pvp_way = 3
			
			
			return 0
			
		end
	end
	
	return 1
end

