
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
	
	if 4~=shop_item.catagory then
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
		
		util.dec(me,res_key,shop_item.cost,'boss')
		
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
	
	
	local new_boss = {type=shop_item.type,level=shop_item.level,num=1}
	
	util.addToLobby(me,new_boss)
		--×¤ÊØµÚÒ»¸öboss
	local my_to = nil
	
	for i = 1,#me.map.list do
		if 'to' == me.map.list[i].type then
			my_to = me.map.list[i]
		end
	end
		
	local boss = nil
	
	for i = 1,#me.lobby.list do
		if shop_item.type == me.lobby.list[i].type then
			boss = me.lobby.list[i]
		end
	end
	
	if nil == my_to or nil == boss then
		error('bad data')
	end
	
	if nil == my_to.mob then
		my_to.mob = {}
		my_to.mob.list = newArray()
	end
	
	if #my_to.mob.list == 0 then
		table_insert(my_to.mob.list,{type=boss.type,level=boss.level,num=boss.num})
		boss.num_used = boss.num
	end
	
		---------------
	util.resPeipin(me)
	
	-- output part
	return 0
end

