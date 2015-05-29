
-- BOX的实现在Lua里的部分

-- bak变量是为了支持热更新
local bak = box


local o = {}

box = o


function OnMessage(message_id)
	local err,ret = pcall(o.on_message,message_id)
	if false==err then
		print(ret)
		return 1
	else
		return ret
	end
end


function OnActorEnter()
	local err,ret = pcall(o.on_actor_enter)
	if false==err then
		print(ret)
		return -1
	else
		return ret
	end
end


function OnRedisReply(a)
	local err,ret = pcall(o.on_redis_reply_select,a)
	
	pcall(o.wipe_actor,0)
	
	if false==err then
		print(ret)
		return 1
	else
		return ret
	end
end

function isPushMsg()
	local err,ret = pcall(o.is_push)
	if false==err then
		print(ret)
		return true
	else
		return ret
	end
end



function OnFrame()
	local err,ret = pcall(o.on_frame)
	if false==err then
		print(ret)
	end
end


-- 下面比较偏实现

local lcf = ffi.C

o.handle = {}

if nil==bak then
	o.actors = {}
	o.next_actor_id = 1
else
	o.actors = bak.actors
	o.next_actor_id = bak.next_actor_id
end

o.exit_message = {}



function o.reg_handle(message_id,f)
	local function wraper(ac)
		if ac then
			ac._cur_tran = tonumber(message_id)
		end
		local begin_time = prof.cur_usec()
		
		local r = f(ac)
		
		-- 检查成就
		pcall(ach.check_all,ac)
		pcall(daily.check_all,ac)
		
		local tran_name = string.format('msg%d',message_id)
		prof.incr_counter(tran_name)
		prof.commit_transaction(tran_name,begin_time)
		
		return r
	end
	
	o.handle[tonumber(message_id)] = wraper
end

function o.get_actor(id)
	return o.actors[tonumber(id)]
end

function o.new_actor()
	-- 分配一个新的。actors的分配策略定为：在一个范围(0~100)内循环使用
	if nil==o.actor_id_range then
		o.actor_id_range = math.floor(g_box_suggested_actor_num * 1.5)
	end
	local range = o.actor_id_range
	local cursor = o.next_actor_id
	
	for i=1,range do
		local aa = cursor+i-1
		if aa>range then
			aa = aa-range
		end
		
		if nil==o.actors[aa] then
			o.actors[aa] = {}
			o.next_actor_id = aa+1
			return aa
		end
	end
	
	return -1	-- 用完了，分配不出了
end

-- 占据这个，不给别人用
function o.occupy_actor(index)
	o.actors[index] = { occupy=true }
	return o.actors[index]
end

function o.release_actor(id)
	o.actors[tonumber(id)] = nil
end

function o.actor_num()
	local c = 0
	for k,v in pairs(o.actors) do
		c = c+1
	end
	return c
end


function o.on_message(message_id)
	local actor_id = tonumber(lcf.cur_actor_id())
	local actor = o.get_actor(actor_id)
	
	if nil==actor then
		-- 如果没有actor，暂不支持事务
		local hd = o.handle[tonumber(message_id)]
		if hd then
			local ok,ret = pcall(hd,nil)
			if false==ok then
				print(ret)
				return 1
			else
				return ret
			end
		else
			print(string.format('message [%d] has NO handle.',message_id))
			return 2
		end
	else
		-- we have an actor ^-^
		local skip_hanging = false
		local is_optimized = false
		
		if nil~=o.exit_message[tonumber(message_id)] then
			-- 退出消息，退出必须成功，强制中止当前事务
			transaction.force_abort_transaction(actor)
			skip_hanging = true
			actor.__hanging = {}	-- cleanup it
		end
		
		-- push the msg to hanging
		if nil==actor.__hanging then
			actor.__hanging = {}
		end
		
		if (not transaction.is_in_transaction(actor)) and 0==#actor.__hanging then
			is_optimized = true
		end
		
		if not is_optimized then
			local sl = lcf.cur_read_stream_backup()
			local bin = ffi.string(sl.mem_,sl.len_)
			local to_hangup = { tonumber(message_id),bin }
			table.insert(actor.__hanging,to_hangup)
		else
			table.insert(actor.__hanging,tonumber(message_id))
		end
		
		-- process msgs
		local first_hanging = nil
		while ((not transaction.is_in_transaction(actor)) and #actor.__hanging>0) do
			first_hanging = table.remove(actor.__hanging,1)
			if not is_optimized then
				message_id = first_hanging[1]
				lcf.cur_read_stream_restore(first_hanging[2])
			else
				is_optimized = false	-- 只有第一次并且唯一一次优化机会
			end
			
			local hd = o.handle[tonumber(message_id)]
			if hd then
				-- 新消息到来时，总是启动一个新的事务
				transaction.new(actor,hd)
				local ret = transaction.wakeup(actor)
			else
				print(string.format('message [%d] has NO handle.',message_id))
			end
		end
		
		if #actor.__hanging>0 then
			print('is_in_transaction',actor_id,tonumber(message_id),actor._cur_tran)
		end
		
		return 3
	end
end

function o.wipe_actor(aid)		-- 催促aid号actor完成他的工作
	local ac = o.get_actor(aid)
	if ac and nil~=ac.__hanging then
		local first_hanging = nil
		while ((not transaction.is_in_transaction(ac)) and #ac.__hanging>0) do
			first_hanging = table.remove(ac.__hanging,1)
			local message_id = first_hanging[1]
			lcf.cur_read_stream_restore(first_hanging[2])
			
			local hd = o.handle[tonumber(message_id)]
			if hd then
				transaction.new(ac,hd)
				local ret = transaction.wakeup(ac)
			else
				print(string.format('message [%d] has NO handle.',message_id))
			end
		end
		
	end
end


function o.on_actor_enter()
	local new_id = o.new_actor()
	if new_id<0 then
		return -1
	end
	
	-- 尽快返回new_id，不做多余操作
	return new_id
end


function o.is_push()
	local c_m = lcf.get_cur_redis_push_msg()
	if nil~=c_m then
		if 2==c_m.type and c_m.elements>0 then
			if 1==c_m.element[0].type then
				local ss = ffi.string(c_m.element[0].str,c_m.element[0].len)
				-- if 'message'==ss or 'pmessage'==ss or 'subscribe'==ss then
				if 'message'==ss or 'pmessage'==ss then
					return true
				end
			end
		end
	end
	
	return false
end

function o.on_redis_reply_select(is_push)
	--print('o.on_redis_reply_select',is_push)
	if 0==is_push then
		return o.on_redis_reply()
	else
		return o.on_redis_push()
	end
end

function o.on_redis_push()

	local c_reply = lcf.get_cur_redis_push_msg()
	
	local function foo(c_reply)
		if 1==c_reply.type or 5==c_reply.type then
			return ffi.string(c_reply.str,c_reply.len)
		elseif 3==c_reply.type then
			return tonumber(c_reply.integer)
		elseif 2==c_reply.type then
			local t = {}
			-- 目前仅实现一层，应该也够了
			for i=0,tonumber(c_reply.elements)-1 do
				local aa,bb = foo(c_reply.element[i])
				if aa then
					table.insert(t,aa)
				end
				if bb then
					table.insert(t,bb)
				end
			end
			return t
		elseif 4==c_reply.type then
			return nil
		elseif 6==c_reply.type then
			print(ffi.string(c_reply.str,c_reply.len))
			return nil
		end
	end
	
	local aa = foo(c_reply)
	
	if 'message'==aa[1] or 'pmessage'==aa[1] then
		-- 是订阅消息
		local key = aa[2]
		local msg = aa[3]
		if 'pmessage'==aa[1] then
			key = aa[3]
			msg = aa[4]
		end
		-- 不支持事务，只是一个函数
		local ok,ret = pcall(channel.on_recv,key,msg)
		if false==ok then
			return 1
		else
			return ret
		end
	end
	
end

function o.on_redis_reply()
	--print('box.on_redis_reply',str,strlen)
	local actor_id = tonumber(lcf.cur_actor_id())
	--print('box.on_redis_reply',g_box_id,actor_id)
	local actor = o.get_actor(actor_id)
	
	if nil==actor then
		return 3
	end
	
	-- 只有这个actor是在事务中，才能resume
	if false==transaction.is_in_transaction(actor) then
		print('want to resume a transaction but actor not in transaction')
		return 5
	end
	
	local c_r_reply = lcf.get_cur_redis_reply()
	
	local function foo(c_reply)
		if 1==c_reply.type or 5==c_reply.type then
			return ffi.string(c_reply.str,c_reply.len)
		elseif 3==c_reply.type then
			return tonumber(c_reply.integer)
		elseif 2==c_reply.type then
			local t = {}
			-- 目前仅实现一层，应该也够了
			for i=0,tonumber(c_reply.elements)-1 do
				local aa = foo(c_reply.element[i])
				if 'table'==type(aa) then
					for j=0,#aa do
						table.insert(t,aa[j])
					end
				else
					table.insert(t,aa)
				end
			end
			return t
		elseif 4==c_reply.type then
			return nil
		elseif 6==c_reply.type then
			print(ffi.string(c_reply.str,c_reply.len))
			return nil
		end
	end
	
	local ret = 0
	local bb = foo(c_r_reply)
	if 'table'==type(bb) then
		ret = transaction.wakeup(actor,unpack(bb))
	else
		ret = transaction.wakeup(actor,bb)
	end
	
	return ret
end

o.frame_handle = {}

function o.on_frame()
	for i=1,#o.frame_handle do
		pcall(o.frame_handle[i])
	end
end

function o.register_frame_handle(f)
	table.insert(o.frame_handle,f)
end


function o.add_exit_message(mes_id)
	o.exit_message[tonumber(mes_id)] = 1
end

