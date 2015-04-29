
local lcf = ffi.C


local stat_taken = -2


-- Reconnect 	9
box.reg_handle(9,function(me)
	
	local login_key = l_cur_stream_get_slice()
	local session_key = l_cur_stream_get_slice()
	local ip = l_cur_stream_get_slice()
	
	local function ack_err(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_write_back()
	end
	
	if nil==session_key then
		ack_err(9)
		return 0
	end
	
	
	local prefix = 'weak%s'
	
	local db_key = string.format(prefix,login_key)
	local usersn = db.get(db_key)
	if nil==usersn then
		ack_err(8)
		return 0
	end
	
	print('Relogin handle',login_key,session_key,ip,usersn)
	
	local now = l_cur_game_time()
	
	-- 检查usersn是否在线
	local old_stat = ownership.get_current_stat(usersn)
	if stat_taken==old_stat then
		-- 要顶号先
		local aa={type='crowd',t=l_cur_game_time()}
		box.send_todo(usersn,aa)
		-- 加一条日志
		yylog.log(string.format('crowd,usersn%d,login_type1,login_key[%s],ip[%s]',usersn,login_key,ip))
	end
	
	local is_taken,session_key = ownership.take(usersn,stat_taken,session_key)
	if false==is_taken then
		-- 这货在线
		if -10==tonumber(session_key) then
			-- be baned
			local timeout = redis.command_and_wait(0,'TTL %s',tostring(usersn))
			
			lcf.cur_write_stream_cleanup()
			lcf.cur_stream_push_int16(tonumber(session_key))
			lcf.cur_stream_push_int32(tonumber(timeout) or 0)
			lcf.cur_stream_write_back()
		else
			ack_err(session_key)
		end
		
	else
		
		local t_com = {'HMGET',usersn}
		for __,kk in pairs(box.user_need_blocks) do
			table.insert(t_com,kk)
		end
		
		local all_data = { db.command_and_wait(db.hash(usersn),table.concat(t_com,' ')) }
		
		if #all_data<(3) then
			-- 数据不足，这里是relogin，不给他开新号		
			ack_err(7)
			return 0
			
		else
			for ii,kk in pairs(box.user_need_blocks) do
				local aa = box.unSerialize(all_data[ii])
				me[kk] = aa
			end
			
			box.makesure_all_block_exist(me)
		end
		
		me.var.stat.lkey = login_key
		me.basic.usersn = usersn
		

		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(0)
		lcf.cur_stream_push_int32(lcf.cur_game_time())
		lcf.cur_stream_push_int32(lcf.cur_game_time())
		lcf.cur_stream_write_back()
		
		
		util.fillCacheData(me)
		
		me.cache.session = session_key
		
		if stat_taken==old_stat then
			me.cache.crowd_other = true
		end
		
		daily.check_and_give_daily(me)
		
		local s = string.format('login,%s,%s,%s',usersn,login_key,ip)
		yylog.log(s)
		
		box.post_login(me)
		
	end
	
	return 0
end)

