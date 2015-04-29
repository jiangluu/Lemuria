
function onEvent(me)
	local index,key = getUEParams()
	
	index = tonumber(index)
	if nil==index or nil==key then
		error('invalid param')
	end
	
	if 1~=me.addition.story.list[index].stat then
		return 1
	end
	
	
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'story_reward')
		elseif to_add<0 then
			util.dec(me,key,-to_add,'story_reward')
		end
	end
	
	
	local conf = sd.reward[key]
	if conf then
		me.addition.story.list[index].stat = 2
		
		for i=1,table.getn(conf.detail) do
			local r_type = conf.detail[i].type
			local r_num = conf.detail[i].count
			if util.has_housekeeper(me) then
				r_num = conf.detail[i].count_vip1
			end
			
			if 0==r_type then
				add_waste('meat',r_num)
			elseif 1==r_type then
				add_waste('elixir',r_num)
			elseif 2==r_type then
				util.add(me,'diamond',r_num,'story_reward')
			elseif 3==r_type then
				util.travalHero(me,function(h)
					if nil~=h.inuse then
						h.stamina = math.min(h.stamina + r_num,100)
						return true
					end
				end)
			elseif 4==r_type then
				util.add_exp_level(me,r_num)
			end
		end
	else
		return 2
	end
	
	
	util.fillCacheData(me)
	
	
	return 0		
end
