
function onEvent(me)
	local map_index,mob_ids = getUEParams()	-- UE Param means User Event Param
	
	if nil==map_index or nil==mob_ids then
		error('invalid input param')
	end
	
	local ta_map = me.map.list[map_index]
	if nil==ta_map then
		error('invalid map index')
	end
	
	local t_id = {}
	for aa in string.gmatch(mob_ids,'(%d+)') do
		table.insert(t_id,tonumber(aa))
	end
	
	-- if #t_id<2 then
		-- error('invalid ids')
	-- end
	if nil==me.lobby.list then
		return 1
	end
	
	
	-- check
	local t_down_mob = {}
	for i=1,#me.lobby.list do
		table.insert(t_down_mob,deepCloneTable(me.lobby.list[i]))
	end
	
		-- 等于把现有的先还回去
	if ta_map.mob then
		for i=1,#ta_map.mob.list do
			local mob_in_map = ta_map.mob.list[i]
			
			local found = false
			for k=1,#t_down_mob do
				local mob_in_lobby = t_down_mob[k]
				if mob_in_map.type==mob_in_lobby.type and mob_in_map.level==mob_in_lobby.level then
					mob_in_lobby.num_used = mob_in_lobby.num_used - mob_in_map.num
					found = true
					
					break
				end
			end
		end
	end
	
	for i=1,(#t_id)/2 do
		local lobby_index = t_id[i*2-1]
		local num = t_id[i*2]
		
		local mob_in_lobby = t_down_mob[lobby_index]
		if nil==mob_in_lobby then
			error('invalid ids index')
		end
		
		if mob_in_lobby.num_used+num > mob_in_lobby.num then
			error('invalid ids num')
		end
	end
	
	-- TODO:检查目标建筑是否能放下这么多
	
	
	
	-- done checking. do real stuff
	if nil==ta_map.mob then
		ta_map.mob = {}
	end
	ta_map.mob.list = newArray()
	
	for i=1,(#t_id)/2 do
		local lobby_index = t_id[i*2-1]
		local num = t_id[i*2]
		
		-- lobby里的减掉
		local mob = t_down_mob[lobby_index]
		mob.num_used = mob.num_used + num
		
		-- 放到
		for kk=1,num do
			table_insert(ta_map.mob.list,{type=mob.type,level=mob.level,num=1})
		end
		--table_insert(ta_map.mob.list,{type=mob.type,level=mob.level,num=num})
	end
	
		-- 同步
	for i=1,#t_down_mob do
		local aa = t_down_mob[i]
		
		if isServ() then
			me.lobby.list[i] = deepCloneTable(aa)
		else
			deepCloneTableToUserData(me.lobby.list[i],aa)
		end
	end
	
	-- 为了让客户端不出错，空了的list就索性删掉
	if 0==#ta_map.mob.list then
		ta_map.mob = nil
	end
	
	
	return 0
end

