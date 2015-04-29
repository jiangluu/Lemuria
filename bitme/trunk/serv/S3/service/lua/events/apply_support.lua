function onEvent(me)
	local apply_type,desc= getUEParams()
	if nil==apply_type then
		error('apply_type is nil')
	end
	
	--是否有公会
	local guild_id=nil
	if nil==me.basic.guild then
		error('has no guild')
	else
		guild_id=me.basic.guild.id
	end
		
	--判断上次卷饼时间
	local apply_time=me.basic.guild.next_apply_time

	if nil~=apply_time and apply_time>l_cur_game_time() then
		return 1
	end	
	
	me.basic.guild.next_apply_time=l_cur_game_time()+1200
	local cur_pop=0
	local max_pop=0
	local level=-1
	local mapid=nil
	local ishavehero=false
	for i=1,#me.map.list do
		if 'gd'==me.map.list[i].type then
			level=me.map.list[i].level
			mapid=i
			local map_obj=me.map.list[i]			
			
			if nil==map_obj['donate_receive'] then
				cur_pop=0
			else
				for j=1,#map_obj['donate_receive'].list do				
					if 1==map_obj['donate_receive'].list[j].stat and map_obj['donate_receive'].list[j].repay_time>=l_cur_game_time() and map_obj['donate_receive'].list[j].receive_usersn==me.basic.usersn then		
					    if ('hero'==map_obj['donate_receive'].list[j].donate_type) then
							cur_pop=cur_pop+0
							ishavehero=true
						end	
						--cur_pop=cur_pop+map_obj['donate_receive'].list[j].pop
						local list=map_obj['donate_receive'].list[j].list
						for j=1,#list do							
							cur_pop=cur_pop+(sd.creature[list[j].type].population*(list[j].num-list[j].backnum))
						end
					end
				end
			end
			break
		end
	end
	
	if -1==level then
		return 1
	end
	
	local boss_time=nil
	
	if nil==me.map.list[mapid].donate_receive then
		boss_time=1
	else
		local dr=me.map.list[mapid].donate_receive
		for i=1,#dr.list do
			if dr.list[i].stat==1 and dr.list[i].repay_time>l_cur_game_time() and dr.list[i].donate_type=='monster' then
				local monster_list=dr.list[i].list
				for j=1,#monster_list do
					if monster_list[j].don_type=='boss' then
						boss_time=dr.list[i].repay_time
						break
					end
				end
			end
		end
	end
		
	if nil==boss_time then
		boss_time=1
	end
	
	
	max_pop=sd.scene['gd']['detail'][level]['population']
	if cur_pop>=max_pop and true==ishavehero then
		return 1
	end
	if isServ() then	
		local begin = 1
		local step = 20	
		for limiter=1,999 do
			local chat_list = guild.pull_msg2(guild_id,1,begin,begin+step)
			begin = begin+step
			
			if not chat_list then
				break
			end
			local isfind=false
			for i=1,#chat_list do
				local tar = box.unSerialize(chat_list[i])
				if tar and 'apply'==tar.type  and me.basic.usersn==tar.usersn then
					isfind=true
									
					guild.del_msg(guild_id,1,i+begin-step-1)
					
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
	
		local record={}
		local tt = {type='apply',tim=l_cur_game_time(),usersn=me.basic.usersn,name=me.basic.name,applytype=apply_type,msg=desc,curpop=cur_pop,maxpop=max_pop,bosstime=boss_time,record=record}		
		tt.pos=guild.get_position(guild_id,me.basic.usersn)
		--guild.publish_msg(guild_id,4,box.serialize(tt))
		
		guild.publish_msg(guild_id,1,box.serialize(tt))		
	end
	return 0
end