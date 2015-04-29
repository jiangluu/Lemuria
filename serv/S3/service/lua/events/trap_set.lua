function onEvent(me)
	local map_index,trap_index=getUEParams()
	if nil==map_index or nil==trap_index then 
		error('invalid param')
	end
	
	if isServ() then
		local the_map = me.cache.pvp_copy.map.list[map_index]
		if nil==the_map then
			error('invalid param')
		end
		
		local the_trap = the_map.trap.list[trap_index]
		if nil==the_trap then
			error('invalid param')
		end
		
		--the_trap.o = 1
		if nil==me.inbattle.trap_log then
			me.inbattle.trap_log = {}
		end
		table.insert(me.inbattle.trap_log,{ a=map_index,b=trap_index,aid=the_map.aid })
	end
	
	return 0
end