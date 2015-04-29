
function onEvent(me)
	local map_index = getUEParams()	-- UE Param means User Event Param
	
	if nil==map_index then
		error('invalid input param')
	end
	
	-- logic part, some code here
	local ta_map = me.map.list[map_index]
	if nil==ta_map then
		error('invalid input param map_index')
	end
	
	-- 扣钱
	local conf = sd.scene[ta_map.type]
	if nil==conf then
		error('sd not found')
	end
	
	if nil==conf.detail then
		error('detail not found')
	end
	
	
	-- 检查是否级别已经到顶不能升级了
	local upgrade_info = conf.detail[ta_map.level+1]
	if nil==upgrade_info then
		error(string.format('detail not found at %s level %d',ta_map.type,ta_map.level+1))
	end
	
	if nil~=conf.limit then
		local to_level = 1	-- 王座等级
		util.travalPlayerMap(me,function(m) if 'to'==m.type then to_level=m.level end end)
		local to_limit = conf.limit[to_level]
		if nil==to_limit then
			error('conf.limit not found')
		end
		
		if ta_map.level+1 > to_limit.limit_level then
			alog.debug('need higher TO')
			return 1
		end
	end
	
	local count1 = 0
	local worker = nil
	util.travalPlayerMob(me,function(mob,map)
		if 'lm'==mob.type and (nil==mob.next_enable_time or l_cur_game_time()>mob.next_enable_time) then
			count1 = count1+1
			worker = mob
			return true
		end
	end)
	
	if count1<1 then
		alog.debug('not enough lm')
		return 1
	end
	
	local foo = function(res_key)
		if me.basic[res_key]<upgrade_info.cost_count then
			alog.debug('not enough res to upgrade')
			return 1
		end
		
		util.dec(me,res_key,upgrade_info.cost_count,'upg_map')
		
		return 0
	end
	
	local suc = 1
	if 0==upgrade_info.cost_type then
		suc = foo('meat')
	elseif 1==upgrade_info.cost_type then
		suc = foo('elixir')
	else
		suc = foo('diamond')
	end
	
	
	if 0~=suc then
		return 1
	end
	
	
	if 'hf'==ta_map.type or 'fn'==ta_map.type then
		RG.RGCreasteLog(me)
	end
	
	
	-- 钱扣了，升级
	ta_map.level = ta_map.level + 1
	
	-- 如果是王座升级，改英雄等级
	if 'to'==ta_map.type then
		for i=1,#me.hero.list do
			local hh = me.hero.list[i]
			hh.level = ta_map.level
		end
		
		util.travalPlayerMap(me,function(m)
			local conf = sd.scene[m.type]
			if conf and 'to'==conf.level_dep then
				m.level = ta_map.level
			end
		end)
		
		if isServ() then
			yylog.log(string.format('levelup-to,usersn%d,%d',me.basic.usersn,ta_map.level))
		end
	end
	
	util.travalPlayerMob(me,function(mm,map)
		local mob_conf = sd.creature[mm.type]
		if nil~=mob_conf.auto_levelup then
			mm.level = map.level
		end
	end)
	
	--判断是不是升级送怪的地块
	local list = sd.scene[ta_map.type]['detail'][ta_map.level]
	
	if nil ~= list.get_monster then	
		local mobLevel = 1

		if nil ~= me.var.research[list.get_monster] then
			mobLevel = me.var.research[list.get_monster]
		end

		for i = 1,list.get_count do
			table_insert(ta_map.mob.list,{type=list.get_monster,level=mobLevel,num=1})
		end
	end
	
	-- 占用一个开山怪
	util.worker_into_cd(worker,upgrade_info.time)
	
	if 'bs'==ta_map.type then
		util.updateHeroEquip(me)
	end
	
	--加经验
	util.add_exp_level(me,upgrade_info['exp'])
	
	
	util.fillCacheData(me)
	
	if isServ() then
		local ss = string.format('verbose_upgrade_map,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,ta_map.type,ta_map.level,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0
end

