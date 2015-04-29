
local lcf = ffi.C



-- ChatNoTarget 	13 	<<(WORD)chat_type<<(string)text 	chat_type:1-本服 text：聊天内容
function onMsg(me)
	
	local chat_type = lcf.cur_stream_get_int16()
	local bin = l_cur_stream_get_slice()
	
	--print('say',bin,bin_len)
	
	if 1==chat_type then
		-- 普通聊天
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(chat_type)
		lcf.cur_stream_push_string(me.basic.name,0)
		lcf.cur_stream_push_int64(tonumber(me.basic.usersn))
		lcf.cur_stream_push_string(bin,#bin)
		--lcf.cur_stream_write_back()
		lcf.cur_stream_broadcast(14)
		
		ach.key_inc4(me,'chatn')
	elseif 2==chat_type then
		-- 公会聊天
		if nil==me.basic.guild then
			return 1
		end
		
		local tt = {type='gchat',a=me.basic.name,b=me.basic.usersn,c=bin,d=l_cur_game_time()}
		tt.pos=guild.get_position(me.basic.guild.id,me.basic.usersn)
		guild.publish_msg(me.basic.guild.id,1,box.serialize(tt))
	end
	
	local function foo(me,mkey,msg)
		if nil==me.heap then
			me.heap = {}
		end
		if nil==me.heap.chat then
			me.heap.chat = {}
		end
		
		table.insert(me.heap.chat,{mkey,msg})
	end
	
	-- for test
	local ch_name = string.match(bin,"^sub (%w+)")
	if ch_name then
		print('SUB',ch_name)
		channel.subscribe(3,ch_name,foo)
		print('SUB END')
	end
	
	local test_todo_usersn = string.match(bin,"^testtodo (%d+)")
	if test_todo_usersn then
		print('test_todo_usersn',test_todo_usersn)
		local o = {type='test1',a='msg1'}
		box.send_todo(test_todo_usersn,o)
		
		o = {type='test1',a='msg2'}
		box.send_todo(test_todo_usersn,o)
		
		
		box.reg_todo_handle('test1',function(me,obj)
			print('test1 handle',obj.a)
		end)
	end
	
	
	return 0
end

