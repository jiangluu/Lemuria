function onEvent(me)
	local id,indexStart,indexEnd = getUEParams()
	
	if nil == id or nil == indexStart or nil == indexEnd then	
		error('invaild param')
	end
	
	if isServ() then
		local member = guild.get_all_member(id)
		if nil == member then
			error('fetch failed')
		end
		
		table.sort(member,function(a,b)
			return a.flag>b.flag
		end)
		
		
			--清除离开和正审核的
		local leave = 0
		local newMember = {list = {}}
		
		for i = 1,#member do 
			if nil ~= member[i].leave_time or nil == member[i].join_time then
				leave = leave + 1
			else
				newMember.list[i - leave] = member[i]
			end
		end
		
			--分页
		local newList = {list = {}}
		if #newMember.list >= indexEnd then
			for i = 1,indexEnd - indexStart + 1 do
				newList.list[i] = newMember.list[indexStart - 1 + i]
				if newList.list[i].usersn==me.basic.usersn then
					newList.list[i].exp=me.basic.exp
				end				
				newList.list[i].level=((25+((625-100*(-newList.list[i].exp)))^0.5)/50)
				
			end
		elseif #newMember.list >= indexStart then
			for i = 1,#newMember.list - indexStart + 1 do
				newList.list[i] = newMember.list[indexStart - 1 + i]
				if newList.list[i].usersn==me.basic.usersn then
					newList.list[i].exp=me.basic.exp
				end
				newList.list[i].level=((25+((625-100*(-newList.list[i].exp)))^0.5)/50)
			end
		end
		
		local str = box.serialize(newList)
		daily.push_data_to_c('guild_member',str)
		
		
		for i=1,#member do
			if me.basic.usersn==member[i].usersn then							
				local str_pos = box.serialize(member[i])
				daily.push_data_to_c('cache.my_guild_info',str_pos)
				break
			end
		end
		
	end
	
	return 0
end