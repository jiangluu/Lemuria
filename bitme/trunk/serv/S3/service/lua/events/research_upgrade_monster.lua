
function onEvent(me)
	local monsterType = getUEParams()
	if nil == monsterType then
		error('invalid input param')
	end
	
		--�ж��Ƿ����о���
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
	
		--�ж��Ƿ��п��õ����棨�����֣�
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
	
		--ȡ���ﵱǰ�ȼ�
	local level = 1
	if nil ~= me.var.research[monsterType] then
		level = me.var.research[monsterType]
	end
	
		--���й�������
	local monsterNum = 0
	util.travalPlayerMob(me,function(mob,map)
		if monsterType == mob.type then
			monsterNum = monsterNum + 1
		end
	end)
	
		--�������ﻨ������
	local spendType = sd.creature[monsterType]['info'][level + 1]['cost_type']
		--�������ﻨ������
	local num = sd.creature[monsterType]['info'][level + 1]['re_cost']
		--���������۸�
	local baseNum = sd.creature[monsterType]['info'][level]['cost']
		--����һ������۸�
	local nextNum = sd.creature[monsterType]['info'][level + 1]['cost']
		--�������ﻨ��ʱ��
	local times = sd.creature[monsterType]['info'][level + 1]['re_time']
		--��������ʱ��
	local baseTimes = sd.creature[monsterType]['info'][level]['time']
		--����һ������ʱ��
	local nextTimes = sd.creature[monsterType]['info'][level + 1]['time']
		--����������Ҫ�о����ĵȼ�
	local reLevel = sd.creature[monsterType]['info'][level + 1]['re_level']
	
		--�ж��Ƿ�Ϊ��ߵȼ�
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
	
		--�����
	num = num + monsterNum * (nextNum - baseNum)
	times = times + monsterNum * (nextTimes - baseTimes)
	
		--���������������۵���Դ
	if me.basic[resKey] >= num and reLevel <= targetMap.level then
		util.dec(me,resKey,num,'research_mon')
	else
		return 1
	end
	
		--������Ϣʱ��
	util.travalPlayerMob(me,function(mob,map)
		if 'lm' == mob.type and (nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time()) then
			util.worker_into_cd(mob,times)
			
			return true
		end
	end)
	
	-----�Ӿ���
	util.add_exp_level(me,sd.creature[monsterType]['info'][level+1]['re_exp'])
	
		--�����о�������ȼ�
	me.var.research[monsterType] = level + 1
	--����������
	if isServ() then
		ach.key_inc3(me,'mons')
	end
	
		--�����й�����
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
	------------�ʹӵȼ�
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