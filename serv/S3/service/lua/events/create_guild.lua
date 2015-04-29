
local guild_name_hash = 'guild_name_hash'

function onEvent(me)
	local name,mark,info,join_way,need_flag,usersn = getUEParams()
	
	if nil == name or nil == mark or nil == info or nil == join_way or nil == need_flag or nil == usersn  then
		error('invalid params')
	end
	
	if nil ~= me.basic.guild then
		error('have guild')
	end
	
	if me.basic.meat < 10000 then
		return 1
	end
	
	if isServ() then
		if not ownership.is_mine(me.basic.usersn,me.cache.session) then
			error('session expired')
		end
		
		
			--创建新公会，保存基本信息
		local id = guild.get_new_guild_id()	
		
		local newGuild = {}
		newGuild.id = id
		newGuild.name = name
		newGuild.times = l_cur_game_time()
		newGuild.mark = mark
		newGuild.info = info
		newGuild.join_way = join_way
		newGuild.need_flag = need_flag
		newGuild.num = 1
		newGuild.flag_sum = me.basic.flag / 2
		
		if nil == guild.set_guild(id,newGuild) then
			error('save guild failed')
		end
		
		local old_value = guild.command_and_wait('HGET %s %s',guild_name_hash,tostring(name))
		old_value = old_value or ''
		local new_value = old_value..tostring(id)..','
		guild.command_and_wait('HSET %s %s %s',guild_name_hash,tostring(name),tostring(new_value))
		
			--将创建者添加到公会，并设为会长
		local play = {}
		play.usersn = usersn
		play.name = me.basic.name
		play.join_time = l_cur_game_time()
		play.flag = me.basic.flag
		play.position = 1
		play.exp = me.basic.exp
		
		if nil == guild.add_new_member(id,play) then
			error('save member failed')
		end
		
		me.basic.guild = {}
		me.basic.guild.id = id
		me.basic.guild.name=name
		me.basic.guild.mark=mark
		me.basic.guild.join_time=l_cur_game_time()
		me.basic.guild.pos=1
		local ss = box.serialize(me.basic.guild)
		daily.push_data_to_c('basic.guild',ss)
		
		box.do_save_player(me)
		
		guild.update_guild(id)
		
		guild.on_has_guild(me)
		
	end
	
	--扣资源
	util.dec(me,'meat',10000,'create_guild')
		--刷新数据
	util.fillCacheData(me)
	
	return 0
end