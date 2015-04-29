function onEvent(me)
	local other = getUEParams()
	local my = me.basic.usersn
	
	if nil == my or nil == other then
		error('invalid param')
	end
	
	local id = nil
	if nil == me.basic.guild then
		return 1
	else
		id = me.basic.guild.id
	end
	
	if isServ() then
			--取公会成员信息
		local member = guild.get_all_member(id)
		
	
			--取双方职位及位置
		local myPosition = 0
		local myList = nil
		local myLocal = 0
		local otherList = nil
		local otherLocal = 0
		
		for i = 1,#member do
			if my == member[i].usersn then
				myList = member[i]
				myPosition = member[i].position
				myLocal = i
			elseif other == member[i].usersn then
				otherList = member[i]
				otherLocal = i
			end
		end
		
		if 1 ~= myPosition or nil == otherList then
			error('not here')
		end
		
			--修改双方职位并保存
		myList.position = 2
		otherList.position = 1
		guild.set_member(id,myLocal,myList)
		guild.set_member(id,otherLocal,otherList)
	end
	
	return 0
end