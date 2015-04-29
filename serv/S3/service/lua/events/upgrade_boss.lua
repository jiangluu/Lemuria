function onEvent(me)
	
	local bossType = getUEParams()
	
	if nil == bossType then
		error('invalid input param')
	end
	
		--�ж��Ƿ��и�BOSS
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
	
		--�ж��Ƿ��п��õ�����
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
	
		--ȡBOSS��ǰ�ȼ�
	local level = 1
	
	if nil ~= me.var.research[bossType] then
		level = me.var.research[bossType]
	end
	
		--����BOSS��������
	local spendType = sd.creature[bossType]['info'][level + 1]['cost_type']
		--����BOSS���Ѽ۸�
	local num = sd.creature[bossType]['info'][level + 1]['re_cost']
		--����BOSS����ʱ��
	local times = sd.creature[bossType]['info'][level + 1]['re_time']
		--����BOSS��Ҫ�о����ȼ�
	local  reLevel = sd.creature[bossType]['info'][level + 1]['re_level']
	
		--�ж�BOSS�Ƿ�Ϊ��ߵȼ�
	if (((nil == spendType or nil == num) or nil == times) or nil == reLevel) then
		return 1
	end
	
		--��ֵ��������
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
	
		--���������������۵���Դ
	if me.basic[resKey] >= num and reLevel <= targetMap.level then
		util.dec(me,resKey,num,'research_boss')
	else
		return 1
	end
	
		--����������Ϣʱ��
	util.travalPlayerMob(me,function(mob,map)
		if 'lm' == mob.type and (nil == mob.next_enable_time or mob.next_enable_time < l_cur_game_time()) then
			util.worker_into_cd(mob,times)
			
			return true
		end
	end)
	
		--�����о���BOSS�ȼ�
	me.var.research[bossType] = level + 1
	
		--������BOSS�ȼ�
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
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0
		
end