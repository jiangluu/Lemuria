function onEvent(me)
	local my = me.basic.usersn
	
	if nil == my then
		error('invalid param')
	end
	
	local id = nil
	if nil == me.basic.guild then
		return 1
	else
		id = me.basic.guild.id
	end
	local other_name=nil
	if isServ() then
			--获取公会成员信息及本人信息
		local member = guild.get_all_member(id)
		
		if nil == member then
			error('fetch failed')
		end
		
		local myList = nil
		local myPosition = 0
		local myLocal = 0
		
		for i = 1,#member do
			if my == member[i].usersn then
				myList = member[i]
				myPosition = member[i].position
				myLocal = i
				break
			end
		end
		
		if 0 == myPosition then
			error('not here')
		end
		local tar=nil
		
		
		
		if 1 == #member then --假如公会只有一个人			
			guild.remove_guild(id)	
			
		else		
			local count=0			
			for i=1,#member do
				if nil == member[i].leave_time then					
					count=count+1
				end
			end
			
			if count<=1 then
				guild.remove_guild(id)
				me.basic.guild = nil		
				local ss = box.serialize(me.basic)
				daily.push_data_to_c('basic',ss)
				return 0
			end
			if 1 == myPosition then --如果是会长要禅让
						--找出某个群体合适继承的成员函数
					local function judge(list)
						local target = nil
						local flag = -1
						local joinTime = 0
						
						for i = 1,#list do
							if list[i].flag > flag or (list[i].flag == flag and list[i].join_time < joinTime)then
								target = list[i]
								flag = list[i].flag
								joinTime = list[i].join_time
							
							end
						end
						other_name=target.name
						return target.usersn
					end
					
						--分出更等级成员的列表
					local list1 = {}
					local list2 = {}
					local list3 = {}	
						
					for i = 1,#member do
						if nil == member[i].leave_time then
							if 2 == member[i].position then
								list1[#list1 + 1] = member[i]
							elseif 3 == member[i].position then
								list2[#list2 + 1] = member[i]
							elseif 4 == member[i].position then
								list3[#list3 + 1] = member[i]
							end
						end
					end
					
						--查找合适人选
					local usersn = nil	
					
					if 0 ~= #list1 then
						usersn = judge(list1)					
					elseif 0 ~= #list2 then
						usersn = judge(list2)					
					else
						usersn = judge(list3)				
					end
						--设定该成员为会长
					if nil ~= usersn then
						for i = 1,#member do
							if usersn == member[i].usersn then
								member[i].position = 1
								local num=guild.set_member(id,i,member[i])							
								tar=member[i];
								break
							end
						end
					else
						error('judge wrong')
					end
					 
					if nil ~= usersn then
						local tt = {type='prompt',tim=l_cur_game_time(),usersn=usersn,name=other_name,name2=me.basic.name,stat=5}		
						guild.publish_msg(id,1,box.serialize(tt))
					end
					
					local object={type='set_position_1',pos=1,guildid=id}
					box.send_todo(usersn,obj)
								
			end
			
				--更改字段，刷新数据		
			--更改字段，刷新数据
			myList.leave_time = l_cur_game_time()
			myList.position = nil
			guild.set_member(id,myLocal,myList)
			guild.update_guild(id)
			---删除我的申请支援记录
			local begin = 1
			local step = 20	
			for limiter=1,999 do
				local chat_list = guild.pull_msg2(id,1,begin,begin+step)
				begin = begin+step				
				if not chat_list then
					break
				end
				local isfind=false
				for i=1,#chat_list do
					local tar = box.unSerialize(chat_list[i])
					if tar and 'apply'==tar.type  and me.basic.usersn==tar.usersn then
						isfind=true										
						guild.del_msg(id,1,i+begin-step-1)						
						break
					end
				end
				
				if #chat_list<step then
					break
				end
				if true==isfind then
					break
				end
			end			
			local tt = {type='prompt',tim=l_cur_game_time(),usersn=me.basic.usersn,name=me.basic.name,stat=1}		
			guild.publish_msg(id,1,box.serialize(tt))
			
		end
		me.basic.guild = nil		
		local ss = box.serialize(me.basic)
		daily.push_data_to_c('basic',ss)
	end
	
	return 0
end


if isServ() then
	box.reg_todo_handle('set_position_1',function(me,dd)	
		if nil==me.basic.guild then
			return 0
		end
		if dd.guildid~= me.basic.guild.id then
			return 0
		end		
		me.basic.guild.pos=dd.pos
	end)
end