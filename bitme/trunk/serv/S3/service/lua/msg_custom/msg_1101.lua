
local lcf = ffi.C

local o = {}
o.handles = {}

-- from controlpanel  1101
box.reg_handle(1101,function(me)
	
	local skey = l_cur_stream_get_slice()
	local tag = lcf.cur_stream_get_int32()
	local user_cmd = l_cur_stream_get_slice()
	
	local send_ack = function(ack_str)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_string(skey,#skey)
		lcf.cur_stream_push_int32(tag)
		lcf.cur_stream_push_string(user_cmd,user_cmd_len)
		lcf.cur_stream_push_string(ack_str,#ack_str)
		lcf.cur_stream_write_back()
	end
	
	print(1101,skey,user_cmd)
	
	local hd = o.get_handle(user_cmd)
	if hd then
		pcall(hd,send_ack)
	end
	
	return 0
end)


function o.reg_cmd(cmd,func)
	o.handles[tostring(cmd)] = func
end

function o.get_handle(cmd)
	return o.handles[tostring(cmd)]
end


o.reg_cmd('reload handles',function(ack)
	regAllHandlers()
		
	ack('reload success')
end)

o.reg_cmd('reload all',function(ack)
	local ll_call = jlpcall
	
	ll_call(dofile,g_lua_dir.."init.lua")
	
	ack('reload all success')
end)

o.reg_cmd('reconnect redis',function(ack)
	channel.clear_channel_cb(box.get_channel_name())	-- cleanup first
	
	redis.init()
	db.init()
	
	post_init()
	
	ack('reconnect redis success')
end)

o.reg_cmd('onlinenum',function(ack)
	local aa = string.format('online[%d]',box.actor_num()-1)	-- -1是去掉系统占用的0号
	ack(aa)
end)

o.reg_cmd('league start',function(ack)
	league.league_start()
		
	ack('league started')
end)

o.reg_cmd('league end',function(ack)
	league.league_end()
		
	ack('league ended')
end)

o.reg_cmd('save all',function(ack)
	box.save_all_player()
		
	ack('save all')
end)

o.reg_cmd('broadcast',function(ack)
		local msg = l_cur_stream_get_slice()
		print('broadcast',msg)
		
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(100)
		
		local tt = { type='broadcast',c=msg,d=tonumber(lcf.cur_game_time()) }
		local bin = box.serialize(tt)
		lcf.cur_stream_push_string(bin,#bin)
		
		lcf.cur_stream_broadcast(30)
		
	ack('broadcasted')
end)

o.reg_cmd('smail',function(ack)
		local usersn = l_cur_stream_get_slice()
		local type2 = lcf.cur_stream_get_int32()
		local icon = l_cur_stream_get_slice()
		local title = l_cur_stream_get_slice()
		local text = l_cur_stream_get_slice()
		print('smail',usersn,text)
		
		local attachment = {}
		table.insert(attachment,{type=0,num=8})
		table.insert(attachment,{type=1,num=9})
		table.insert(attachment,{type=2,num=10})
		
		box.send_todo(usersn,{type='smail',type2=type2,icon=icon,title=title,text=text,list=attachment})
		
	ack('smail sent')
end)

o.reg_cmd('smail_all_online',function(ack)
		local type2 = lcf.cur_stream_get_int32()
		local icon = l_cur_stream_get_slice()
		local title = l_cur_stream_get_slice()
		local text = l_cur_stream_get_slice()
		
		local o = {type=type2,icon=icon,title=title,text=text}
		
		for actor_id,actor in pairs(box.actors) do
			local me = actor
			if 0~=tonumber(actor_id) and nil~=me.basic then
				
			end
		end
		
		
	ack('not impl')
end)

