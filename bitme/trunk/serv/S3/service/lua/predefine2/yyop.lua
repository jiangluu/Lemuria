
-- yyop是运营操作

local o = {}

yyop = o


o.handles = {}


local lcf = ffi.C

function o.regHandle(key,f)
	o.handles[key] = f
end

function o.dispatch(msg)
	local key = string.match(msg,'(%w+)')
	if key then
		local f = o.handles[key]
		if f then
			local actor_id = tonumber(lcf.cur_actor_id())
			local ac = box.get_actor(actor_id)
			
			if transaction.is_in_transaction(ac) then
				logg('is_in_transaction at yyop.dispatch')
			else
				transaction.new(ac,f)
				transaction.wakeup(ac,msg)
			end
		end
	end
end


local lock_ban = -10		-- 封号的锁是-10

o.regHandle('yyban',function(ag,msg)
	local usersn,timelen = string.match(msg,'%w+,(%d+),(%d+)')
	if usersn then
		local aa={type='ban',t=l_cur_game_time(),t2=timelen or 300}
		
		box.send_todo(usersn,aa)
		
		ownership.release(usersn,lock_ban,nil,aa.t2)
	end
end)

o.regHandle('yysmail',function(ag,msg)
	local bin = string.match(msg,'yysmail,(.+)')
	if bin then
		local mail = box.unSerialize(bin)
		if nil==mail then
			print('unSerialize failed in yysmail')
		else
			if mail.usersn then
				mail.type2 = mail.type
				mail.type = 'smail'
				box.send_todo(mail.usersn,mail)
			end
		end
	end
end)

o.regHandle('yysmailall',function(ag,msg)
	local bin = string.match(msg,'yysmailall,(.+)')
	if bin then
		local mail = box.unSerialize(bin)
		if nil==mail then
			print('unSerialize failed in yysmailall')
		else
			local redis_global_todo_list = 'lgt'
			
			mail.type2 = mail.type
			mail.type = 'smail'
			
			db.command_and_wait_all('RPUSH %s %s',redis_global_todo_list,box.serialize(mail))
		end
	end
end)

o.regHandle('yybroadcast',function(ag,msg)
	local bin = string.match(msg,'yybroadcast,(.+)')
	if bin then
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(100)
		
		local tt = { type='broadcast',c=bin,d=tonumber(lcf.cur_game_time()) }
		local s = box.serialize(tt)
		lcf.cur_stream_push_string(s,#s)
		
		lcf.cur_stream_broadcast(30)
	end
end)

local prefix_google_bind = 'google_bind_'
local prefix_apple_bind = 'gamecenter_bind_'

o.regHandle('yyunbind',function(ag,msg)
	local usersn = string.match(msg,'%w+,(%d+)')
	if usersn then
		local google_id = db.get(prefix_google_bind..usersn)
		if google_id then
			-- undo bind
			local db_key = 'google+'..google_id
			db.command_and_wait(db.hash(db_key),'DEL %s',db_key)
			db_key = prefix_google_bind..usersn
			db.command_and_wait(db.hash(db_key),'DEL %s',db_key)
			end
			
		local apple_id = db.get(prefix_apple_bind..usersn)
		if apple_id then
			-- undo bind
			local db_key = 'gamecenter'..apple_id
			db.command_and_wait(db.hash(db_key),'DEL %s',db_key)
			db_key = prefix_apple_bind..usersn
			db.command_and_wait(db.hash(db_key),'DEL %s',db_key)
		end
	end
end)

o.regHandle('yynonew',function(ag,msg)
	local usersn = string.match(msg,'%w+,(%d+)')
	if usersn then
		local var = box.load_player_one_block(usersn,'var')
		local basic = box.load_player_one_block(usersn,'basic')
		if var and basic then
			table.travel_sd(sd.wizard,function(t,k)
				if 'name'~=k then
					var.ns[k] = 999
				end
			end)
			
			box.save_player_one_block(usersn,'var',var)
		end
	end
end)

o.regHandle('yycopy',function(ag,msg)
	local usersn,name = string.match(msg,'yycopy,(%d+),(.+)')
	
	if usersn and name then
		local t_com = {'HMGET',usersn}
		for __,kk in pairs(box.user_need_blocks) do
			table.insert(t_com,kk)
		end
		
		local all_data = { db.command_and_wait(db.hash(usersn),table.concat(t_com,' ')) }
		if #all_data>3 then
			-- 认为是一个正常的号
			local me = {}
			for ii,kk in pairs(box.user_need_blocks) do
				local aa = box.unSerialize(all_data[ii])
				me[kk] = aa
			end
			
			box.makesure_all_block_exist(me)
			
			-- assign new usersn
			local new_usersn = tostring(db.command_and_wait(0,'INCR count_usersn'))
			me.basic.usersn = new_usersn
			
			-- 移除社交信息
			me.basic.guild = nil
			me.basic.name = name
			me.var.stat.iscopy = true
			
			-- 保存
			box.do_save_player(me)
			ownership.release(new_usersn,0)
		end
		
	end
end)

o.regHandle('yyrenamesz',function(ag,msg)
	local usersn,name = string.match(msg,'yyrenamesz,(%d+),(.+)')
	if usersn and name then
		local basic_bin = db.hget(usersn,'basic')
		if nil~=basic_bin then
			local basic = box.unSerialize(basic_bin)
			
			basic.name = name
			
			db.hset(usersn,'basic',box.serialize(basic))
		end
	end
end)

o.regHandle('yybindmail',function(ag,msg)
	local usersn,mail,key = string.match(msg,'yybindmail,(%d+),(.-),(%w+)')
	if usersn and mail and key then
		local aa={type='bindmail',a=mail}
		
		box.send_todo(usersn,aa)
	end
end)

-- 下面是todo_handle

box.reg_todo_handle('ban',function(me,dd)
	local now = l_cur_game_time()
	if now <= dd.t+dd.t2 then	-- 如果时间还没有失效
	
		box.do_save_player(me)
		
		local tt = {type='ban',t=dd.t+dd.t2}
		daily.send_systemmsg(tt)
	end
	
	return 0
end)

box.reg_todo_handle('crowd',function(me,dd)

	if me.cache.crowd_other then
		-- 是挤人的人
		return 1
	end
	
	local now = l_cur_game_time()
	if now <= dd.t+20 then
		local tt = {type='crowd',t=dd.t}
		daily.send_systemmsg(tt)
	end
	
	return 0
end)

box.reg_todo_handle('smail',function(me,obj)
	obj.type = obj.type2
	-- 转成客户端希望的格式
	local attachment = {}
	if obj.diamond and obj.diamond>0 then
		table.insert(attachment,{ type=2,num=obj.diamond })
	end
	if obj.meat and obj.meat>0 then
		table.insert(attachment,{ type=0,num=obj.meat })
	end
	if obj.elixir and obj.elixir>0 then
		table.insert(attachment,{ type=1,num=obj.elixir })
	end
	if #attachment>0 then
		obj.list = attachment
	end
	
	local old = daily.incr_version(me,'smail','b',1)
	obj.aid = old+1
	
	me.addition.smail.list = me.addition.smail.list or {}
	
	table.insert(me.addition.smail.list,obj)
	
	return 0
end)

box.reg_todo_handle('bindmail',function(me,dd)
	me.addition.mail = dd.a
	
	return 0
end)
