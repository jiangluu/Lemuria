
local safe_time_len = 20

function onEvent(me)
	local map_index = getUEParams()	-- UE Param means User Event Param
	
	local event_time =0
	if isServ() then
		event_time = getHappenedTime()
	end
	
	if nil==map_index then
		error('invalid input param')
	end
	
	local ta_map = me.map.list[map_index]
	if nil==ta_map then
		error('invalid map_index')
	end
	
	local local_time = l_cur_game_time()
	if isServ() then
		if event_time>=local_time-safe_time_len and event_time <= local_time+safe_time_len then
			local_time = event_time
		end
	end
	
	RG.RGCreasteLog(me,local_time,true)
	RG.RGCommitLog(me,true)
	
	
	local foo = function(src_key,res_key)
		if nil~=ta_map[src_key] then
			local key2 = res_key..'_limit'
			local to_add = math.min(ta_map[src_key],me.basic[key2]-me.basic[res_key])
			-- 给它向上取整
			local up = math.floor(to_add)+1
			up = math.min(up,me.basic[key2]-me.basic[res_key])
			util.add(me,res_key,up,'col_res')
			ta_map[src_key] = ta_map[src_key] - to_add
		end
		
		-- 把地图上的 _w 资源累加起来
		local sum = 0
		util.travalPlayerMap(me,function(m)
			if m[src_key] then
				sum = sum + m[src_key]
			end
		end)
		me.basic[src_key] = sum
	end
	
	foo('meat_w','meat')
	foo('elixir_w','elixir')
	
	util.fillCacheData(me)
	
	if isServ() then
		local aa = {meat=me.basic.meat,elixir=me.basic.elixir}
		daily.push_data_to_c('cache.collect_result',box.serialize(aa))
	end
	
	-- output part
	return 0
end

