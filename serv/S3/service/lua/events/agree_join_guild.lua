
function onEvent(me)
	local ta_usersn,tim,agree_or_refuse = getUEParams()
	
	if nil == ta_usersn or nil == tim or nil==agree_or_refuse then
		error('invalid param')
	end
	
	if nil == me.basic.guild then
		error('have no guild ')
	end
	
	local guild_id = me.basic.guild.id
	
	
	if isServ() then	
		local basic = guild.get_guild(guild_id)		
		if nil==basic then 
			return 1
		end
		
		if basic.num>=50 then 
			return 1
		end
		
		local begin = 1
		local step = 20	
		
		local function commit_join(v,bin,index)
			
			local new_member = deepCloneTable(v)			
			
			local member=deepCloneTable(v)
			member.stat=4
			member.name2=me.basic.name			
			guild.publish_msg(guild_id,1,box.serialize(member))			
			guild.modify_msg(guild_id,1,index,bin)				
			local mem={type='join_is_success',new_member=new_member,guild_id=guild_id}			
			box.send_todo(v.usersn,mem)
		end
		
		local function commit_refuse(v,bin)
			guild.command_and_wait('LREM %s %s %b','gla'..guild_id,'-1',bin,ffi.cast('size_t',#bin))			
			v.stat = 3
			v.tim = l_cur_game_time()
			v.name2 = me.basic.name
			guild.publish_msg(guild_id,1,box.serialize(v))
		end
		
		
		local other_flag=nil
		for safer=1,1000 do
			local chat_list = guild.pull_msg2(guild_id,1,begin,begin+step)
			begin = begin+step
			
			if not chat_list then
				break
			end
			
			for i=1,#chat_list do
				local tt = box.unSerialize(chat_list[i])
				if tt and 'join'==tt.type and 1==tt.stat and ta_usersn==tt.usersn and tim==tt.tim then
					other_flag=tt.flag
					if nil==other_flag then 
						return 1
					end								
					if other_flag<basic.need_flag then 
						return 1
					end						
					if 1==agree_or_refuse then
						commit_join(tt,chat_list[i],i+begin-step-1)						
						basic.num = basic.num+1
						guild.set_guild(guild_id,basic)
					else
						commit_refuse(tt,chat_list[i])
					end
					guild.del_msg(guild_id,1,i+begin-step-1)
					return 0
				end
			end
			
			if #chat_list<step then
				break
			end
		end
						
	end
	
	return 0
end

if isServ() then
	box.reg_todo_handle('join_is_success',function(me,dd)

		local sociaty=guild.get_guild(dd.guild_id)	
		
		local v = deepCloneTable(dd.new_member)		
		if nil~=me.basic.guild then		
			v.stat = 6
			v.name2 = me.basic.name
			guild.publish_msg(dd.guild_id,1,box.serialize(v))	
			
			return 0
		end				
		local gg = guild.get_guild(dd.guild_id)
		local tab={id=dd.guild_id,name=gg.name,mark=gg.mark,pos=4,join_time=l_cur_game_time()}	
		me.basic.guild=tab		
		v.type=nil
		v.stat = 5
		v.join_time=l_cur_game_time()
		v.position=4
		v.name2 = me.basic.name	
		guild.add_new_member(dd.guild_id,v)
		sociaty=guild.get_guild(dd.guild_id)
		
		
		local m = deepCloneTable(dd.new_member)		
		m.type='join'
		m.stat = 5
		m.tim = l_cur_game_time()
		m.name2 = me.basic.name	
		m.pos=4
		guild.publish_msg(dd.guild_id,1,box.serialize(m))
		
		daily.push_data_to_c('basic',box.serialize(me.basic))			
		daily.send_broadcast_msg('find_key',sociaty.name)
		return 0
	
	end)	
end



