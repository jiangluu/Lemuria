function onEvent(me)
	local index=getUEParams()
	if nil==index  then
		error('Params is nil')
	end
	
	--是否有工会地块
	local mapid=nil
	for i=1,#me.map.list do
		if 'gd'==me.map.list[i].type then
			mapid=i
			break
		end
	end
	
	if nil==mapid then
		error('mapid is nil')
	end
	
	--是否已经召回或已经出战回来
	if nil==me.map.list[mapid].donate_receive then
		return 1
	end
	
	local dr=me.map.list[mapid].donate_receive
	if dr.list[index].repay_time<l_cur_game_time() then
		return 1
	end	
	
	--召回钻石判断
	
	local dia=util.getDiamondExchangeTime_recall(dr.list[index].end_time-l_cur_game_time())
	if  dia<=0 or dia>me.basic.diamond then
		return 1
	end
	
	util.dec(me,'diamond',dia,'recall_monster')
	local prompt={}
	local donlist=dr.list[index].list
	if 'monster'==dr.list[index].donate_type then	
		
		if nil==me.lobby.list then
			return 1
		end
		
		for i=1,#me.lobby.list do
			local lobby_obj=me.lobby.list[i]
			for j=1,#donlist do
				if nil~=lobby_obj["isdonate"] and lobby_obj["type"]==donlist[j]['type'] then	
					table.insert(prompt,{type=donlist[j]['type'],num=tonumber(donlist[j]['num']-donlist[j]['backnum']),level=tonumber(donlist[j]['level'])})
					lobby_obj["isdonate"]=lobby_obj["isdonate"]-(donlist[j]['num']-donlist[j]['backnum'])
					if 0==lobby_obj["isdonate"] then
						lobby_obj["isdonate"]=nil
					end
				end
			end
		end
		
	else		
		
		for i=1,#me.hero.list do
			local hero_obj=me.hero.list[i]
			for j=1,#donlist do
				if nil~=hero_obj['isdonate'] and hero_obj['type']==donlist[j]['type'] then	
					table.insert(prompt,{type=donlist[j]['type'],num=tonumber(donlist[j]['num']-donlist[j]['backnum']),level=tonumber(donlist[j]['level'])})
					hero_obj['isdonate']=nil					
				end				
			end
		end
		
	end
	
	local other=dr.list[index]['receive_usersn']
	dr.list[index]['repay_time']=1
	dr.list[index]['isback']=1
	
	dr.list[index].type='donate_recall'
	dr.list[index].donlist=prompt
	dr.list[index].callback_time=l_cur_game_time()
	dr.list[index].other_name=me.basic.name
	if isServ() then
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))
		box.send_todo(other,dr.list[index])
	end
	util.fillCacheData(me)
	
	return 0
end

if isServ() then
		box.reg_todo_handle('donate_recall',function(me,dd)
			
			--是否有工会地块
			local mapid=nil
			for i=1,#me.map.list do
				if 'gd'==me.map.list[i].type then
					mapid=i
					break
				end
			end			
			
			if nil==mapid then
				error('mapid is nil')
			end
			
			local map_obj=me.map.list[mapid]			
			if nil==map_obj['donate_receive'] then
				return 0
			end	
			
			local donatelist=map_obj['donate_receive']['list']
			local don_index=nil
			for i=1,#donatelist do
				local don=donatelist[i]				
				if don.stat==1 and don.donate_usersn==dd.donate_usersn and  don.receive_usersn==dd.receive_usersn and don.times==dd.times and don.donate_type==dd.donate_type then
					don_index=i
				end
				
			end
			
			if nil==don_index then
				return 0
			end				
			
			donatelist[don_index].repay_time=1
			donatelist[don_index].isback=1		
			--local obj=deepCloneTable(dd)
			--obj.type='donate_prompt'
			--daily.send_broadcast_bson(obj);	
			
			guild.delete_record(mapid,me)
			daily.push_data_to_c('map',box.serialize(me.map))
			local call_prompt={list=dd.donlist,other_name=dd.other_name,times=dd.callback_time,type="callback_prompt"}
			daily.send_broadcast_bson(call_prompt);	
			
		return 0
	end)
end
