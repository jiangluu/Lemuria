function onEvent(me)
		local index= getUEParams()
		if nil==index then
			error('Params is nil')
		end
		
		local mapid=nil
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if nil==mapid then
			return 1
		end
		
		if nil==me.map.list[mapid].donate_receive then
			return 1
		end
		local dr=me.map.list[mapid].donate_receive
		local drobj=dr.list[index]
		--已经过期或者已经召回
		if drobj.repay_time<l_cur_game_time() then
			return 1
		end		
		
		drobj.repay_time=1
		drobj.isback=1
		drobj.type='recall_hero'
		local other=drobj.donate_usersn
		if isServ() then
			guild.delete_record(mapid,me)
			daily.push_data_to_c('map',box.serialize(me.map))
			box.send_todo(other,drobj)
		end		
		
		return 0
end

if isServ() then
	box.reg_todo_handle('recall_hero',function(me,dd)
		
		local mapid=nil
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if nil==mapid then
			return 1
		end
		
		if nil==me.map.list[mapid].donate_receive then
			return 1
		end
		local dr=me.map.list[mapid].donate_receive	
		local drobj=nil
		
		for i=1,#dr.list do
			if dr.list[i].stat==0 and dr.list[i].donate_usersn==dd.donate_usersn and dr.list[i].receive_usersn==dd.receive_usersn and dr.list[i].times==dd.times and dr.list[i].donate_type==dd.donate_type then
				drobj=dr.list[i]
				break
			end
		end
		
		if nil==drobj then
			return 1
		end
		
		for	i=1,#me.hero.list do
			
			if me.hero.list[i].type==drobj.list[1].type and nil~=me.hero.list[i].isdonate  and  me.hero.list[i].isdonate==#drobj.list then
				me.hero.list[i].isdonate=nil
				
			end
		end
		
		drobj.repay_time=1	
		drobj.isback=1	
		daily.push_data_to_c('hero',box.serialize(me.hero))
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))
		
		return 0
	end)
end
