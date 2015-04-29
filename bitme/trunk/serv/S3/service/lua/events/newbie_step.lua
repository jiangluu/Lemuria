
function onEvent(me)

	local nkey,step = getUEParams()
	
	if nil==nkey or nil==step then
		error('invalid param')
	end
	
	if nil==me.var.ns then
		me.var.ns = {}
	end
	
	
	local old = me.var.ns[nkey] or 0
	me.var.ns[nkey] = math.max(step,old)
	
	if 'c_res_m'==nkey and step>=1 then
		me.var.ns_pass = 1
	end
	
	
	-- TODO 有些步骤可能给奖励
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'newbie')
		elseif to_add<0 then
			util.dec(me,key,-to_add,'newbie')
		end
	end
	
	if step>0 then
		local reward_key = nkey
		
		local conf = sd.reward[reward_key]
		if conf then
			for i=1,table.getn(conf.detail) do
				local r_type = conf.detail[i].type
				local r_num = conf.detail[i].count
				
				if 0==r_type then
					add_waste('meat',r_num)
				elseif 1==r_type then
					add_waste('elixir',r_num)
				elseif 2==r_type then
					util.add(me,'diamond',r_num,'newbie')
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
			-- 没有奖励正常
		end
	end
	
	
	return 0		
end
