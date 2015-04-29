-- 假设是放一个地块
function onEvent(me)
	local shop_hash,x,y,direction = getUEParams()	-- UE Param means User Event Param
	
	if nil==shop_hash or nil==x or nil==y or nil==direction then
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
	
	if shop_item.has >= shop_item.limit then
		error('has too much')
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
		
		util.dec(me,res_key,shop_item.cost,'map')
		
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
	
	
	if 'hf'==shop_item.type or 'fn'==shop_item.type then
		RG.RGCreasteLog(me)
	end
	
	
	-- 增加地块
	local r = util.addMap(me,shop_item.type,x,y,direction)
	if not r then
		alog.debug('put map failed')
		return 1
	end
	-- 看看有没有买建筑送怪
	local conf = sd.scene[shop_item.type]
	if conf and conf.get_monster then
		local new_map = me.map.list[#me.map.list]	-- the last one should be the new one
		new_map.mob = {}
		util.makesureListExists(new_map.mob)
		
		local level = me.var.research[conf.get_monster] or 1
		table_insert(new_map.mob.list,{type=conf.get_monster,level=level,num=1})
	end
	
	-- 使一个怪睡觉
	util.worker_into_cd(lm,shop_item.time)
	
	-----加经验
	util.add_exp_level(me,sd.shop.map[shop_item.type][1].exp)
	
	util.fillCacheData(me)
	
	if 'bs'==shop_item.type then
		util.updateHeroEquip(me)
	end
	
	
	if isServ() then
		local ss = string.format('verbose_buy_map,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,shop_item.type,1,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0
end

