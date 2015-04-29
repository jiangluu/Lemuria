
function onEvent(me)
	local shop_hash,map_index,x,y = getUEParams()	-- UE Param means User Event Param
	
	if nil==shop_hash or nil==map_index or nil==x or nil==y then
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
	
	if 7~=shop_item.catagory then
		error('invalid shop_hash')
	end
	
	-- if shop_item.has >= shop_item.limit then
		-- error('has too much')
	-- end
	
	map_index = tonumber(map_index)
	local target_map = me.map.list[map_index]
	if nil==target_map then
		error('invalid input param')
	end
	
	local lm = nil
	util.travalPlayerMob(me,function(m,map)
		if 'lm'==m.type and (nil==m.next_enable_time or l_cur_game_time()>m.next_enable_time) then
			lm = m
			return true
		end
	end)
	if nil==lm then
		error('no lm')
	end
	
	
	-- 扣钱
	local foo = function(res_key)
		if me.basic[res_key]<shop_item.cost then
			alog.debug('not enough res to buy')
			return 1
		end
		
		util.dec(me,res_key,shop_item.cost,'trap')
		
		shop_item.has = (shop_item.has or 0) + 1
		
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
	
	if nil==target_map.trap then
		target_map.trap = {}
	end
	
	util.makesureListExists(target_map.trap)
	
	table_insert(target_map.trap.list,{type=shop_item.type,level=shop_item.level,x=x,y=y})
	
	-----加经验
	util.add_exp_level(me,sd.shop.trap[shop_item.type][1].exp)
	
	-- 使一个怪睡觉
	util.worker_into_cd(lm,shop_item.time)
	
	util.fillCacheData(me)
	
	if isServ() then
		local ss = string.format('verbose_buy_trap,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,shop_item.type,shop_item.level,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0
end

