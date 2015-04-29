function onEvent(me)
	local mark,info,join_way,need_flag = getUEParams()

	if nil == mark or nil == info or nil == join_way or nil == need_flag  then
		error('invalid params')
	end

	if nil == me.basic.guild then
		error('have no guild')
	end
	
	local usersn=me.basic.usersn	
	if isServ() then
			--获取玩家职位及公会信息
		local id = me.basic.guild.id
		local basic = guild.get_guild(id)
		local member = guild.get_all_member(id)
		local position = 4
		for i = 1,#member do
			if usersn == member[i].usersn then
				position = member[i].position
				break
			end
		end
			--读表获取权限信息
		local function judge(position,key)
			if 1 == sd.guild['a' .. position]['power']['change_guild_' .. key] then
				return true
			else
				return false
			end
		end
		
		
		if  false == judge(position,'mark') then
			return 1
		elseif  false == judge(position,'info') then
			return 1
		elseif   false == judge(position,'jointype') then
			return 1
		elseif  false == judge(position,'needflag') then
			return 1
		end
		
		
			
		if mark~=basic.mark then
			for i = 1,#member do
				if usersn ~= member[i].usersn then
					local mem={}			
					mem.type = 'updateMark'							
					mem.mark=mark					
					box.send_todo(member[i].usersn,mem)
				end
			end					
		end
		
		--满足权限进行修改
		basic.mark = mark
		basic.info = info
		basic.join_way = join_way
		basic.need_flag = need_flag		
		guild.set_guild(id,basic)
		
	end	
	me.basic.guild.mark=mark
	return 0
end



if isServ() then
	box.reg_todo_handle('updateMark',function(me,mem)
		if nil==me.basic.guild then
			return 0
		end
		me.basic.guild.mark=mem.mark
		return 0
	end)	
end
