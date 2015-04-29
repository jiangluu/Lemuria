
function onEvent(me)
	local key = getUEParams()
	
	local has_hero = false
	if me.hero and me.hero.list and #me.hero.list>0 then
		has_hero = true
	end
	
	if has_hero then
		error('already has hero')
	end
	
	local conf = sd.creature[key]
	if nil==conf then
		return 1
	end
	
	if 'hero'~=conf.type then
		return 1
	end
	
	me.hero.list = newArray()
	table_insert(me.hero.list,{type=key,level=1,inuse=true,stamina=100})
	
	-- ËÍ×°±¸
	for _,hero in pairs(me.hero.list) do
		local conf = sd.creature[hero.type]
		if conf and conf.equip then
			hero.equip = {}
			hero.equip.list = newArray()
			
			if conf.equip.item then
				table_insert(hero.equip.list,{type=conf.equip.item,level=1,weapon = true})
			else
				for __,ek in pairs(conf.equip) do
					table_insert(hero.equip.list,{type=ek.item,level=1})
				end
			end
		end
	end
	
	return 0
end
