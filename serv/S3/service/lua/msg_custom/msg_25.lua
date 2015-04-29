
local lcf = ffi.C



-- observe 	25 	<<(string)usersn 	要观察的目标玩家usersn
box.reg_handle(25,function(me)
	
	local function err_ack(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_write_back()
	end
	
	local ta_usersn = l_cur_stream_get_slice()
	
	local ta_data = { db.command_and_wait(db.hash(ta_usersn),'HMGET %s basic map',ta_usersn) }
	if 2~=#ta_data then
		err_ack(1)
		return 1
	end
	
	-- 读取在线状态
	local now = l_cur_game_time()
	local online = 1
	local stat = tonumber(redis.command_and_wait(0,'HGET %s a',ta_usersn))
	if nil==stat then
		online = 0		
	elseif now<=tonumber(stat) then
		online = 2		
	elseif tonumber(stat)<0 then
		online = 1	
	else
		online = 0		
	end
	
	local tt = { a=online }
	local bin2 = box.serialize(tt)
	daily.push_data_to_c('cache.ro',bin2)
	
	
	local dd = {}
	dd.basic = box.unSerialize(ta_data[1])
	dd.map = box.unSerialize(ta_data[2])
		
	local ss = box.serialize(dd)
	daily.push_data_to_c('cache.ro2',ss)
	
	err_ack(0)
	
	
	return 0
end)

