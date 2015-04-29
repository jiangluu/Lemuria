function onEvent(me)
	local hero_index,mob_ids = getUEParams()
	
	if nil == hero_index or nil==mob_ids then
		error('invalid param')
	end
	
	local t_id = {}
	for aa in string.gmatch(mob_ids,'(%w+)') do
		table.insert(t_id,aa)
	end
	
	if (#t_id)%2 ~= 0 then
		error('invalid param')
	end
	
	for i=2,#t_id,2 do
		if nil==tonumber(t_id[i]) then
			error('invalid param')
		end
	end
	
	if nil==me.hero.list[hero_index] then
		error('invalid param')
	end
	
	local this_hero = me.hero.list[hero_index]
	if nil==this_hero.pet then
		this_hero.pet = {}
	end
	
	this_hero.pet.list = newArray()		-- 先清掉
	
	for i=1,#t_id,2 do
		table_insert(this_hero.pet.list,{ type=t_id[i],level=tonumber(t_id[i+1]) })
	end
	
	if 0 == #this_hero.pet.list then
		this_hero.pet = nil
	end
	
	
	return 0		
end
