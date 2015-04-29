-- PVP对手匹配
-- 选择入侵玩家后，匹配旌旗积分最接近、不在线、不在免战期、非好友、非同公会的其他玩家领地。		


function onEvent(me)
	local a_key = getUEParams()
	local my_sn = me.basic.usersn
	
	
	if isServ() then
		local lcf = ffi.C	
		
		local now = tonumber(lcf.cur_game_time())
		
		
		local tt = { db.command_and_wait(db.hash(a_key),'HMGET %s basic map buff var llog',a_key) }
		-- TO BE REMOVED
		if 4==table.getn(tt) then
			local bin = RG.fixOldData(a_key)
			
			table.insert(tt,bin)
		end
		-- END
		if 5==table.getn(tt) then
			local pvp_battle = {}
			pvp_battle.basic = box.unSerialize(tt[1])
			pvp_battle.map = box.unSerialize(tt[2])
			pvp_battle.buff = box.unSerialize(tt[3])
			pvp_battle.llog = box.unSerialize(tt[5])
			local var = box.unSerialize(tt[4])
			pvp_battle.map.research = var.research
			
			RG.RGCreasteLog(pvp_battle)			-- 计算一下资源增长
			RG.RGCommitLog(pvp_battle,false)
			util.resPeipin(pvp_battle)
			
			local ss = box.serialize(pvp_battle)
			daily.push_data_to_c('pvpbattle',ss)
			
			me.inbattle = nil	-- 清理
			me.cache.pvp_usersn = a_key
			me.cache.pvp_copy = pvp_battle
			
			if nil==me.cache.just_found then
				me.cache.just_found = {}
			end
			table.insert(me.cache.just_found,{tonumber(a_key),now})
			
			return 0
		end
	end
	
	return 1
end

