

local function get_max_pow(list)
	--计算全部的pow
	local _pow = 0

	for i = 1 , #list do
		_pow = _pow + list[i].pow
	end
	
	return _pow
end

local function get_match_pow(list , random_pow)
	--匹配合适的区间
	local _pow = 0
	
	for i = 1 , #list do
		local last_pow = _pow
		_pow = _pow + list[i].pow
		
		if random_pow >= last_pow and random_pow <= _pow then
			return i , list[i]
		end
	end

	return -1 , nil
end


local per_day_free_num = 3		-- 每天免费抽3次
local lottery_diamond = 10
local lottery_cd = 300

function onEvent(me)

	local free_or_nonfree = getUEParams()
	
	if nil==me.var.stat_daily.lottery then
		return 1
	end
	
	if nil==me.var.stat_daily.lottery.pool then
		return 1
	end
	
	local need_pay = me.var.stat_daily.lottery.num_free>per_day_free_num
	
	if 0==free_or_nonfree and need_pay then
		return 1
	end
		
	if 0~=free_or_nonfree and (not util.check(me,'diamond',lottery_diamond)) then
		return 1
	end
	
	local lottery_list = me.var.stat_daily.lottery.pool.list
	
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'lottery')
		elseif to_add<0 then
			util.dec(me,key,-to_add,'lottery')
		end
	end
		
	local index = tonumber(me.var.stat_daily.lottery.pool.index)
	local item = me.var.stat_daily.lottery.pool.list[index]
	
	me.cache.lottery_hint = item
	me.cache.lottery_hint_index = index
	
	-- 清空转盘
	me.var.stat_daily.lottery.pool = nil
	
	if 0==free_or_nonfree then
		me.var.stat_daily.lottery.num_free = me.var.stat_daily.lottery.num_free+1
		me.var.stat_daily.lottery.enable_time = l_cur_game_time() + lottery_cd
	else
		util.dec(me,'diamond',lottery_diamond,'lottery')
	end

	
	if item.type==0 then
		add_waste('meat',item.count)
	elseif item.type==1 then
		add_waste('elixir',item.count)
	elseif item.type==2 then
		util.add(me,'diamond',item.count,'lottery')
	elseif item.type==3 then
		util.travalHero(me,function(h)
			if nil~=h.inuse then
				h.stamina = math.min(h.stamina + item.count,100)
				return true
			end
		end)
	elseif item.type==4 then
		util.add_exp_level(me,item.count)
	end
	
	if isServ() then
		ach.key_inc3(me,'lott',1)
	end
	
	util.fillCacheData(me)
	

	return 0
end
