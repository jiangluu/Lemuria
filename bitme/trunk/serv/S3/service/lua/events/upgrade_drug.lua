function onEvent(me)
	local drugType = getUEParams()
	
	if nil == drugType then
		error('invalid input param')
	end
	
		--是否有药铺
	local havePs = false
	local psLevel = 1
	
	util.travalPlayerMap(me,function(m)
		if 'ps' == m.type then
			havePs = true
			psLevel = m.level
			
			return true
		end
	end)
	
	if false == havePs then
		return 1
	end
	
		--药剂三脸是否有升级时间
	local haveTime = false
	
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			if nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time() then
				haveTime = true
				
				return true
			end
		end
	end)
	
	if false == haveTime then
		return 1
	end
	
		--药铺等级是否满足升级药剂需要
	local drugLevel = 1
	
	if nil ~= me.var.research[drugType] then
		drugLevel = me.var.research[drugType]
	end		
		
	local needLevel = sd.drug[drugType]['info'][drugLevel + 1]['re_level']
	
	if psLevel < needLevel then
		return 1
	end
	
		--判断资源是否满足升级需要
	local spendType = sd.drug[drugType]['info'][drugLevel + 1]['cost_type']
	local spendNum = sd.drug[drugType]['info'][drugLevel + 1]['re_count']
	local spendTime = sd.drug[drugType]['info'][drugLevel + 1]['re_time']
	
	local resKey = nil
	
	if 0 == spendType then
		resKey = 'meat'
	elseif 1 == spendType then
		resKey = 'elixir'
	elseif 2 == spendType then
		resKey = 'diamond'
	else
		return 1
	end
	
	if me.basic[resKey] < spendNum then
		return 1
	end	
	
		--条件满足，扣掉资源
	util.dec(me,resKey,spendNum,'research_drug')
	--加经验
	util.add_exp_level(me,sd.drug[drugType]['info'][drugLevel + 1]['re_exp'])
	
		--增加药剂三脸升级休息时间
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			util.worker_into_cd(mob,spendTime)
			
			return true
		end
	end)
	
		--提升研究结果等级
	me.var.research[drugType] = drugLevel + 1
	
	if nil~=me.var.drug.list then
		for i = 1,#me.var.drug.list do
			if nil~=me.var.drug.a and drugType==me.var.drug.a.type then
				me.var.drug.a.level=drugLevel+1
			end
			if drugType == me.var.drug.list[i].type then
				me.var.drug.list[i].level = drugLevel + 1
			end
		end
	end
	
	
	
	
		--刷新数据
	util.fillCacheData(me)
	
	return 0	
end