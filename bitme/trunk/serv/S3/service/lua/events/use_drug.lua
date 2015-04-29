function onEvent(me)
	local drugType = getUEParams()
	
	if nil == drugType then
		error('invalid param')
	end
	
	local index = 0
	
	if nil ~= me.var.drug.list then
		for i = 1,#me.var.drug.list do
			if drugType == me.var.drug.list[i].type then
				index = i
			end
		end
	end
	
	if 0 == index then
		error('not here')
	end
	
	table_remove(me.var.drug.list,index)
	
	if isServ() then
		ach.key_inc_daily(me,'used_potion',1)
		ach.key_inc4(me,'use_drug_'..drugType)
	end
	
	return 0
end