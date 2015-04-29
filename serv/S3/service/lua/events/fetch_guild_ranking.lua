
function onEvent(me)
	local is_global,idx_1,idx_2 = getUEParams()
	
	if nil==idx_1 or nil==idx_2 then
		error('invalid param')
	end
	
	local num = idx_2 - idx_1
	
	if isServ() then
		local lcf = ffi.C
		
		local gg = guild.get_ranking(idx_1-1,idx_2-2)
		
		if nil==gg then
			return 1
		end
		
		local con = { list=gg }
		
		local str = box.serialize(con)
		daily.push_data_to_c('guild_ranking',str)
	end
	
	return 0		
end


