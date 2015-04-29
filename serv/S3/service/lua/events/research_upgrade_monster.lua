
function onEvent(me)
	local monsterType = getUEParams()
	if nil == monsterType then
		error('invalid input param')
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
	
		--判断是否有可用的蜥蜴（升级怪）
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
	
		--取怪物当前等级
	local level = 1
	if nil ~= me.var.research[monsterType] then
		level = me.var.research[monsterType]
	end
	
		--已有怪物数量
	local monsterNum = 0
	util.travalPlayerMob(me,function(mob,map)
		if monsterType == mob.type then
			monsterNum = monsterNum + 1
		end
	end)
	
		--升级怪物花费类型
	local spendType = sd.creature[monsterType]['info'][level + 1]['cost_type']
		--升级怪物花费数量
	local num = sd.creature[monsterType]['info'][level + 1]['re_cost']
		--买怪物基础价格
	local baseNum = sd.creature[monsterType]['info'][level]['cost']
		--买下一级怪物价格
	local nextNum = sd.creature[monsterType]['info'][level + 1]['cost']
		--升级怪物花费时间
	local times = sd.creature[monsterType]['info'][level + 1]['re_time']
		--买怪物基础时间
	local baseTimes = sd.creature[monsterType]['info'][level]['time']
		--买下一级怪物时间
	local nextTimes = sd.creature[monsterType]['info'][level + 1]['time']
		--升级怪物需要研究所的等级
	local reLevel = sd.creature[monsterType]['info'][level + 1]['re_level']
	
		--判断是否为最高等级
	if (((nil == spendType or nil == num) or nil == times) or nil == reLevel) then
		return 1
	end
	
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
	
		--补差价
	num = num + monsterNum * (nextNum - baseNum)
	times = times + monsterNum * (nextTimes - baseTimes)
	
		--满足升级条件，扣掉资源
	if me.basic[resKey] >= num and reLevel <= targetMap.level then
		util.dec(me,resKey,num,'research_mon')
	else
		return 1
	end
	
		--增加休息时间
	util.travalPlayerMob(me,function(mob,map)
		if 'lm' == mob.type and (nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time()) then
			util.worker_into_cd(mob,times)
			
			return true
		end
	end)
	
	-----加经验
	util.add_exp_level(me,sd.creature[monsterType]['info'][level+1]['re_exp'])
	
		--升级研究所怪物等级
	me.var.research[monsterType] = level + 1
	--升级怪数量
	if isServ() then
		ach.key_inc3(me,'mons')
	end
	
		--把已有怪升级
	util.travalPlayerMob(me,function(mob,map)
		if monsterType == mob.type then
			if mob.level == level + 1 then
				return true
			end
			mob.level = level + 1
		end
	end)
	
	if me.lobby.list then
		for i=1,#me.lobby.list do
			local mm = me.lobby.list[i]
			if monsterType == mm.type then
				mm.level = level + 1
			end
		end
	end
	------------仆从等级
	for i=1,#me.hero.list do
		if nil~=me.hero.list[i].pet then
			local pet=me.hero.list[i].pet.list
			for z=1,#pet do
				
				if pet[z].type==monsterType then					 
					 pet[z].level=level + 1				
				end
			end
		end
	end
	

	util.fillCacheData(me)
	
	if isServ() then
		local ss = string.format('verbose_upgrade_monster,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,monsterType,level+1,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0	
		
end