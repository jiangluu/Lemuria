
function onEvent(me)
	local from,endd = getUEParams()
	
	if nil==from or nil==endd then
		error('invalid param')
	end
	
	if nil==me.basic.guild then
		error('has NO guild')
	end
	if isServ() then	
		local lcf = ffi.C
		local aa = guild.pull_msg(me.basic.guild.id,1,from,endd,true)
		
		if aa then			
			--local dd={}
			for i=#aa,1,-1 do
				aa[i] = box.unSerialize(aa[i])	
				--table.insert(dd,aa[i])	
			end
			
			
			--local f = { list=dd }
			local f = { list=aa }
			daily.push_data_to_c('cache.gc',box.serialize(f))
		end
	
		-- if aa then
			-- local f = { list=aa }
			-- daily.push_data_to_c('cache.gc',box.serialize(f))
			-- for i=1,#aa do
				-- lcf.cur_write_stream_cleanup()
				-- lcf.cur_stream_push_int16(100)
				-- local dd = aa[i]
				-- lcf.cur_stream_push_string(dd,#dd)
				-- lcf.cur_stream_write_back2(14)
				
			-- end
		-- end
	end
	return 0		
end

