
function onEvent(me)
	local index = getUEParams()
	
	if isServ() then
		if nil==index then
			error('invalid param')
		end
		
		if nil==me.var.stat_daily.story_r then
			me.var.stat_daily.story_r = {}
		end
		
		local old = me.var.stat_daily.story_r[index]
		if nil~=old then
			return 1
		end
		
		local id_pool = {}
		-- 滤出可用id
		local need_unlock = nil
		local aa = string.match(index,'%a+(%d+)')
		if nil==aa then
			error('invalid param')
		end
		local pattern1 = string.format('d_lv%02d',aa)
		for k,v in pairs(sd.raid) do
			if string.match(k,pattern1) then
				table.insert(id_pool,{id=k,weight={v.weight,v.ref1_weight,v.ref2_weight}})
				
				need_unlock = v.unlock_conditions
			end
		end
		
		if #id_pool<=0 then
			error('raid id filter invalid')
		end
		
		local need_unlock_id = tonumber(string.match(need_unlock,'raid_id_(%d+)'))
		if nil==need_unlock_id then
			error('unlock_conditions invalid')
		end
		
		if #me.addition.story.list < need_unlock_id then
			return 1
		end
		
		local today_random_times = 1
		today_random_times = math.min(today_random_times,3)
		local weight_sum = 0
		for i=1,#id_pool do
			weight_sum = weight_sum + (id_pool[i].weight[today_random_times] or 0)
		end
		
		local rand = math.random(0,weight_sum-1)
		local ww = 0
		local oo = nil
		for i=1,#id_pool do
			ww = ww + (id_pool[i].weight[today_random_times] or 0)
			if rand<ww then
				oo = id_pool[i]
				break
			end
		end
		
		if nil==oo then
			return 1
		end
		
		me.var.stat_daily.story_r[index] = {name=oo.id}
		
		local bin = box.serialize(me.var.stat_daily.story_r)
		daily.push_data_to_c('cache.story_r',bin)
	end
	
	return 0		
end
