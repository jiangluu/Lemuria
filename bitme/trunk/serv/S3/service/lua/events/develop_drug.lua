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
	
		--ҩ�������Ƿ�ﵽ����
	local drugNum = 0

	if nil ~= me.var.drug.list then
		drugNum = #me.var.drug.list
	end
	
	local drugLimit = sd.scene['ps']['detail'][psLevel]['make_count']
	
	if drugNum >= drugLimit then
		return 1
	end
	
		--ҩ�̵ȼ��Ƿ���������ҩ����Ҫ	
	local needLevel = sd.drug[drugType]['build_level']
	
	if psLevel < needLevel then
		return 1
	end
	
		--�ж���Դ�Ƿ���������ʹ��
	local drugLevel = 1
	
	if nil ~= me.var.research[drugType] then
		drugLevel = me.var.research[drugType]				
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
	
	if me.basic[resKey] < spendNum then
		return 1
	end
	
		--�������㣬�۵���Դ
	util.dec(me,resKey,spendNum,'drug')
	
		--����ҩ������������Ϣʱ��
	local times = nil
	local rest_time=nil
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			if nil == mob.next_develop_time then
				mob.next_develop_time = l_cur_game_time()
			end
			
			if  mob.next_develop_time<l_cur_game_time() then
				 mob.next_develop_time=l_cur_game_time()
			end
			
			if nil==me.var.drug.list  then
				times = l_cur_game_time()				
			else
				local count=#me.var.drug.list
							
				times=me.var.drug.a.rest_time+me.var.drug.a.finish_time				
				if times<l_cur_game_time() then
					times=l_cur_game_time()
				end
			end
			rest_time=spendTime
			mob.next_develop_time = mob.next_develop_time + spendTime
			return true
		end
	end)
	
	--�Ӿ���
	util.add_exp_level(me,sd.drug[drugType]['info'][drugLevel]['exp'])
		--����ҩ����
	
	
	util.makesureListExists(me.var.drug)
	
	
	local dd={type = drugType,level = drugLevel,finish_time = times,rest_time=rest_time}
	table_insert(me.var.drug.list,dd)
	if isServ() then
		me.var.drug.a = dd
	else
		me.var.drug.a = {}
		deepCloneTableToUserData(me.var.drug.a,dd)
	end
	--��ҩ����
	--if me.var.drug.list[#me.var.drug.list].finish_time == l_cur_game_time() then	
	if isServ() then
		ach.key_inc3(me,'drug')
		ach.key_inc4(me,'drug_'..drugType)
	end
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0		
end