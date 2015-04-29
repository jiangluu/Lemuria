function onEvent(me)
	local heroType = getUEParams()
	
	if nil == heroType then
		error('invalid param')
	end
	
		--�ж��Ƿ��и�Ӣ�۲�ȡ��
	local hero = nil
	
	for i = 1,#me.hero.list do
		if heroType == me.hero.list[i].type then
			hero = me.hero.list[i]
		end
	end
	
	
	if nil == hero then
		return 1
	end
	
	if not hero.heal then
		return 1
	end
	
	if hero.stamina==100 then
		return 0
	end
	
	local left = 100 - hero.stamina
	local needNum = util.calcHealDiamond(me,left)
	
	if needNum <= 0 then
		error('time error')
	end

		--�жϽ��Ƿ���
	if not util.check(me,'diamond',needNum) then
		return 1
	end
	
		--�������㣬�۽𵤡���������������ʱ��
	util.dec(me,'diamond',needNum,'heroheal')
	hero.stamina = 100
	hero.heal = nil
	
	hero.last_battle_time = nil
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0		
end