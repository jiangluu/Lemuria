
function onEvent(me)
	local heroType,new_hp = getUEParams()
	
	if nil == heroType or nil==tonumber(new_hp) then
		error('invalid param')
	end
	
	if tonumber(new_hp)>100 then
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
	
	if hero.stamina < tonumber(new_hp) then
		-- 不能加体力
		return 1
	end
	
	hero.stamina = tonumber(new_hp)
	hero.last_battle_time = nil
	
	
	return 0		
end