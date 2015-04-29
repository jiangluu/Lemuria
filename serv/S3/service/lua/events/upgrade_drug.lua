function onEvent(me)
	local drugType = getUEParams()
	
	if nil == drugType then
		error('invalid input param')
	end
	
		--�Ƿ���ҩ��
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
	
		--ҩ�������Ƿ�������ʱ��
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
	
		--ҩ�̵ȼ��Ƿ���������ҩ����Ҫ
	local drugLevel = 1
	
	if nil ~= me.var.research[drugType] then
		drugLevel = me.var.research[drugType]
	end		
		
	local needLevel = sd.drug[drugType]['info'][drugLevel + 1]['re_level']
	
	if psLevel < needLevel then
		return 1
	end
	
		--�ж���Դ�Ƿ�����������Ҫ
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
	
		--�������㣬�۵���Դ
	util.dec(me,resKey,spendNum,'research_drug')
	--�Ӿ���
	util.add_exp_level(me,sd.drug[drugType]['info'][drugLevel + 1]['re_exp'])
	
		--����ҩ������������Ϣʱ��
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			util.worker_into_cd(mob,spendTime)
			
			return true
		end
	end)
	
		--�����о�����ȼ�
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
	
	
	
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0	
end