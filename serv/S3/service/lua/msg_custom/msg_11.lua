
local lcf = ffi.C



-- HeartBeat
function onMsg(me)
	
	-- 先把一些系统要做的事情做了
	local now = lcf.cur_game_time()
	if nil==yylog.prev_time1 or now>=yylog.prev_time1+60 then
		local s = string.format('BOX%d,online %d',g_box_id,box.actor_num()-1)	-- -1是去掉系统占用的0号
		yylog.log(s)
		
		yylog.prev_time1 = now
	end
	
	-- for safety, save data per 10 min
	if nil==me.cache.__save_t then
		me.cache.__save_t = now
	elseif now>=me.cache.__save_t+600 then
		box.do_save_player(me)
		me.cache.__save_t = now
	end
	
	
	util.heroHPRegen(me,now)
	
	if me.notify_todo then
		box.check_todo(me)
		
		guild.on_has_guild(me)
		
		me.notify_todo = nil
	end
	
	if nil~=me.cache.pvp_start_time and now>=(me.cache.pvp_start_time+420) then
		check_and_do_battle_end(me,nil)
		me.cache.pvp_start_time = nil
	end
	
	-- 刚登录，先把最近的10条消息推送
	-- 移到 fetch_gchat_history.lua 里去了
	--[[
	if 0==me.count_hb and nil~=me.basic.guild then
		local aa = guild.pull_msg(me.basic.guild.id,1,1,10)
		if aa then
			for i=1,#aa do
				lcf.cur_write_stream_cleanup()
				lcf.cur_stream_push_int16(100)
				local dd = aa[i]
				lcf.cur_stream_push_string(dd,#dd)
				lcf.cur_stream_write_back2(14)
			end
		end
	end
	--]]
	
	
	if me.heap then
		if me.heap.chat then
			for i=1,#me.heap.chat do
				lcf.cur_write_stream_cleanup()
				lcf.cur_stream_push_int16(100)
				local aa = me.heap.chat[i][2]
				lcf.cur_stream_push_string(aa,#aa)
				lcf.cur_stream_write_back2(14)
				
			end
			
			me.heap.chat = nil
		end
	end
	
	lcf.cur_write_stream_cleanup()
	lcf.cur_stream_write_back()
	
	return 0
end

