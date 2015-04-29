
local arena_size = 16	-- 16个人一个赛场


function onEvent(me)
	if isServ() then
		if nil==me.basic.arena_id then
			return 1
		end
		
		local data,matrix = league.get_arena_data_app(me)
		-- 找到我的index
		local my_index = -1
		for i=1,#data.list do
			local aa = data.list[i]
			local sn = aa.usersn or aa
			if tonumber(sn) == tonumber(me.basic.usersn) then
				my_index = i
				break
			end
		end
		
		if my_index<0 then
			me.basic.arena_id = nil
			return 1
		end
		
		local my_score = league.matrix_get_my_score(matrix,my_index)
		
		data.my_score = my_score
		
		local bin = box.serialize(data)
		daily.push_data_to_c('cache.league',bin)
		if nil~=matrix then
			local ss = string.sub(matrix,1,arena_size*arena_size)
			local o = { str=ss }
			daily.push_data_to_c('cache.league_score',box.serialize(o))
			
			ss = string.sub(matrix,arena_size*arena_size+1,#matrix)
			o = { str=ss }
			daily.push_data_to_c('cache.league_time',box.serialize(o))
		end
		
	end
	
	return 0		
end

