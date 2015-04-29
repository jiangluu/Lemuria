
local lcf = ffi.C


-- 在线列表的key是usersn，value是数字，意义为：正数和0表示不在线护盾结束时间；-2表示在线；-4表示正在被攻击；key不存在表示不在线，但是护盾未知。
-- 注意正数和0表示不在线，但是反过来不成立。即不在线的不一定在在线列表里。在线列表只保证在线的人一定在它里面。
local stat_taken = -2

local prefix_google_bind = 'google_bind_'
local prefix_apple_bind = 'gamecenter_bind_'

local function gen_random()
	local t = {}
	for i=1,8 do
		local ff = 65+(math.random(100000)%58)
		if ff>=91 and ff<=96 then
			ff = ff+6
		end
		table.insert(t,ff)
	end
	return string.char(unpack(t))
end

box.reg_handle(1,function(me)
	
	local function ack_err(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_write_back()
	end
	
	local login_type = lcf.cur_stream_get_int16()
	local login_key = l_cur_stream_get_slice()
	local ip = l_cur_stream_get_slice()
	
	local orig_type = login_type
	
	local new_weak_id = nil
	
	if 4==login_type then
		login_key = gen_random()
		local usersn = tostring(db.command_and_wait(0,'INCR count_usersn'))
		if nil==usersn then
			-- 杯具
			ack_err(2)
			return 1
		end
		
		login_key = login_key..usersn
		db.set('weak'..login_key,usersn)
		
		login_type = 3
	end
	
	
	local prefix = 'weak%s'
	if 1==login_type then
		prefix = 'gamecenter%s'
	elseif 2==login_type then
		prefix = 'google+%s'
	end
	
	local db_key = string.format(prefix,login_key)
	local usersn = db.get(db_key)
	if nil==usersn then
		-- 这个tostring 转换重要，否则会crash。这是因为redis接口有...，无法做类型检查所致。这是这个架构唯一的坑了
		usersn = tostring(db.command_and_wait(0,'INCR count_usersn'))
		if nil==usersn then
			-- 杯具
			ack_err(2)
			return 1
		end
		
		db.set(db_key,usersn)
		-- 给她绑定，即27号包里的部分操作
		local key2 = 0
		if 1==login_type then
			key2 = prefix_apple_bind..usersn
		else
			key2 = prefix_google_bind..usersn
		end
		db.set(key2,login_key)
		
		new_weak_id = gen_random()
		db_key = 'weak'..new_weak_id
		db.set(db_key,usersn)
	end
	
	print('Login handle',login_type,login_key,ip,usersn)
	
	local now = l_cur_game_time()
	
	-- 检查usersn是否在线
	local old_stat = ownership.get_current_stat(usersn)
	if stat_taken==old_stat then
		-- 要顶号先
		local aa={type='crowd',t=l_cur_game_time()}
		box.send_todo(usersn,aa)
		-- 加一条日志
		yylog.log(string.format('crowd,usersn%d,login_type%d,login_key[%s],ip[%s]',usersn,login_type,login_key,ip))
	end
	
	local is_taken,session_key = ownership.take(usersn,stat_taken)
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
		-- 这货不在线 OR 被顶号了
		local t_com = {'HMGET',usersn}
		for __,kk in pairs(box.user_need_blocks) do
			table.insert(t_com,kk)
		end
		
		local all_data = { db.command_and_wait(db.hash(usersn),table.concat(t_com,' ')) }
		
		if #all_data<(3) then
			-- 数据不足，是新号			
			util.initNewPlayer(me)
			me.basic.create_time = tonumber(lcf.cur_game_time())
		else
			-- 如果是平台ID登录，先备份数据
			if 1==login_type or 2==login_type then
				local time_str = os.date('%Y%m%dh%H%M%S')
				local key_new = string.format('%s_%s',usersn,time_str)
				
				for ii,kk in pairs(box.user_need_blocks) do
					local aa = all_data[ii]
					if aa then
						box.save_player_one_block(key_new,kk,aa)
					end
				end
				
				local extra_block = {'todo'}
				for ii,kk in pairs(extra_block) do
					local aa = db.command_and_wait(db.hash(usersn),'HGET %s %s',tostring(usersn),kk)
					if aa then
						box.save_player_one_block(key_new,kk,aa)
					end
				end
			end
			
			for ii,kk in pairs(box.user_need_blocks) do
				local aa = box.unSerialize(all_data[ii])
				me[kk] = aa
			end
			
			box.makesure_all_block_exist(me)
		end
		
		
		me.var.stat.lkey = login_key
		me.basic.usersn = usersn
		if login_type>=3 then
			me.var.stat.weakid = login_key
		elseif new_weak_id then
			me.var.stat.weakid = new_weak_id
		end
		
		
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(0)
		lcf.cur_stream_push_string(session_key,#session_key)
		lcf.cur_stream_push_int32(lcf.cur_game_time())
		lcf.cur_stream_push_int32(lcf.cur_game_time())
		local ww = me.var.stat.weakid or 'notexists'
		lcf.cur_stream_push_string(ww,#ww)
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

