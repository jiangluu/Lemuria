function onEvent(me)
	local index= getUEParams()
	if nil==index then
		error(' Params is nil')
	end
	
	--是否有map地块
	local mapid=nil
	local dr=nil
	for i=1,#me.map.list do
		if 'gd'==me.map.list[i].type then
			mapid=i
			dr=me.map.list[i].donate_receive
			break
		end
	end
	
	if nil==mapid or nil==dr then
		return 1
	end
	
	--是否已经还了
	if dr.list[index].repay_time>l_cur_game_time() or dr.list[index].isback==1 then
		return 1
	end
	
	local dr_obj=dr.list[index]
	dr_obj.repay_time=1
	dr_obj.isback=1		
	for i=1,#dr_obj.list do
		if 'hero'==dr_obj.donate_type then	
			
			if dr_obj.stat==0 then
				for j=1,#me.hero.list do
					if me.hero.list[j].type==dr_obj.list[i].type and nil~=me.hero.list[j].isdonate then					
						me.hero.list[j].isdonate=nil
						break						
					end				
				end
			end
			
		else
			
			if dr_obj.stat==0 then
				if nil==me.lobby.list then
					return 1
				end
				for j=1,#me.lobby.list do
					if me.lobby.list[j].type==dr_obj.list[i].type and nil~=me.lobby.list[j].isdonate  then					
						me.lobby.list[j].isdonate=nil
					end
				end
				
			end		
			
			
		end
	end
	
	if isServ() then
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))
	end
	
	return 0
	
end
