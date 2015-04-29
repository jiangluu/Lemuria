

-- 这个文件的意义是，把box里的actor理解为游戏中的玩家，并给他一些玩家的操作
-- 这个文件里的内容，略偏向游戏，actor的核心概念在 box.lua里


local lcf = ffi.C


box.user_need_blocks = {
	--'basic','map','hero','lobby','research','achieve','daily','drug','stat','stat_daily','pvpreport1','pvpreport2','cd','jin','buff','story',
	'basic','map','hero','lobby','pvpreport1','pvpreport2','buff','var','addition','llog','depot','pve',
}

box.second_layer_block = {
	var = {'research','drug','stat','stat_daily','cd','jin','stat_s','ns','stat_monthly',},
	addition = {'achieve','daily','story','smail',},
	llog = {'rg','trap'},
}

local redis_global_todo_list = 'lgt'



-- C里会调用
function OfflineAllPlayer()
	local t = {}
	-- 先记下所有的ID
	for actor_id,ac in pairs(box.actors) do
		if 0~=actor_id then
			table.insert(t,actor_id)
		end
	end
	
	local cur_actor_id = tonumber(lcf.cur_actor_id())
	local ac_0 = box.get_actor(cur_actor_id)
	if transaction.is_in_transaction(ac_0) then
		print('ac_0 is busy in OfflineAllPlayer()')
		yylog.log('ac_0 is busy in OfflineAllPlayer()')
	else
		local function _save_all()
			print('OfflineAllPlayer()  begin')
			local count = 0
			for i=1,#t do
				local id = t[i]
				local ac = box.get_actor(id)
				if ac then
					pcall(box.on_player_offline,ac,id)
					count = count+1
				end
			end
			print('OfflineAllPlayer()  end',count)
		end
		
		transaction.new(ac_0,_save_all)
		transaction.wakeup(ac_0)
	end
	
end


function box.serialize(t)
	return tostring(bson.encode(t))
end

function box.unSerialize(bin)
	local a = bson.decode2(bin)
	if not a then
		local stack = debug.traceback()
		print(stack)
		alog.debug(stack)
		return
	else
		return -a
	end
end

function box.get_channel_name()
	return string.format('%sB%d',g_app_id,g_box_id)
end

function box.makesure_all_block_exist(me)
	for ii,kk in pairs(box.user_need_blocks) do
		if nil==me[kk] then
			me[kk] = {}
		end
		
		if nil~=box.second_layer_block[kk] then
			for i3=1,#box.second_layer_block[kk] do
				local aa = box.second_layer_block[kk][i3]
				if nil==me[kk][aa] then
					me[kk][aa] = {}
				end
			end
		end
	end
end


function box.on_player_offline(p,actor_id)
	if nil==actor_id then
		actor_id = tonumber(lcf.cur_actor_id())
	end
	-- save
	if nil~=p.basic then
		local usersn = p.basic.usersn
		
		util.use_update_array(p)
		
		local to_level = 1	-- 取一下王座等级
		util.travalPlayerMap(p,function(m)
			if 'to'==m.type then
				to_level = m.level
				return true
			end
		end)
		p.basic.tol = to_level		-- 把王座等级记在basic里，省的外部要去读map块
		
		p.var.stat_s = p.var.stat_s or {}
		p.var.stat_s.diamond = p.basic.diamond		-- 支持第4类日志
		
		channel.unsubscribe_all_of_actor(actor_id)
		
		
		-- 补救措施，不要坑正在被攻击的人
		check_and_do_battle_end(p,nil)
		
		
		if ownership.is_mine(usersn,p.cache.session) then
			local online_stat = ownership.get_current_stat(usersn) or 0
			if 0==online_stat or -2==online_stat then
				box.do_save_player(p)
				
				-- 下线标记
				local now = l_cur_game_time()
				if p.basic.shield_end_time and now<p.basic.shield_end_time then
					-- 还有护盾
					ownership.release(usersn,p.basic.shield_end_time,p.cache.session)
				else
					ownership.release(usersn,0,p.cache.session)
				end
				
			end
		end
		
		
		local s = string.format('logout,%s,%s',p.basic.usersn,p.var.stat.lkey)
		yylog.log(s)
		
	end
	
	
	-- 下面2步放在最后比较安全
	box.release_actor(actor_id)
	
	-- C里的工作 目前只要计数器减一就可以了
	lcf.box_actor_num_dec(1)
end


function box.do_save_player(p)
			local usersn = p.basic.usersn
			
			local t_com = {'HMSET',usersn}
			local t_value = {}
			
			for __,kk in pairs(box.user_need_blocks) do
				table.insert(t_com,kk)
				table.insert(t_com,'%b')
				local ss = box.serialize(p[kk])
				table.insert(t_value,ss)
				table.insert(t_value,ffi.cast('size_t',#ss))	-- 注意这里有cast转换。这是一个由Lua和ffi共同造成的坑，使用...参数时需要注意
			end
			
			local r = db.command_and_wait(db.hash(usersn),table.concat(t_com,' '),unpack(t_value))
			print('SAVE',usersn,r)
			
			if nil~=p.cache then
			ranklist.add(usersn,p.basic.flag,p.cache.flag_bak)
			else
				ranklist.add(usersn,p.basic.flag)
			end
end


function box.save_all_player()
	for actor_id,actor in pairs(box.actors) do
		if 0~=tonumber(actor_id) then
			pcall(box.do_save_player,actor)
		end
	end
end


function box.load_player_one_block(usersn,block_key)
	usersn = tostring(usersn)
	local dd = db.command_and_wait(db.hash(usersn),'HGET %s %s',usersn,block_key)
	if dd then
		return box.unSerialize(dd)
	end
	return nil
end

function box.save_player_one_block(usersn,block_key,bin)
	usersn = tostring(usersn)
	if 'table'==type(bin) then
		bin = box.serialize(bin)
	end
	return db.command_and_wait(db.hash(usersn),'HSET %s %s %b',usersn,block_key,bin,ffi.cast('size_t',#bin))
end


function box.find_actor_by_usersn(sn)
	for id,ac in pairs(box.actors) do
		if ac.basic and sn==ac.basic.usersn then
			return ac,id
		end
	end
	return nil
end

local guild_redis_index = 2

function box.send_todo(usersn,tt)
	usersn = tostring(usersn)
	local todo_data = box.load_player_one_block(usersn,'todo')
	if nil==todo_data then
		todo_data = { l={} }
	end
	table.insert(todo_data.l,tt)
	box.save_player_one_block(usersn,'todo',todo_data)
	

	-- 访问在线列表得到usersn究竟在哪个频道
	local box_channel = redis.command_and_wait(0,'HGET %s b',usersn)
	if nil==box_channel then
		return false
	end
	local aa = {a='notify_todo',b=usersn}
	return channel.publish(guild_redis_index,box_channel,box.serialize(aa))
end

function box.check_todo(me)
		local usersn = tostring(me.basic.usersn)
		local todo_data = box.load_player_one_block(usersn,'todo')
		if todo_data then
			local left = { l={} }
			for __,dd in pairs(todo_data.l) do
				
				if 'table'==type(dd) then
					local tt = dd
					if tt and tt.type then
						local f = box.todo_handles[tostring(tt.type)]
						if f then
							local ok,ret = pcall(f,me,tt)
							if false==ok then
								print(ret)
								table.insert(left.l,dd)
							elseif 0~=ret then
								table.insert(left.l,dd)
							end
						end
					end
				end
			end
			
			-- reset todo
			box.save_player_one_block(usersn,'todo',left)
		end
end

-- 这个函数是检查global的todo，这些不是已经分派到me的
function box.check_todo_global(me)
	local usersn = tostring(me.basic.usersn)
	local me_version_global_todo = me.basic.vgt or 0
	
	local vv = db.command_and_wait(db.hash(usersn),'LLEN %s',redis_global_todo_list)
	
	vv = vv or 0
	
	if me_version_global_todo<vv then
		for i=me_version_global_todo,vv-1 do
			local dd = db.command_and_wait(db.hash(usersn),'LINDEX %s %s',redis_global_todo_list,tostring(i))
			
			dd = box.unSerialize(dd)
			if nil==dd then
				return
			end
				
				local suc = true
				
				if 'table'==type(dd) then
					local tt = dd
					if tt.type then
						local f = box.todo_handles[tostring(tt.type)]
						if f then
							local ok,ret = pcall(f,me,tt)
							if false==ok then
								print(ret)
								suc = false
							elseif 0~=ret then
								suc = false
							end
						end
					end
				end
			
			if suc then
				me.basic.vgt = i
			else
				return
			end
		end
	end
end

box.todo_handles = {}

function box.reg_todo_handle(key,f)
	box.todo_handles[tostring(key)] = f
end




function box.unpending_pvpreport(p)
	
	for i=1,table.getn(p.pvpreport1.list) do
		local repo = p.pvpreport1.list[i]
		
		if repo.pending then
			p.basic.shield_end_time = repo.sh_time
			p.basic.flag = math.max(p.basic.flag+repo.flag_add,0)
			
			repo.pending = nil
			daily.incr_version(p,'pvpreport1','b')
		end
	end
	
	local max_size = 10
	if p.pvpreport1.list and #p.pvpreport1.list>max_size then
		while #p.pvpreport1.list>max_size do
			table.remove(p.pvpreport1.list,1)
		end
	end
	if p.pvpreport2.list and #p.pvpreport2.list>max_size then
		while #p.pvpreport2.list>max_size do
			table.remove(p.pvpreport2.list,1)
		end
	end
end

function box.post_login(p)
	box.check_todo(p)
	
	box.check_todo_global(p)
	
	util.make_map_aid(p)
	
	box.unpending_pvpreport(p)
	
	RG.RGCreasteLog(p)
	RG.RGCommitLog(p,true)
	
	
	p.cache.flag_bak = p.basic.flag
	
	p.var.stat_s = nil	-- cleanup
	
	
	-- 因为新手流程重做。。
	local me = p
	if nil==me.basic.cver then
		if me.var.ns.g_hk and me.var.ns.g_hk>=1 then
			me.var.ns_pass = 1
		else
			-- 回复初始状态
			local usersn = me.basic.usersn
			local ctime = me.basic.create_time
			local session_key = me.cache.session
			local lkey = me.var.stat.lkey
			
			util.initNewPlayer(me)
			
			me.basic.usersn = usersn
			me.basic.create_time = ctime
			
			util.fillCacheData(me)
			
			me.cache.session = session_key
			me.var.stat.lkey = lkey
		end
		
		me.basic.cver = 2
	end
	
	-- for tap4fun
	--p.basic.diamond = math.max(60000,p.basic.diamond)
	
	p.basic.meat = math.floor(p.basic.meat)
	p.basic.elixir = math.floor(p.basic.elixir)
	
	
	util.fillCacheData(p)
	
	-- 如果有公会，注册公会频道
	guild.on_has_guild(p)
	
end

