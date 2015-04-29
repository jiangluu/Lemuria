function onEvent(me)
	local id = getUEParams()
	
	if nil == id then
		error('invalid param')
	end
	
	if nil ~= me.basic.guild then
		error('have guild')
	end
	
	if isServ() then
		if not ownership.is_mine(me.basic.usersn,me.cache.session) then
			error('session expired')
		end
	
		local member = guild.get_all_member(id)
		
		if nil == member then
			error('fetch failed')
		end
		
			--判断公会人数和申请人数是否达上限
		local num = 0
		local applyNum = 0
		
		for i = 1,#member do
			if nil == member[i].join_time then
				applyNum = applyNum + 1
			elseif nil == member[i].leave_time then
				num = num + 1
			end
		end
		
		if num >= 50 or applyNum >= 50 then
			return 2
		end
			--看看是否是已离开为超过24小时成员
		for i = 1,#member do
			if me.basic.usersn == member[i].usersn then
				if nil ~= member[i].leave_time and l_cur_game_time() - member[i].leave_time >= 86400 then
					table.remove(member,i)
				else
					return 4
				end
			end
		end
		
		local basic = guild.get_guild(id)
		
		if nil == basic then
			error('fetch failed')
		end
		
		print(basic.need_flag,me.basic.flag)
		if me.basic.flag < basic.need_flag then
			return 3
		end
		
		if 0 == basic.join_way then
		--判断旗子数			
			local v = {usersn = me.basic.usersn,name = me.basic.name,join_time = l_cur_game_time(),flag = me.basic.flag,exp = me.basic.exp,position = 4}
			
			if nil == guild.add_new_member(id,v) then
				error('add failed')
			end
			
			me.basic.guild = {}
			me.basic.guild.id = id			
			me.basic.guild.name=basic.name
			me.basic.guild.mark=basic.mark
			me.basic.guild.pos=4
			me.basic.guild.join_time=l_cur_game_time()
			guild.update_guild(id)
			
			local ss = box.serialize(me.basic.guild)
			daily.push_data_to_c('basic.guild',ss)			
			guild.on_has_guild(me)
			
			v.type = 'join'
			v.stat = 2	
			v.pos=4
			guild.publish_msg(id,1,box.serialize(v))
		elseif 1 == basic.join_way then	
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
					if tar and 'join'==tar.type  and me.basic.usersn==tar.usersn and nil~=tar.stat and tar.stat==1 then
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
			
			local tt = {type='join',tim=l_cur_game_time(),usersn=me.basic.usersn,name=me.basic.name,flag=me.basic.flag,exp = me.basic.exp,stat=1}		
			tt.pos=-1
			guild.publish_msg(id,1,box.serialize(tt))
			
		else
			return 1
		end
		
		box.do_save_player(me)
		
	end
	
	return 0
end