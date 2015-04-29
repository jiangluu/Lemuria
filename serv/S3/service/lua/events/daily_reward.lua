
function onEvent(me)
	local index = getUEParams()	-- UE Param means User Event Param
	
	index = tonumber(index)
	
	if nil==me.addition.daily.list[index] then
		error('invalid key')
	end
	
	if 1~=tonumber(me.addition.daily.list[index].stat) then
		-- 成就当前不是1的状态，客户端被黑了
		error('invalid stat')
	end
	
	local conf = sd.daily[me.addition.daily.list[index].id]
	if nil==conf then
		error('invalid id')
	end
	
	
	local dd = me.addition.daily.list[index]
	if dd.mc then		-- 月卡
		if nil==me.addition.daily.mc_time or me.addition.daily.mc_time<l_cur_game_time() then
			error('invalid yueka')
		end
	end
	
	-- 改成状态2
	dd.stat = 2
	
	
	-- 给奖励
	local res_key = 'meat'
	if 1==conf.reward_type then
		res_key = 'elixir'
	elseif 2==conf.reward_type then
		res_key = 'diamond'
	end
	
	if conf.reward_count < 1 then
		util.add(me,res_key,conf.reward_count*me.basic[res_key..'_limit'],'daily')
	else
		util.add(me,res_key,conf.reward_count,'daily')
	end
	
	
	--加经验
	util.add_exp_level(me,conf.exp)
	
	util.fillCacheData(me)
	
	
	return 0
end

