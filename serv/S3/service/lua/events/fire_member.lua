function onEvent(me)
	local other = getUEParams()
	local my = me.basic.usersn
	local id = nil
	if nil == my or nil == other then
		error('invaild param')
	end
	
	if nil ~= me.basic.guild then
		id = me.basic.guild.id
	else
		error('have no guild')
	end

	if isServ() then
		local member = guild.get_all_member(id)
		local target = nil
		local myPosition = 0
		local otherPosition = 0
		local otherLocal = 0
	
		if nil == member then
			error('fetch failed')
		end
		
			--查找双方，并记录职位
		for i = 1,#member do
			if nil == member[i].leave_time and nil ~= member[i].join_time then
				if my == member[i].usersn then
					myPosition = member[i].position
				elseif other == member[i].usersn then
					target = member[i]
					otherPosition = member[i].position
					otherLocal = i
				end
			end
		end
		
		if 0 == myPosition or 0 == otherPosition then
			error('have no member')
		end
		
			--取权限比较判断
		if nil == sd.guild['a' .. myPosition]['power']['set_member_fire'] or otherPosition <= myPosition then
			return 1
		end
			--满足权限,标记该成员字段
		target.leave_time = l_cur_game_time()
		guild.set_member(id,otherLocal,target)			
		
		local tt = {type='prompt',tim=l_cur_game_time(),usersn=other,name=me.basic.name,name2=target.name,stat=4}		
		guild.publish_msg(id,1,box.serialize(tt))
		
		
		---删除对应的申请支援记录
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
				if tar and 'apply'==tar.type  and other==tar.usersn then
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
		
		
		local otherObj={type='fire_member',firetime=l_cur_game_time()}
		box.send_todo(other,otherObj)
		
			--刷新数据
		guild.update_guild(id)
	end	
	return 0
end

if isServ() then
	box.reg_todo_handle('fire_member',function(me,dd)
		me.basic.guild=nil			
		print(l_cur_game_time(),dd.firetime,l_cur_game_time()-dd.firetime)
		if l_cur_game_time()-dd.firetime<500 then			
			daily.push_data_to_c('basic',box.serialize(me.basic))
		end	
		return 0	
	end)	
end
