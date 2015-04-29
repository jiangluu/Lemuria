function onEvent(me)
	
	local res_key = 'meat'
	local res_sum = 0
	
	util.travalPlayerMap(me,function(v)
		if nil~=v.trap then 
			for j=1,#v.trap.list do
				local trap = v.trap.list[j]
				if nil~=trap.o then
					local conf = sd.trap[trap.type].info[trap.level]
					res_sum = res_sum + conf.rp_cost
				end
			end
		end
	end)
	
	if res_sum>0 and (not util.check(me,res_key,res_sum)) then
		return 1
	end
	
	if res_sum<=0 then
		return 0
	end
	
	util.dec(me,res_key,res_sum,'trap_repair')
	
	util.travalPlayerMap(me,function(v)
		if nil~=v.trap then 
			for j=1,#v.trap.list do
				local trap = v.trap.list[j]
				if nil~=trap.o then
					trap.o = nil
				end
			end
		end
	end)
	
	return 0
end