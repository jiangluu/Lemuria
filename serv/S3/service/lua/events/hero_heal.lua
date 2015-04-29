
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
			break
		end
	end
	
	if nil == hero then
		return 1
	end
	
	if hero.stamina>=100 then
		return 0
	end
	
	local left = 100 - hero.stamina
	local cost = util.calcHealEli(me,left)
	
	if cost<=0 then
		return 0
	end
	
	if not util.check(me,'elixir',cost) then
		return 1
	end
	
	util.dec(me,'elixir',cost,'heroheal')
	hero.heal = true
	
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0		
end
