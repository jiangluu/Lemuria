
function onEvent(me)
	local composite_key = getUEParams()	-- UE Param means User Event Param
	
	-- composite_key应该是 1_1 这样的
	if nil==me.addition.achieve[composite_key] then
		error('invalid key')
	end
	
	if 1~=tonumber(me.addition.achieve[composite_key].stat) then
		-- 成就当前不是1的状态，客户端被黑了
		error('invalid stat')
	end
	
	local a1,a2 = string.match(composite_key,'(%d+)_(%d+)')
	a1 = tostring(a1)
	
	local v = sd.achieve[a1]
	
	-- 改成状态2
	me.addition.achieve[composite_key].stat = 2
	
	-- 给奖励
	util.add(me,'diamond',v.info[tonumber(a2)].reward_count,'achieve')
	--加经验
	util.add_exp_level(me,v.info[tonumber(a2)]['exp'])
	
	return 0
end

