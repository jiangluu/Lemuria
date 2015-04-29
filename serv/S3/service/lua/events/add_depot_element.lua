
function onEvent(me)
		local eleType,num = getUEParams()	-- UE Param means User Event Param			
		if nil==eleType or nil==num then
			return 1
		end		
		if nil==me.depot.list then
			me.depot.list = newArray()
		end	
		for i=1,#me.depot.list do
			if me.depot.list[i].type==eleType then
				me.depot.list[i].num=me.depot.list[i].num+num
				return 0
			end
		end			
		table_insert(me.depot.list,{type=eleType,num=tonumber(num)})
	return 0
end