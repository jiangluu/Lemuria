
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
	
	if 6~=shop_item.catagory then
		error('invalid catagory')
	end
	
	if shop_item.has>0 then
		error('has > 0')
	end
	
	local foo = function(res_key)
		if me.basic[res_key]<shop_item.cost then
			alog.debug('not enough res to buy')
			return 1
		end
		
		util.dec(me,res_key,shop_item.cost,'contract')
		
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
	
	-- do real stuff
	local now = l_cur_game_time()
	local aa = 0
	
	if string.match(shop_item.type,'shd%d+') then
		if nil~=me.basic.shield_end_time then
			aa = me.basic.shield_end_time + shop_item.sh_time
		end
		me.basic.shield_end_time = now + shop_item.sh_time
		-- 取两个时间中大的一个
		me.basic.shield_end_time = math.max(me.basic.shield_end_time,aa)
		
		-- 记录CD时间
		me.var.cd[shop_item.type] = now + shop_item.cd_time
		
	elseif string.match(shop_item.type,'mng%d+') then
		if nil~=me.basic.steward_end_time then
			aa = me.basic.steward_end_time + shop_item.sh_time
		end
		me.basic.steward_end_time = now + shop_item.sh_time
		-- 取两个时间中大的一个
		me.basic.steward_end_time = math.max(me.basic.steward_end_time,aa)
	end
	
	util.resPeipin(me)
	
	return 0
end

