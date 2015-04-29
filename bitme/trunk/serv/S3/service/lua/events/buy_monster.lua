-- 假设是买怪
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
	
	if shop_item.has >= shop_item.limit then
		error('has too much')
	end
	
	local mob_conf = sd.creature[shop_item.type]
	if nil==mob_conf then
		error('invalid creature')
	end
	
	
	local lm = nil
	if 0~=mob_conf.buycheck then
		util.travalPlayerMob(me,function(m,map)
			if 'lm'==m.type and (nil==m.next_enable_time or l_cur_game_time()>m.next_enable_time) then
				lm = m
				return true
			end
		end)
		if nil==lm then
			error('no lm')
		end
	end
	
	-- 扣钱
	local foo = function(res_key)
		if me.basic[res_key]<shop_item.cost then
			alog.debug('not enough res to buy')
			return 1
		end
		
		util.dec(me,res_key,shop_item.cost,'monster')
		
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
	-----加经验
	util.add_exp_level(me,sd.shop.monster[shop_item.type][shop_item.level].exp)
	
	-- 增加怪
	
	local count1 = 0
	local ll = {}
	local log_lv = 1
	if string.match(mob_conf.type,'^w%-') or string.match(mob_conf.type,'^s%-') then
		for idx=1,#me.map.list do
			local m = me.map.list[idx]
			if m.type == mob_conf.build then
				if nil==m.mob then
					m.mob = {}
					m.mob.list = newArray()
				end
				
				-- local count2 = 0
				-- for j=1,#m.mob.list do
					-- local ee = m.mob.list[j]
					-- if ee.type==shop_item.type and ee.level==shop_item.level then
						-- ee.num = ee.num+1
						-- count2 = 1
						-- break
					-- end
				-- end
				-- if count2<=0 then
					-- table_insert(m.mob.list,{type=shop_item.type,level=shop_item.level,num=1})
				-- end
				
				-- table_insert(m.mob.list,{type=shop_item.type,level=shop_item.level,num=1})
				
				-- me.cache.new_monster_at = idx
				-- count1 = 1
				
				table.insert(ll,{index=idx,level=m.level,num=#m.mob.list,pop_all=sd.scene[m.type].detail[m.level].population })
			end
		end
	end
	count1 = #ll
	if count1>0 then
		table.sort(ll,function(a,b)
			return (a.pop_all-a.num)>(b.pop_all-b.num)
		end)
		
		local m = me.map.list[ll[1].index]
		local lv = shop_item.level
		if nil~=mob_conf.auto_levelup then
			lv = m.level
		end
		log_lv = lv
		table_insert(m.mob.list,{type=shop_item.type,level=lv,num=1})
		me.cache.new_monster_at = ll[1].index
	else
		-- 没有根据build匹配到合适的工作建筑，那么是英雄或者战斗怪？
		log_lv = shop_item.level
		if 'hero'==mob_conf.type then
			table_insert(me.hero.list,{type=shop_item.type,level=shop_item.level})
		elseif 'monster'==mob_conf.type or 'chief'==mob_conf.type then
			util.addToLobby(me,{type=shop_item.type,level=shop_item.level,num=1})
		end
	end
	
	-- 使一个怪睡觉
	if 0~=mob_conf.buycheck then
		util.worker_into_cd(lm,shop_item.time)
	end
	util.fillCacheData(me)
	
	if isServ() then
		local ss = string.format('verbose_buy_monster,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,shop_item.type,log_lv,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	-- output part
	return 0
end

