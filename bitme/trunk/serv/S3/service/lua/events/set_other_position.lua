function onEvent(me)
	local other,position = getUEParams()
	local my = me.basic.usersn
	
	if nil == my or nil == other or nil == position then
		error('invalid param')
	end
	
	local id = nil
	if nil == me.basic.guild then
		return 1
	else
		id = me.basic.guild.id
	end
	
	if isServ() then
			--ȡ�����Ա��Ϣ
		local member = guild.get_all_member(id)
		
			--ȡ˫��ְλ���Է�λ��
		local myPosition = 0
		local otherPosition = 0
		local target = nil
		local otherLocal = 0
		
		for i = 1,#member do
			if my == member[i].usersn then
				myPosition = member[i].position
			elseif other == member[i].usersn then
				target = member[i]
				otherPosition = member[i].position
				otherLocal = i
				
			end
		end
		
		if 0== myPosition or 0== otherPosition then
			error('not here')
		end
		
		
			--�����ж���û���޸�Ȩ��
		if nil == sd.guild['a' .. myPosition]['power']['set_member_power'] or myPosition >=otherPosition or myPosition >=position then
			return 1
		end
			--�޸ĶԷ�ְλ������
		
		target.position = position
		guild.set_member(id,otherLocal,target)
		if(otherPosition>position)	 then
			--����
			local tt = {type='prompt',tim=l_cur_game_time(),usersn=other,name=me.basic.name,name2=target.name,stat=2}		
			guild.publish_msg(id,1,box.serialize(tt))
		elseif (otherPosition<position) then
			--�½�
			local tt = {type='prompt',tim=l_cur_game_time(),usersn=other,name=me.basic.name,name2=target.name,stat=3}		
			guild.publish_msg(id,1,box.serialize(tt))
		end
		local obj={type='update_position',pos=position,guildid=id}
		box.send_todo(other,obj)
		
	end
	
	return 0
end




if isServ() then
	box.reg_todo_handle('update_position',function(me,dd)	
		if nil==me.basic.guild then
			return 0
		end
		if dd.guildid~= me.basic.guild.id then
			return 0
		end		
		me.basic.guild.pos=dd.pos
	end)
end
