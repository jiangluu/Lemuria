
function onEvent(me)
	local heroType,new_hp = getUEParams()
	
	if nil == heroType or nil==tonumber(new_hp) then
		error('invalid param')
	end
	
	if tonumber(new_hp)>100 then
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
	
	if hero.stamina < tonumber(new_hp) then
		-- ���ܼ�����
		return 1
	end
	
	hero.stamina = tonumber(new_hp)
	hero.last_battle_time = nil
	
	
	return 0		
end