function onEvent(me)
	local bossType = getUEParams()
	
	if nil == bossType then
		error('invalid input param')
	end
	--判断是哪一个人物
	local function get_to_hero(heros)
		for i=1,#heros.list do
			if bossType==heros.list[i].type then
				return heros.list[i]
			end
		end
		return nil 
	end
	local to_hero = get_to_hero(me.hero)
	if nil == to_hero then
		error('invalid input param')
	end
	
	--判断王座等级
	local to_level = 1
	--等级改为与表的键值一致
	local lv_level ="lv1"
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			to_level = m.level
			local to_s = tostring(to_level)
			lv_level = "lv"..to_s
			return true
		end
	end)
	
	-- 扣金丹
	local en = sd.force[lv_level]
	local foo = function(res_key)
		if me.basic[res_key]< en.cost_count then
			alog.debug('not enough res to buy')
			return 1
		end
		util.dec(me,res_key,en.cost_count,'encourage')
		return 0
	end
	
	local suc = 1
	if 0==en.cost_type then
		suc = foo('meat')
	elseif 1==en.cost_type then
		suc = foo('elixir')
	elseif 2==en.cost_type then
		suc = foo('diamond')
	else
		return 1
	end
	
	if 0~=suc then
		return 1
	end
	
	--修改英雄鼓舞的字符串值
	to_hero.encounrage = lv_level
	
	if isServ() then
		ach.key_inc_daily(me,'encounrage',1)
	end
	
	--刷新数据
	util.fillCacheData(me)
	
	return 0
end