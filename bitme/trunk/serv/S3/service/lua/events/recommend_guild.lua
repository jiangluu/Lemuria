function onEvent(me)
	local num = getUEParams()
	
	if nil == num then
		error('invaild param')
	end
	
	if isServ() then
		local fmin = math.max(me.basic.flag - 300,0)
		local fmax = me.basic.flag + 300
		local targetList = guild.get_guild_recommand_list(num,fmin,fmax)
		if nil == targetList then
			error('fetch failed')
		end
		
		local guild_list = {list = {}}
		local length = num
		
		if num > #targetList then
			length = #targetList
		end
		
		for i = 1,length do
			guild_list.list[i] = targetList[i]
		end
		
		local str = box.serialize(guild_list)
		daily.push_data_to_c('guild_list',str)
	end
	
	return 0
end