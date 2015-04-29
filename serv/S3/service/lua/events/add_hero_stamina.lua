function onEvent(me)
	local heroType = getUEParams()
	
	if nil == heroType then
		error('invalid param')
	end
	
		--判断是否有该英雄并取出
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

		--判断金丹是否够用
	if not util.check(me,'diamond',needNum) then
		return 1
	end
	
		--条件满足，扣金丹、补满体力、设置时间
	util.dec(me,'diamond',needNum,'heroheal')
	hero.stamina = 100
	hero.heal = nil
	
	hero.last_battle_time = nil
	
		--刷新数据
	util.fillCacheData(me)
	
	return 0		
end