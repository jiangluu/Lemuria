
local lcf = ffi.C
local ls = require('luastate')

local yield_value = ls.C.LUA_YIELD

local function remote_transaction_start(dest_boxc,func_name,mid,app_context,con_index)
		ls.pushnil(dest_boxc.L)
		ls.setglobal(dest_boxc.L, '__g_cur_context')
		ls.pushnil(dest_boxc.L)
		ls.setglobal(dest_boxc.L, '__g_repush')
		
		local co = ls.newthread(dest_boxc.L)		-- @TODO: coroutine pool
		ls.getglobal(co,func_name)
		local arg_num = 1
		if nil~=app_context then
			ls.pushnumber(co,con_index)
			arg_num = 2
		end
		ls.pushnumber(co,mid)
		
		
		local r = ls.C.lua_resume(co,arg_num)
		if yield_value==r then		-- yield
			
			local td = box.new_transdata(dest_boxc)
			if nil==td then
				error('transdata pool was full')
			end
			
			td.co = co
			if mid>=8000 and mid<8100 then
				td.optype = 0
			else
				td.optype = 1
			end
			
			-- save co to box_co, prevent GC
			ls.rawseti(dest_boxc.L, dest_boxc.stack_at_box_co, td.trans_id)
			
			-- save context
			local src = lcf.gx_get_input_context()
			ffi.copy(td.input_context, src, box.input_context_size)
			if nil~=app_context then
				ffi.copy(td.app_context, app_context, box.app_context_size)
			end
			
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

function OnGXMessage()
	local msg_id = lcf.gx_get_message_id()
	
	if msg_id>=8000 and msg_id<8100 then
		-- internal msg
		lcf.gx_cur_writestream_protect(0)
		local r = jlpcall(remote_transaction_start,boxraid.ad,'on_message_1',msg_id)
		
		ls.getglobal(boxraid.ad.L,'__g_repush')
		local repush = ls.tonumber(boxraid.ad.L,-1)
		ls.pop(boxraid.ad.L,1)
		
		if 0~=repush then
			sendFakeMessage(msg_id,repush)
		end
	else
		-- custom msg
		local ptr = lcf.cur_stream_get_bin(box.app_context_size)
		ptr = ffi.cast('uint16_t*',ptr)
		local con_index = tonumber(ptr[2])
		local box_id = ctb_strategy.get(con_index)
		local boxc = boxraid.getboxc(box_id)
		lcf.gx_cur_stream_push_bin(ffi.cast('const char*',ptr), box.app_context_size)
		lcf.gx_cur_writestream_protect(box.app_context_size)
		
		local r = jlpcall(remote_transaction_start,boxc,'on_message_2',msg_id,ptr,con_index)
		
		lcf.gx_cur_writestream_protect(0)
		
	end
	
	return 0
end

-- 内部伪造一个消息
function sendFakeMessage(mid,box_id)
	local boxc = boxraid.getboxc(box_id)
	if nil~=boxc then
		lcf.gx_cur_stream_cleanup()
		lcf.gx_cur_writestream_cleanup()
		local r = jlpcall(remote_transaction_start,boxc,'on_message_1',mid)
	elseif -1==box_id then
		-- 此消息发给所有box
		for i=1,boxraid.box_num+1 do
			local boxc = boxraid.getboxc(i)
			if nil~=boxc then
				lcf.gx_cur_stream_cleanup()
				lcf.gx_cur_writestream_cleanup()
				local r = jlpcall(remote_transaction_start,boxc,'on_message_1',mid)
			end
		end
		
	end
	
	return 0
end

gRemoteCall = remote_transaction_start
