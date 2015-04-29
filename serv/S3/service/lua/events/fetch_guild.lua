function onEvent(me)
	local id = getUEParams()
	
	if nil == id then
		error('invaild params')
	end
	
	if isServ() then
		-- 有概率更新数据
		local random_number = math.random(1,10)
		if 1==random_number then
			guild.update_guild(id)
		end
		
	
		local targetGuild = {}
		targetGuild.basic = guild.get_guild(id)
		targetGuild.member = guild.get_all_member(id)
		
		if nil == targetGuild.basic or nil == targetGuild.member then
			error('fetch failed')
		end
		
		local str1 = box.serialize(targetGuild.basic)
		local str2 = box.serialize(targetGuild.member)
		daily.push_data_to_c('guild_basic',str1)
		daily.push_data_to_c('guild_member',str2)
	end
	
	return 0
end