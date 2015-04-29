function onEvent(me)
	local index = getUEParams()
	
	if nil == index then
		error('invalid input param')
	end
	local drugType= me.var.drug.list[index].type
		--判断是否存在并记录位置
	
	
	if nil==drugType then
		return 1
	end
	
		--计算原本所需的资源
	local drugLevel = 1
	
	if nil ~= me.var.research.drugType then
		drugLevel = me.var.research.drugType
	end
	
	local spendType = sd.drug[drugType]['info'][drugLevel]['cost_type']
	local spendNum = sd.drug[drugType]['info'][drugLevel]['cost_count']
	local spendTime = sd.drug[drugType]['info'][drugLevel]['time']

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
	
		--增加资源
	util.add(me,resKey,spendNum / 2,'cancel_drug')
		
		--减少药剂三脸休息时间
	local times = nil
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			mob.next_develop_time = mob.next_develop_time - spendTime			
			return true
		end
	end)

		--修改表
	--if 2 == index and 3 == #me.var.drug.list then
	--	me.var.drug.list[3].finish_time = me.var.drug.list[3].finish_time - spendTime
	--end
	
	for i=index+1,#me.var.drug.list do
		me.var.drug.list[i].finish_time = me.var.drug.list[i].finish_time - spendTime
	end	
	table_remove(me.var.drug.list,index)
	
	
	if #me.var.drug.list>0 then
		local dd=me.var.drug.list[#me.var.drug.list]
		if isServ() then
			me.var.drug.a =dd
		else
			me.var.drug.a = {}		
			deepCloneTableToUserData(me.var.drug.a,dd)	
		end
	else
		-- 不删
		me.var.drug.a.rest_time = 0
	end
		--刷新数据
	util.fillCacheData(me)
	
	return 0		
end
