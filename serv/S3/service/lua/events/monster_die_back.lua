function onEvent(me)
	local str= getUEParams()
	if  nil==str  then
		error('Params is nil')
	end
	
	local function split(ss)
		local aa={}
		for k,v,l in string.gmatch(ss,'(%w+)_(%d+)_(%d+),') do	
			table.insert(aa,{type=k,num=tonumber(v),level=tonumber(l)})			
		end		
		return aa
	end	
	local tt=split(str)	
	
	if isServ() then	
		
		if nil==me.cache.pvp_copy then
			return 1
		end		
		
		local other_map=me.cache.pvp_copy.map					
		
		local mapid=nil
		for i=1,#other_map.list do
			
			if 'gd'==other_map.list[i].type then
				mapid=i
				break
			end
		end
		if nil==mapid then
			return 1
		end		
		
		if nil==other_map.list[mapid].donate_receive then
			return 1
		end
		local dr =other_map.list[mapid].donate_receive
		----保存记录 查看捐赠人列表
		
		local list={}
		for i=1,#dr.list do
			if dr.list[i].stat==1 and dr.list[i].repay_time>l_cur_game_time() and dr.list[i].isback==0 then
				local monlist=dr.list[i].list				
				for j=1,#monlist do
					for f=1,#tt do
						if tt[f].type==monlist[j].type and monlist[j].level==tt[f].level and tt[f].num>0 then							
							local obj={}
							obj.type=tt[f].type
							obj.num= monlist[j].num-monlist[j].backnum
							if obj.num>tt[f].num then
								obj.num=tt[f].num
								tt[f].num=0
							end
							obj.level=tt[f].level
							obj.donatetime=dr.list[i].times	
							obj.donate_usersn=dr.list[i].donate_usersn
							obj.receive_usersn=dr.list[i].receive_usersn
							obj.index=i	
							if obj.num>0 then
								table.insert(list,obj)	
							end
							
						end
					end
					
				end
			end
		end
		
		if #list<=0 then
			return 1
		end
		
		
		local record={type='monster_r',list=list}
		---------------接收者处理		
		box.send_todo(list[1].receive_usersn,record)
		
		---------------捐赠者处理
		for i=1,#list do			
			local s={type='monster_d',obj=list[i]}
			box.send_todo(s.obj.donate_usersn,s)
		end
		
	end	
	return 0
end


if isServ() then
	box.reg_todo_handle('monster_r',function(me,obj)
		--接收者	
		
		local list =obj.list
		local mapid =nil
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if nil==mapid then
			return 1
		end
		
		if nil==#me.map.list[mapid].donate_receive then
			return 1
		end
		
		local dr=me.map.list[mapid].donate_receive
		for i=1,#list do	
			local index=list[i].index
			
			dr_list=dr.list[index].list
			local x=0
			for j=1,#dr_list do			
				if list[i].type==dr_list[j].type and list[i].level==dr_list[j].level then
					dr_list[i].backnum=dr_list[i].backnum+list[i].num					
				end
				x=x+dr_list[i].num-dr_list[i].backnum
			end
			if x<=0 then
				dr.list[index].repay_time=1
				dr.list[index].isback=1				
			end
		end
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))
		
		return 0		
		
	end)

end

if isServ() then
	box.reg_todo_handle('monster_d',function(me,dd)
		--捐助者
		
		local obj=dd.obj
		if nil==obj then
			return 1
		end
		local mapid=nil
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if nil==mapid then
			return 0
		end
		
		if nil==me.map.list[mapid].donate_receive then
			return 0
		end
	
		local dr=me.map.list[mapid].donate_receive 
		local x=0
		
		if nil==me.lobby.list then
			return 0
		end
		--修改lobby
		local lobby=me.lobby.list
		for i=1,#lobby do
			if lobby[i].type==obj.type and nil~=lobby[i].isdonate then				
				lobby[i].isdonate=lobby[i].isdonate-obj.num				
				if lobby[i].isdonate<=0 then
					lobby[i].isdonate=nil					
				end				
			end
		end	
		
		
		--修改捐赠记录
		for i=1,#dr.list do	
			if dr.list[i].stat==0 and dr.list[i].times==obj.donatetime and dr.list[i].receive_usersn==obj.receive_usersn and dr.list[i].donate_usersn==obj.donate_usersn then
				x=0
				for j=1,#dr.list[i].list do
					local mo=dr.list[i].list[j]
					if mo.type==obj.type and mo.level==obj.level then
						mo.backnum=mo.backnum+obj.num						
					end
					x=x+(mo.num-mo.backnum)
					if x<=0 then
						dr.list[i].repay_time=1
						dr.list[i].isback=1						
					end
				end
			end
			
		end
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))
		daily.push_data_to_c('lobby',box.serialize(me.lobby))	
		
		return 0		
		
	end)
end