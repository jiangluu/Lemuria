
local lcf = ffi.C

-- 这是个全局函数，C里面会调用
function box_post_init()
	league.post_init()


	-- 订阅本BOX系统频道
	local actor_id = tonumber(lcf.cur_actor_id())
	print('box_post_init',g_box_id,actor_id)
	
	
	local ac = box.occupy_actor(actor_id)
	
	local function subscribe_box_channel(me2)
	
		local function cb(me,mkey,msg)
			-- @NOTE: 这里之所以注册cb，然后在cb里面再调用一个全局函数，目的是为了“解耦”。这样reload以后不用重新注册handle，因为 __default_box_channel_cb 已经是新的值了
			__default_box_channel_cb(me,mkey,msg)
		end
		
		local box_channel = box.get_channel_name()
		print('box_channel',box_channel,g_app_id)
		channel.subscribe(guild_subscribe_redis_index,box_channel,cb,actor_id)
	
	end
	
	if transaction.is_in_transaction(ac) then
		subscribe_box_channel(ac)
	else
		transaction.new(ac,subscribe_box_channel)
		transaction.wakeup(ac)
	end
	
end

-- BOX频道的系统默认callback
function __default_box_channel_cb(agent,mkey,msg)
	if 'yy'==string.sub(msg,1,2) then
		yyop.dispatch(msg)
	else
		local dd = box.unSerialize(msg)
		if dd then
			if 'notify_todo'==dd.a then
				local usersn = dd.b
				local whom = box.find_actor_by_usersn(usersn)
				if whom then
					whom.notify_todo = true
				end
			end
		end
	end
end
