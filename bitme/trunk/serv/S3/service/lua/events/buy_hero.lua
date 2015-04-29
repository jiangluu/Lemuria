
function onEvent(me)
	local shop_hash = getUEParams()	-- UE Param means User Event Param
	
	if nil==shop_hash then
		error('invalid input param')
	end
	
	me.cache.shop = util.generateShop(me)
	
	-- logic part, some code here
	local shop_item = nil
	for i=1,#me.cache.shop do
		if shop_hash==me.cache.shop[i].hash then
			shop_item = me.cache.shop[i]
			break
		end
	end
	
	if nil==shop_item then
		error('invalid shop_hash')
	end
	
	if 3~=shop_item.catagory then
		error('invalid catagory')
	end
	
	if shop_item.limit - shop_item.has<1 then
		error('limit-has < 1')
	end
	
	local conf = sd.creature[shop_item.type]
	if nil==conf then
		error('invalid static data')
	end
	
	local foo = function(res_key)
		if me.basic[res_key]<shop_item.cost then
			alog.debug('not enough res to buy')
			return 1
		end
		
		util.dec(me,res_key,shop_item.cost,'hero')
		
		shop_item.has = shop_item.has + 1
		
		return 0
	end
	
	local suc = 1
	if 0==shop_item.cost_type then
		suc = foo('meat')
	elseif 1==shop_item.cost_type then
		suc = foo('elixir')
	elseif 2==shop_item.cost_type then
		suc = foo('diamond')
	else
		return 1
	end
	
	if 0~=suc then
		return 1
	end
	
	local new_hero = {type=shop_item.type,level=shop_item.level,stamina=100}
	if nil~=conf.equip then
		new_hero.equip = {}
		new_hero.equip.list = newArray()
		
		if conf.equip.item then
			table_insert(new_hero.equip.list,{type=conf.equip.item,level=1,weapon = true})
		else
			for __,ek in pairs(conf.equip) do
				table_insert(new_hero.equip.list,{type=ek.item,level=1})
			end
		end
	end
	table_insert(me.hero.list,new_hero)
	--table_insert(me.hero.list,{type=shop_item.type,level=shop_item.level})
	
	util.resPeipin(me)
	
	util.updateHeroEquip(me)
	
	return 0
end

