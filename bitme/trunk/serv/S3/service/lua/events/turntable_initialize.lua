
local cur_count = 0

local function add_item(list , item)
	table.insert(list , item)
	cur_count = cur_count + 1
end

local function remove_item(list , index)
	table.remove(list , index)
end

local function remove_same_item(list , group)
	for i = #list , 1 , - 1 do
		local item = list[i]
		if item.group ~= nil and item.group == group then
			remove_item(list , i)
		end
	end
end

local function get_max_pow(list)
	--计算全部的pow
	local _pow = 0

	for i = 1 , #list do
		_pow = _pow + list[i].pow
	end
	
	return _pow
end

local function get_max_show_pow(list)
	--计算全部的pow
	local _show_pow = 0

	for i = 1 , #list do
		_show_pow = _show_pow + list[i].show_pow
	end
	
	return _show_pow
end

local function get_match_pow(list , random_pow)
	--匹配合适的区间
	local _pow = 0
	
	for i = 1 , #list do
		local last_pow = _pow
		_pow = _pow + list[i].pow
		
		if random_pow > last_pow and random_pow <= _pow then
			return i , list[i]
		end
	end

	return -1 , nil
end

local function get_match_show_pow(list , random_pow)
	--匹配合适的区间
	local _show_pow = 0
	
	for i = 1 , #list do
		local _last_show_pow = _show_pow
		_show_pow = _show_pow + list[i].show_pow
		
		if random_pow > _last_show_pow and random_pow <= _show_pow then
			return i , list[i]
		end
	end

	return -1 , nil
end


local pool_item_count = 8		-- 转盘上是8个东西

function onEvent(me)

	cur_count = 0

	if isServ() then
		if nil==me.var.stat_daily.lottery then
			-- 新的一天初始化
			me.var.stat_daily.lottery = {}
			me.var.stat_daily.lottery.num = 1
			me.var.stat_daily.lottery.num_free = 1
		end
		
		
		if nil==me.var.stat_daily.lottery.pool then

			local lottery_item = nil
			table.travel_sd(sd.lottery,function(t,k)
				local item = t[k]		
				if me.var.stat_daily.lottery.num >= item.count then
					lottery_item = item
				else
					return true
				end
			end)
			
			if nil==lottery_item then
				return 1
			end
			
			local list = table.deepclone(lottery_item.item)
			local must_list = {}
			
			
			for i = #list , 1 , - 1 do
				local item = list[i]
				if item.must ~= nil and item.group == nil then
					add_item(must_list , item)
					remove_item(list , i)
				end
			end
			
			
			for safer = 1,9999 do
				if cur_count>=pool_item_count then
					break
				end
				
				if(#list == 0) then
					error('invalid param')
					break
				end
			
				local index , item = get_match_pow(list , math.random(1 , get_max_pow(list)))
				
				if(index == -1 or item == nil) then
					error('invalid param')
					break
				end
				
				local group = item.group
				add_item(must_list , item)
				
				if(group == nil) then
					remove_item(list ,index)
				else
					remove_same_item(list , group)
				end
			end
				
			local to_level = 1
			util.travalPlayerMap(me,function(m)
				if 'to'==m.type then
					to_level = m.level
					return true
				end
			end)
			
			
			local ret = { list = {} }
			
			for i = 1 , #must_list do
				local item = must_list[i]
				
				local lottery_count_item = sd.lotterycount['type_'..item.type].item
				
				local t = {}
				
				for i = 1 , table.getn(lottery_count_item)  do
					if lottery_count_item[i].to_lvl == to_level then
						table.insert(t , table.deepclone(lottery_count_item[i]))
					end
				end
				
				local index , item = get_match_show_pow(t , math.random(1 , get_max_show_pow(t)))
				table.insert(ret.list,item)
			end
			
			ret.list = table.shuffle_array(ret.list)
			
			print('turntable list num',#ret.list)
			ret.pow = get_max_pow(ret.list)
			ret.rand = math.random(1 , ret.pow)
			
			local index , item = get_match_pow(ret.list ,ret.rand)
			ret.index = index
			
			
			me.var.stat_daily.lottery.pool = ret
			me.var.stat_daily.lottery.num = me.var.stat_daily.lottery.num + 1
		end
		
		daily.push_data_to_c('var.stat_daily' , box.serialize(me.var.stat_daily))
		daily.push_data_to_c('cache.lottery' , box.serialize(me.var.stat_daily.lottery.pool))
		
	end
	
	return 0
end
