-- PVP对手匹配
-- 选择入侵玩家后，匹配旌旗积分最接近、不在线、不在免战期、非好友、非同公会的其他玩家领地。		

local one_grade_retry_times = 10

local search_command_queue = {
	0,
	1,
	-1,
	2,
	-2,
	3,
	-3,
	4,
	-4,
	5,
	-5,
	6,
	-6,
	7,
	-7,
	8,
	-8,
	9,
	-9,
	10,
	-10,
}


function onEvent(me)
	-- 这个请求没有输入参数
	local my_sn = me.basic.usersn
	
	local to_level = 1
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			to_level = m.level
			return true
		end
	end)
	
	local to_dec = sd.battle.default.info[to_level].match_cost
	local to_dec_type = sd.battle.default.info[to_level].match_cost_type
	
	local function foo(res_key)
		if me.basic[res_key] < to_dec then
			return false
		end
		
		util.dec(me,res_key,to_dec,'pvpmatch')
		return true
	end
	
	local suc = false
	if 0==to_dec_type then
		suc = foo('meat')
	elseif 1==to_dec_type then
		suc = foo('elixir')
	else
		suc = foo('diamond')
	end
	
	if not suc then
		return 1
	end
	
	util.fillCacheData(me)
	
	
	if isServ() then
		local lcf = ffi.C	
		
		local now = tonumber(lcf.cur_game_time())
		
		local base_r_key = ranklist.rank_to_key(me.basic.flag)	-- 基准线
		local prefix,base_num = string.match(base_r_key,'(%a+)(%d+)')
		if nil==prefix or nil==base_num then
			return 1
		end
		
		
		local function search_one_grade(r_key)
		
			for i=1,one_grade_retry_times do
				local a_key = redis.command_and_wait(1,'SRANDMEMBER %s',r_key)
				
				if nil==a_key then
					return false	-- 这时就不用retry one_grade_retry_times次了，浪费时间
				end
				
				if nil~=tonumber(a_key) and tonumber(my_sn)~=tonumber(a_key) then		-- 暂时只要找到不是自己的就好
					local stat = redis.command_and_wait(0,'HGET %s a',a_key)
					
					local can_attack = false
					if nil==stat then
						can_attack = true
					else
						stat = tonumber(stat)
						if stat>=0 and stat<=now then
							can_attack = true
						end
					end
					
					-- 刚刚搜索过的不可
					if true==can_attack then
						if nil==me.cache.just_found then
							me.cache.just_found = {}
						end
						for jj=1,#me.cache.just_found do
							local aa = me.cache.just_found[jj]
							if tonumber(a_key) == tonumber(aa[1]) and now < tonumber(aa[2])+60 then
								can_attack = false
								break
							end
						end
					end
					
					
					if can_attack then
						local tt = { db.command_and_wait(db.hash(a_key),'HMGET %s basic map buff var llog',a_key) }
						-- TO BE REMOVED
						if 4==table.getn(tt) then
							local bin = RG.fixOldData(a_key)
							
							table.insert(tt,bin)
						end
						-- END
						if 5==table.getn(tt) then
							local ta_basic = tt[1]
							
							local bb = box.unSerialize(ta_basic)
							if util.is_newbie_name(bb) then
								can_attack = false
							end
							
							-- 同公会不可
							if bb.guild and me.basic.guild and bb.guild.id==me.basic.guild.id then
								can_attack = false
							end
							
							if can_attack then
								local pvp_battle = {}
								pvp_battle.basic = bb
								pvp_battle.map = box.unSerialize(tt[2])
								pvp_battle.buff = box.unSerialize(tt[3])
								pvp_battle.llog = box.unSerialize(tt[5])
								local var = box.unSerialize(tt[4])
								pvp_battle.map.research = var.research
								
								-- for security
								pvp_battle.basic.lkey = nil
								
								
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
								
								return true		-- suc
							end
						end
					end
				end
			end
		
			return false	-- not found
		end
		
		for i=1,#search_command_queue do
			local aa = search_command_queue[i]
			aa = aa + tonumber(base_num)
			
			if aa>=0 then
				local the_key = string.format('%s%d',prefix,aa)
				local ret = search_one_grade(the_key)
				
				if true==ret then
					return 0
				end
			end
		end
		
		return 1	-- 找了前后N段最终也没找到
		
	else
		return 0
	end
	
	return 1
end

