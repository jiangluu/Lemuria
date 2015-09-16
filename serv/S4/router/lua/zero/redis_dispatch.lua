
local ls = require('luastate')
local lcf = ffi.C

local yield_value = ls.C.LUA_YIELD


local function __foo(privdata, reply)
	local td = ffi.cast('TransData*',privdata)
	assert(1==td.is_active)
	assert(td.box_id <= boxraid.box_num)
	
	ls.pushlightuserdata(td.co, td)
	ls.setglobal(td.co, '__g_cur_context')
	ls.pushnil(td.co)
	ls.setglobal(td.co, '__g_repush')
	
	-- restore context
	if 0==td.optype or 1==td.optype then
		local dest = lcf.gx_get_input_context()
		ffi.copy(dest, td.input_context, box.input_context_size)
		lcf.gx_cur_stream_cleanup()
		lcf.gx_cur_writestream_cleanup()
	end
	if 1==td.optype then
		lcf.gx_cur_stream_push_bin(td.app_context, box.app_context_size)
		lcf.gx_cur_writestream_protect(box.app_context_size)
	end
	
	ls.pushlightuserdata(td.co, reply)
	local r = ls.C.lua_resume(td.co, 1)
	if yield_value~=r then
		local boxcdata = boxraid.getboxc(td.box_id+1)
		ls.pushnil(boxcdata.L)
		ls.rawseti(boxcdata.L, boxcdata.stack_at_box_co, td.trans_id)
		
		box.release_transdata(boxcdata,td)
		
		
		local ptr = ffi.cast('uint16_t*',td.app_context)
		local con_index = tonumber(ptr[2])
		ctb_strategy.check_detach(con_index,msg_id)
	end
	
end

local function parse_reply(c_reply)
	if 1==c_reply.type or 5==c_reply.type then
		return ffi.string(c_reply.str,c_reply.len)
	elseif 3==c_reply.type then
		return tonumber(c_reply.integer)
	elseif 2==c_reply.type then
		local t = {}
		-- 目前仅实现一层，应该也够了
		for i=0,tonumber(c_reply.elements)-1 do
			local aa = parse_reply(c_reply.element[i])
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

local yield_value = ls.C.LUA_YIELD

local function remote_on_push(dest_boxc,key,msg)
		ls.pushnil(dest_boxc.L)
		ls.setglobal(dest_boxc.L, '__g_cur_context')
		
		local co = ls.newthread(dest_boxc.L)		-- @TODO: coroutine pool
		ls.getglobal(co,'channel')
		ls.getgetfield(co,-1,'on_recv')
		ls.remove(co,-2)
		
		ls.pushstring(co,key)
		ls.pushstring(co,msg)
		
		local r = ls.C.lua_resume(co,2)
		if yield_value==r then		-- yield
			
			local td = box.new_transdata(dest_boxc)
			if nil==td then
				error('transdata pool was full')
			end
			
			td.co = co
			td.optype = 9
			
			-- save co to box_co, prevent GC
			ls.rawseti(dest_boxc.L, dest_boxc.stack_at_box_co, td.trans_id)
			
			ls.pushlightuserdata(co,td)
			return ls.C.lua_resume(co,1)
			
		elseif 0==r then				-- successful ends
			ls.pop(dest_boxc.L,1)
			return 0
		else									-- there is error
			print(ls.get(co,-1))
			ls.pop(dest_boxc.L,1)
			return r
		end
end

local function __on_push(reply)
	local t = parse_reply(reply)
	
	if 'message'==t[1] or 'pmessage'==t[1] then
		-- 是订阅消息
		local key = t[2]
		local msg = t[3]
		if 'pmessage'==t[1] then
			key = t[3]
			msg = t[4]
		end
		
		local app_id,box_id = string.match(key,'S(%d+)B(%d+)')
		if nil~=app_id and nil~=box_id then
			-- 如果是box频道，尝试进行初步分派
			local boxc = boxraid.getboxc(tonumber(box_id))
			if boxc then
				remote_on_push(boxc, key, msg)
			end
		else
			-- 只能给每个box传递
			for i=1, boxraid.box_num+1 do
				local boxc = boxraid.getboxc(i)
				if boxc then
					remote_on_push(boxc, key, msg)
				end
			end
		end
		
	end
end

local function __is_push(reply)
	if nil~=reply then
		if 2==reply.type and reply.elements>0 then
			if 1==reply.element[0].type then
				local ss = ffi.string(reply.element[0].str,reply.element[0].len)
				-- if 'message'==ss or 'pmessage'==ss or 'subscribe'==ss then
				if 'message'==ss or 'pmessage'==ss then
					return true
				end
			end
		end
	end
	
	return false
end

function OnRedisReply(privdata, reply)
	reply = ffi.cast('redisReply*',reply)
	
	local is_push_msg = __is_push(reply)
	
	lcf.gx_cur_writestream_protect(0)
	
	if false==is_push_msg then
		jlpcall(__foo,privdata, reply)
	else
		jlpcall(__on_push, reply)
	end
	return 0
end

local function redis_init()
	for i=1,#redis_port do
		--local ip,port = string.match(redis_port[i],'([^:]+):(%d+)')
		local ip,port = unpack(redis_port[i])
		if ip and port then
			assert(lcf.add_redis_server(ip,tonumber(port)) >= 0)
		end
	end
end

local ok = jlpcall(redis_init)
if false==ok then
	os.exit(-3)
end
