function onEvent(me)
	local map_list,trap_list=getUEParams()
	
	if nil==map_list or nil==trap_list then 
		error('invalid param')
	end
	
	local the_map = me.map.list[map_list]
	if nil==the_map then
		error('invalid param')
	end
	
	local the_trap = the_map.trap.list[trap_list]
	if nil==the_trap then
		error('invalid param')
	end
	
	local conf = sd.trap[the_trap.type].info[the_trap.level]
	
	if not util.check(me,'meat',conf.rp_cost) then
		return 1
	end
	
	util.dec(me,'meat',conf.rp_cost,'trap_repair')
	the_trap.o = nil
	
	return 0	
end