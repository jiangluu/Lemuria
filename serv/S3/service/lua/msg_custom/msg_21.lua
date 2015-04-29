
local lcf = ffi.C



-- CombatStart 	21 	NULL 	开始一次PVP战斗
function onMsg(me)
	local ta_usersn = nil
	
	local index = lcf.cur_stream_get_int32()
	if index>0 then
		ta_usersn = me.pvpreport1.list[index].usersn
	else
		ta_usersn = me.cache.pvp_usersn
	end
	
	local function err_ack(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_write_back()
	end
	
	if nil==ta_usersn then
		err_ack(1)
		return 1
	end
	
	ta_usersn = tostring(ta_usersn)
	
	local now = lcf.cur_game_time()
	
	-- 检查在线否，是否能攻击
	if 3~=me.cache.pvp_way then
		local stat = tonumber(redis.command_and_wait(0,'HGET %s a',tostring(ta_usersn)))
		if stat and stat<0 then	-- 在线or正在被人打
			err_ack(stat)
			return 1
		end
		
		if stat and now<stat then		-- 护盾未过期
			err_ack(5)
			return 1
		end
	end
	
	if index>0 then
		-- 1-可以复仇  2-无法复仇  3-已复仇
		me.pvpreport1.list[index].bson.stat = 3
	end
	me.cache.pvp_usersn = ta_usersn
	me.basic.shield_end_time = 1
	
	
	--判断是否带天罡阵或北斗阵出战
	if (nil~=me.var.jin.jin_atk and me.var.jin.jin_atk.count>0) 
		or (nil~=me.var.jin.jin_def and me.var.jin.jin_def.count>0) then
		ach.key_inc3(me,'activated_gw')
	end
	
	me.cache.just_found = nil	-- 清空搜索历史
	me.cache.pvp_start_time = now
	
	-- 是复仇的，赋上 me.cache.pvp_copy
	if index>0 then
		local tt = { db.command_and_wait(db.hash(ta_usersn),'HMGET %s basic map buff llog',ta_usersn) }
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
			
			me.cache.pvp_copy = pvp_battle
		end
	end
	
	-- 日志相关
	local hero = nil
	util.travalHero(me,function(h)
		if nil~=h.inuse then
			hero = h
			return true
		end
	end)
	if nil~=hero then
		ach.key_inc4(me,'pvp_hero_'..hero.type)
		
		if nil~=hero.pet and nil~=hero.pet.list then
			for i=1,#hero.pet.list do
				local mm = hero.pet.list[i]
				ach.key_inc4(me,'pvp_pet_'..mm.type)
			end
		end
		
		local valid_slot = {'weapon','armor','glove','ring1','ring2'}
		if nil~=hero.equip then
			for i=1,#hero.equip.list do
				local equipment = hero.equip.list[i]
				
				for j=1,#valid_slot do
					local key = valid_slot[j]
					if equipment[key] then
						ach.key_inc4(me,'pvp_equip_'..equipment.type)
					end
				end
			end
		end
	end
	
	err_ack(0)
	
	if 3~=me.cache.pvp_way then
		ownership.lock(ta_usersn,-4,600)	-- 正在被人打，超时600秒
	end
	
	yylog.log(string.format('pvpstart,usersn%d,targetsn%d',me.basic.usersn,ta_usersn))
	
	return 0
end

