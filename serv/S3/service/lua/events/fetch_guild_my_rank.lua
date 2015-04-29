
function onEvent(me)
	if isServ() then
		local lcf = ffi.C
		
		if nil==me.basic.guild then
			return 1
		end
		
		local myrank,neighbor = guild.query_my_rank(me.basic.guild.id,2)
		if nil==myrank or nil==neighbor then
			return 2
		end
		
		local con = { my=myrank,list=neighbor }
		local str = box.serialize(con)
		daily.push_data_to_c('cache.guild_my',str)
	end
	
	return 0		
end


