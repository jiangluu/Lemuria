function onEvent(me)
	
	local bossType = getUEParams()
	
	if nil == bossType then
		error('invalid input param')
	end
	
		--判断是否有该BOSS
	local isHave = false
	
	util.travalPlayerLobby(me,function(lobby)
		if bossType == lobby.type then
			isHave = true
			
			return true
		end
	end)
	
	if false == isHave then
		return 1
	end
	
		--判断是否有研究所
	local targetMap = nil
	
	util.travalPlayerMap(me,function(m)
		if 'ri' == m.type then
			targetMap = m
			
			return true
		end
	end)
	
	if nil == targetMap then
		return 1
	end
	
		--判断是否有可用的蜥蜴
	local lmTime = false
	local lmNum = 0
	
	util.travalPlayerMob(me,function(mob,map)
		if 'lm' == mob.type then
			lmNum = lmNum + 1
			if nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time() then
				lmTime = true
				
				return true
			end
		end
	end)
	
	if false == lmTime or 0 == lmNum then
		return 1
	end
	
		--取BOSS当前等级
	local level = 1
	
	if nil ~= me.var.research[bossType] then
		level = me.var.research[bossType]
	end
	
		--升级BOSS花费类型
	local spendType = sd.creature[bossType]['info'][level + 1]['cost_type']
		--升级BOSS花费价格
	local num = sd.creature[bossType]['info'][level + 1]['re_cost']
		--升级BOSS花费时间
	local times = sd.creature[bossType]['info'][level + 1]['re_time']
		--升级BOSS需要研究所等级
	local  reLevel = sd.creature[bossType]['info'][level + 1]['re_level']
	
		--判断BOSS是否为最高等级
	if (((nil == spendType or nil == num) or nil == times) or nil == reLevel) then
		return 1
	end
	
		--赋值花费类型
	local resKey
	
	if 0 == spendType then
		resKey = 'meat'
	elseif 1 == spendType then
		resKey = 'elixir'
	elseif 2 == spendType then
		resKey = 'diamond'
	else 
		return 1
	end
	
		--满足升级条件，扣掉资源
	if me.basic[resKey] >= num and reLevel <= targetMap.level then
		util.dec(me,resKey,num,'research_boss')
	else
		return 1
	end
	
		--增加蜥蜴休息时间
	util.travalPlayerMob(me,function(mob,map)
		if 'lm' == mob.type and (nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time()) then
			util.worker_into_cd(mob,times)
			
			return true
		end
	end)
	
		--升级研究所BOSS等级
	me.var.research[bossType] = level + 1
	
		--升级该BOSS等级
	util.travalPlayerLobby(me,function(lobby)
		if bossType == lobby.type then
			lobby.level = level + 1
			
			return true
		end
	end)
	
	util.travalPlayerMob(me,function(mob,map)
		if bossType == mob.type then
			mob.level = level + 1
			
			return true
		end
	end)
	
	if isServ() then
		ach.key_inc_daily(me,'levelup_BOSS',1)
	end
	
		--刷新数据
	util.fillCacheData(me)
	
	return 0
		
end