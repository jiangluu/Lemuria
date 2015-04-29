function onEvent(me)
	--捐兵类型,兵种_数量_等级,剩余人口,对方usersn,申请时间
	
	local donate_type,mon_type,overplus_pop,other,app_time= getUEParams()
	if nil==donate_type or nil==mon_type  or nil==overplus_pop  or nil==other or nil==app_time then 		
		error(' Params is nil')		
	end
	
	--我是否有工会
	if nil==me.basic.guild then		
		error('has no guild')
	end
	local guild_id=me.basic.guild.id

	--看自己是否有空余的怪or英雄
	
	local function find_skill(u_type)
		local skill=nil
		
		if 'monster'==donate_type then
			if nil==me.lobby.list then
				return 1
			end
			
			for i=1,#me.lobby.list do				
				if me.lobby.list[i].type==u_type and nil~=me.lobby.list[i].skill then					
					skill=me.lobby.list[i].skill
					break
				end
				
			end
			
		else
			
			for i=1,#me.hero.list do
				if me.hero.list[i].type==u_type and nil~=me.hero.list[i].equip  then
					skill=me.hero.list[i].equip	
					break
				end				
			end
				
		end
		return skill		
	end
	
	local boss_num=0
	local hero_num=0
	local monlist={}
	local function split(ss)
		local aa = {}
		
		for k,v,l,j in string.gmatch(ss,'(%w+)_(%d+)_(%d+)_(%w+),') do			
			local sk=find_skill(k)	
			if 'boss'==j then
				boss_num=boss_num+1
			elseif 'hero'==j then
				hero_num=hero_num+1
			end
			table.insert(monlist,{type=k,num=tonumber(v),level=tonumber(l)})
			table.insert(aa,{type=k,num=tonumber(v),level=tonumber(l),equip=sk,don_type=j,backnum=0})			
		end		
		return aa
	end
	
	local tt = split(mon_type)	
	
	if boss_num>=2 or hero_num>=2 then
		daily.send_broadcast_msg('fail','')
		return 1
	end
	--local tt ={{type='dsf',num=2,level=10},{type='dsf',num=2,level=10},}
	
	local pop=0
	local monp =0 
	local have_hero=false
	if 'hero'==donate_type then
		if #tt>1 then	
			daily.send_broadcast_msg('fail','')
			return 1
		end
		for i=1,#me.hero.list do			
			if tt[1].type==me.hero.list[i].type and nil==me.hero.list[i].inuse and tt[1].num==1 then				
				--pop=sd.creature[tt[1].type].population
				--if pop==0 then
					--pop=10
				--end
				have_hero=true
				break
			end
		end
	elseif 'monster'==donate_type then			
		for i=1,#me.lobby.list do			
			for j=1,#tt do	
				if tt[j].type==me.lobby.list[i].type and me.lobby.list[i].num-me.lobby.list[i].num_used>=tt[j].num then					
					pop=pop+((sd.creature[tt[j].type].population)*tt[j].num)
					monp = monp+tt[j].num
				end
			end			
		end
	end
	

	
	if 0==pop and false==have_hero then	
		daily.send_broadcast_msg('fail','')
		return 1
	end
	--查看是否可以放下这么多怪
	if overplus_pop<pop and  'hero'~=donate_type  then
		daily.send_broadcast_msg('fail','')
		return 1		
	end	
	
	local index=-1
	for i=1,#me.map.list do
		if 'gd'==me.map.list[i].type then
			index=i
			break
		end
	end
	
	if -1==index then
		return 1
	end
	local tims=24*60*60
	--local tims=30
	

	
	--把自己的兵冻结
	function freeze()
		if 'hero'==donate_type then
			for i=1,#me.hero.list do
				if tt[1].type==me.hero.list[i].type then				
					me.hero.list[i].isdonate=tt[1].num
					break
				end
			end
		elseif 'monster'==donate_type then
		
			for i=1,#me.lobby.list do
				for j=1,#tt do
					if tt[j].type==me.lobby.list[i].type  then
						if nil~=me.lobby.list[i].isdonate then
								
								me.lobby.list[i].isdonate=me.lobby.list[i].isdonate+tt[j].num
						else
							
							me.lobby.list[i].isdonate=tt[j].num
						end
					end
				end			
			end
		end
	end

	local function is_have_boss(m_list)
		local check_type=nil
		for i=1,#monlist do
			local types=sd.creature[monlist[i].type].type
			if 'hero'==types or 'boss'==types then
				check_type=types
				break
			end
		end
		
		if nil==check_type then
			return 1
		end
		
		for i=1,#m_list do
			local _trl=m_list[i]
			for k=1,#_trl.monlist do				
				local types=sd.creature[_trl.monlist[k].type].type				
				if nil~=types and types==check_type then
					return 0
				end
			end
		end		
		return 1
	end
	local is_find=false
	if isServ() then

	
		local begin = 1
		local step = 20	
		local otherPosition=nil
		local member = guild.get_all_member(guild_id)
		for i = 1,#member do
			if nil == member[i].leave_time and nil ~= member[i].join_time then
				if other == member[i].usersn then					
					otherPosition = member[i].position
					break					
				end
			end
		end
	
		
		if nil==otherPosition then 			
			return 1
		end
		
		for limiter=1,999 do
			local chat_list = guild.pull_msg2(guild_id,1,begin,begin+step)
			begin = begin+step
			
			if not chat_list then
				break
			end
			
			for i=1,#chat_list do
				local tar = box.unSerialize(chat_list[i])				
				
				if tar and 'apply'==tar.type  and other==tar.usersn and app_time==tar.tim then
					is_find=true
					if tar.maxpop<=tar.curpop and  'hero'~=donate_type then	
						daily.send_broadcast_msg('fail','')
						return 1
					end
						
					-- 修改公会聊天中的那条
						
					if nil==tar.record.list then
						tar.record.list={}						
					else
						local k=is_have_boss(tar.record.list)						
						if 0==k then
							local dct=deepCloneTable(tar)	
							dct.type='notice'				
							guild.publish_msg(guild_id,4,box.serialize(dct))							
							daily.send_broadcast_msg('fail','')
							return 1
						end
					end
					
					tar.curpop=tar.curpop+pop	
					freeze()
					local obj={donate_usersn=me.basic.usersn,monlist=monlist}
					table.insert(tar.record.list,obj)
					guild.modify_msg(guild_id,1,i+begin-step-1,tar)	
					
					
					local dd = {stat=0,donate_usersn=me.basic.usersn,receive_usersn=other,times=l_cur_game_time(),repay_time=l_cur_game_time()+tims,list=tt,postion=otherPosition,
					name=tar.name,donate_type=donate_type,end_time=l_cur_game_time()+tims,isback=0,other_name=me.basic.name}
					
					if nil==me.map.list[index].donate_receive then
						me.map.list[index].donate_receive = { list={} }
					end
					table_insert(me.map.list[index].donate_receive.list,dd)	
					
					
					--local bin = box.serialize(tar)
					--local aa = i+begin-step-2						
					--guild.command_and_wait('LSET %s %d %b','gla'..guild_id,ffi.cast('int',aa),bin,ffi.cast('size_t',#bin))
					guild.delete_record(index,me)
					daily.push_data_to_c('map',box.serialize(me.map))
					daily.push_data_to_c('lobby',box.serialize(me.lobby))	
					daily.push_data_to_c('hero',box.serialize(me.hero))					
					local is_del=false
					if 	tar.curpop>=tar.maxpop then						
						guild.del_msg(guild_id,1,i+begin-step-1)
						is_del=true
					end			
					
					-- 通知接收人
					local ee = deepCloneTable(dd)					
					ee.type = 'donate_recv'
					ee.stat=1					
					local rrr = box.send_todo(other,ee)
				
					local ss=deepCloneTable(tar)	
					ss.type='notice'				
					guild.publish_msg(guild_id,4,box.serialize(ss))
					if 'hero'==donate_type and is_del==false then
						local mm=deepCloneTable(tar)	
						mm.type='notice_1'				
						guild.publish_msg(guild_id,4,box.serialize(mm))	
						guild.del_msg(guild_id,1,i+begin-step-1)
					end	
					
						--加经验
					util.add_exp_level(me,pop)
					daily.push_data_to_c('basic',box.serialize(me.basic))
					--捐赠的英雄和怪数量
					ach.key_inc3(me,'accAllian',monp)
					ach.key_inc3(me,'accHero',hero_num)
					return 0
				end
			end
			
			if #chat_list<step then
				break
			end
		end
		if is_find==false then
			daily.send_broadcast_msg('fail','')
		end
	end	
	
	return 0	
	
end

if isServ() then
	box.reg_todo_handle('donate_recv',function(me,dd)
		if nil==me.basic.guild then
			error('has no guild')
		end
		
		local mapid=-1
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if -1==mapid then
			return 0
		end
		
		local jz_type=nil	
		
		for i=1,#dd.list do
			if 'boss'==dd.list[i].don_type or 'hero'==dd.list[i].don_type then
				jz_type=dd.list[i].don_type
				break
			end
		end
		
		local count=0		
		if nil~=jz_type and me.map.list[mapid].donate_receive~=nil then
		
			local dr=me.map.list[mapid].donate_receive
			for i=1,#dr.list do
				
				if dr.list[i].repay_time>l_cur_game_time() and dr.list[i].stat==1 then
				
					for j=1,#dr.list[i].list do
						
						if jz_type==dr.list[i].list[j].don_type   then
							local ee = deepCloneTable(dd)					
							ee.type = 'have_more_boss'
							box.send_todo(ee.donate_usersn,ee)
							return 0
						end
					end
				end				
			end
		end		
		
		if nil==me.map.list[mapid].donate_receive then
			me.map.list[mapid].donate_receive = { list={} }
		end
		table_insert(me.map.list[mapid].donate_receive.list,dd)	
		guild.delete_record(mapid,me)
		daily.push_data_to_c('map',box.serialize(me.map))	
		--local dd = {stat=0,donate_usersn=me.basic.usersn,receive_usersn=other,times=l_cur_game_time(),repay_time=l_cur_game_time()+tims,list=tt,
		--postion=otherPosition,name=tar.name,donate_type=donate_type,end_time=l_cur_game_time()+tims,isback=0}
		--table.insert(monlist,{type=k,num=tonumber(v),level=tonumber(l)})
		
		local obj=deepCloneTable(dd)
		obj.type='donate_prompt'
		daily.send_broadcast_bson(obj);	
		return 0
	end)
	
end


if isServ() then
	box.reg_todo_handle('have_more_boss',function(me,dd)	
		--local dd = {stat=0,donate_usersn=me.basic.usersn,receive_usersn=other,times=l_cur_game_time(),repay_time=l_cur_game_time()+tims,
		--list=tt,postion=otherPosition,name=tar.name,donate_type=donate_type,end_time=l_cur_game_time()+tims,isback=0}
		
		local mapid=-1
		for i=1,#me.map.list do
			if 'gd'==me.map.list[i].type then
				mapid=i
				break
			end
		end
		
		if -1==mapid then
			return 0
		end
		
		local dr=me.map.list[mapid].donate_receive 
		local is_del=false
		for i=1,#dd.list do		
			if 'hero'==dd.list[i].don_type then	
				local is_find=false			
				for j=1,#me.hero.list do
					if dd.list[i].type==me.hero.list[j].type and nil~=me.hero.list[j].isdonate then
						me.hero.list[j].isdonate =nil
						is_find=true						
						break
					end
				end				
				if is_find==false then
					return 0
				end				
				for j=1,#dr.list do					
					if dr.list[j].donate_usersn==dd.donate_usersn and dr.list[j].receive_usersn==dd.receive_usersn and dr.list[j].times==dd.times and dr.list[j].stat==0 then
						
						table_remove(dr.list,j)
						daily.push_data_to_c('map',box.serialize(me.map))
						daily.push_data_to_c('hero',box.serialize(me.hero))
						
						return 0
					end
				end	
			else
				if nil==me.lobby.list then
					return 0
				end
				local is_find=false	
				for j=1,#me.lobby.list do
					if dd.list[i].type==me.lobby.list[j].type and nil~=me.lobby.list[j].isdonate then
						me.lobby.list[j].isdonate=me.lobby.list[j].isdonate-dd.list[i].num
						if me.lobby.list[j].isdonate<=0 then
							me.lobby.list[j].isdonate=nil	
							is_find=true							
							break
						end
					end
				end		
				if is_del==false and  is_find==true then
					for j=1,#dr.list do
						if dr.list[j].donate_usersn==dd.donate_usersn and dr.list[j].receive_usersn==dd.receive_usersn and dr.list[j].times==dd.times and dr.list[j].stat==0 then						
							table_remove(dr.list,j)	
							is_del=true
							
							break
						end
					end	
				end				
					
				
			end
		end
		
		if 'monster'==dd.donate_type then
			guild.delete_record(mapid,me)
			daily.push_data_to_c('map',box.serialize(me.map))
			daily.push_data_to_c('lobby',box.serialize(me.lobby))
		end	
		
		return 0
	end)
end
