function onEvent(me)
	
	local types = getUEParams()
	if nil==types then
		error('invaild param')
	end
	local array=nil
	local state=nil
	if types=='sign' then
		local sign_count=me.addition.daily.sign2
		array=sd.sign['sign_'..sign_count].reward
		state=me.var.stat_daily.sign
	elseif types=='newBee' then
		local sign_count=me.addition.daily.newbeeSign2
		array=sd.reward['e_newbee_7sign_'..sign_count].detail
		state=me.var.stat_daily.newbeeSign
	elseif types=='calendar' then
		print(me.addition.daily.calendar2)
		local sign_count=me.addition.daily.calendar2		
		array=sd.reward['e_sign25_'..sign_count].detail
		state=me.var.stat_daily.calendar
	end
	
	if nil==array or nil==state or 1~=state then
		return 1
	end
	
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'sign_reward')
		elseif to_add<0 then
			util.dec(me,key,-to_add,'sign_reward')
		end
	end
	
	for i=1,table.getn(array) do
		if array[i].type==0 then
			add_waste('meat',array[i].count)
		elseif array[i].type==1 then
			add_waste('elixir',array[i].count)
		elseif array[i].type==2 then
			util.add(me,'diamond',array[i].count,'sign_reward')
		elseif array[i].type==3 then
			util.travalHero(me,function(h)
				if nil~=h.inuse then
					h.stamina = math.min(h.stamina + array[i].count,100)
					return true
				end
			end)
		elseif array[i].type==4 then
			util.add_exp_level(me,array[i].count)
		end
	end
	if types=='sign' then
		me.var.stat_daily.sign=2	
		me.addition.daily.sign2=me.addition.daily.sign2+1
	elseif types=='newBee' then
		me.var.stat_daily.newbeeSign=2	
		me.addition.daily.newbeeSign2=me.addition.daily.newbeeSign2+1
	elseif types=='calendar' then
		me.var.stat_daily.calendar=2	
		me.addition.daily.calendar2=me.addition.daily.calendar2+1
	end
	
	util.fillCacheData(me)
	
	return 0
end
