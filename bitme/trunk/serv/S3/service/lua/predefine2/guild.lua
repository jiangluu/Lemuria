
local o = {}

guild = o


local lcf = ffi.C

local guild_redis_index = 2
local guild_subscribe_redis_index = 3

local guild_incr = 'c_guild'
local guild_flag_zset = 'guild_flag_zset'
local guild_name_hash = 'guild_name_hash'

local function key_to_mkey(k)
	return tostring(k)..'gm'
end


-- 下面开始是Public接口
-- 参数key统一是公会id

-- 根据id得到公会数据
function o.get_guild(key)
	key = tostring(key)
	local v = o.command_and_wait('GET %s',key)
	if nil==v then
		return nil
	end
	return box.unSerialize(v)
end

-- 保存公会数据
function o.set_guild(key,v)
	key = tostring(key)
	local bb = box.serialize(v)
	return o.command_and_wait('SET %s  %b',key,bb,ffi.cast('size_t',#bb))
end

-- 得到此公会所有成员的数据，以一个数组的形式返回
function o.get_all_member(key)
	key = tostring(key)
	local aa = {o.command_and_wait('LRANGE %s 0 -1',key_to_mkey(key))}
	for i=1,#aa do
		local bb = aa[i]
		aa[i] = box.unSerialize(bb)
	end
	
	return aa
end

function o.get_position(key,usersn)
	
	local member = o.get_all_member(key)
	for i=1,#member do
		if usersn==member[i].usersn then
				
			return member[i].position
		end
	end
		
	return -1
end

-- 保存某个公会成员的数据
function o.set_member(key,member_index,v)
	key = tostring(key)
	member_index = member_index-1	-- begin with 0
	local bb = box.serialize(v)
	
	return o.command_and_wait('LSET %s %d %b',key_to_mkey(key),ffi.cast('int',member_index),bb,ffi.cast('size_t',#bb))
end

-- 添加一个新的公会成员
function o.add_new_member(key,v)
	key = tostring(key)
	local bb = box.serialize(v)
	
	return o.command_and_wait('RPUSH %s %b',key_to_mkey(key),bb,ffi.cast('size_t',#bb))
end

function o.remove_member(key,member_index)
	key = tostring(key)
	member_index = member_index-1	-- begin with 0
	
	-- 由于redis没有提供直接删除指定index处元素的指令，只能用如下方式曲线救国
	o.command_and_wait('LSET %s %d %s',key_to_mkey(key),ffi.cast('int',member_index),'__removed')
	o.command_and_wait('LREM %s 0 %s',key_to_mkey(key),'__removed')
end


-- 创建新公会前，分配新的id
function o.get_new_guild_id()
	local aa = o.command_and_wait('INCR %s',guild_incr)
	return tostring(aa)
end

function o.remove_guild(key)
	key = tostring(key)
	o.command_and_wait('DEL %s',key_to_mkey(key))
	local r = o.command_and_wait('DEL %s',key)
	o.command_and_wait('ZREM %s %s',guild_flag_zset,key)
	
	return r
end


function o.get_guild_recommand_list(num,flag_min,flag_max)
	flag_min = flag_min or 0
	flag_max = flag_max or 50
	local all_data = { o.command_and_wait('ZRANGEBYSCORE %s %s %s ',guild_flag_zset,tostring(flag_min),tostring(flag_max)) }
	local get_num = #all_data
	if get_num>num then
		table.shuffle_array(all_data)
		get_num = num
	end
	
	local t_com = {'MGET'}
	for i=1,get_num do
		table.insert(t_com,all_data[i])
	end
	all_data = { o.command_and_wait(table.concat(t_com,' ')) }
	
	for i=1,#all_data do
		local bb = all_data[i]
		all_data[i] = box.unSerialize(bb)
	end
	
	return all_data
end

function o.get_ranking(begin,endd)
	
	local all_data = { o.command_and_wait('ZREVRANGE %s %s %s ',guild_flag_zset,tostring(begin),tostring(endd)) }
	
	if 0==#all_data then
		return
	end
	
	local t_com = {'MGET'}
	for i=1,#all_data do
		table.insert(t_com,all_data[i])
	end
	all_data = { o.command_and_wait(table.concat(t_com,' ')) }
	
	for i=1,#all_data do
		local bb = all_data[i]
		all_data[i] = box.unSerialize(bb)
	end
	
	return all_data
end


function o.query_my_rank(key,offset)
	if nil==key then
		return
	end
	
	local aa = o.command_and_wait('ZREVRANK %s %s',guild_flag_zset,tostring(key))
	if nil==aa then
		return
	end
	
	aa = aa+1
	local begin = math.max(1,aa-offset)
	local endd = aa+offset
	
	local dd = o.get_ranking(begin,endd)
	return aa,dd
end


function o.update_guild(key)
	key = tostring(key)
	if nil == key then
		error('invalid param')
	end
	
	--获取公会信息
	local basic = o.get_guild(key)
	if nil == basic then
		error('fetch failed')
	end
	
		--清除离开24小时的成员
	local member = o.get_all_member(key)
	if nil == member then
		error('fetch failed')
	end
	
	local now = tonumber(lcf.cur_game_time())
	
	local fire = 0
	local memberNum=0
	for i = 1,#member do
		if nil ~= member[i].leave_time then			
			if now - member[i].leave_time >= 86400 then
				o.remove_member(key,i - fire)
				fire = fire + 1			
			end
		else 
			memberNum=memberNum+1
		end
	end
	
	if fire>0 then
		member = o.get_all_member(key)
	end
	
	basic.num = memberNum
	
	--更新旗子数
	for i=1,#member do
		local sn = member[i].usersn
		local bin = db.hget(sn,'basic')
		local the_basic = box.unSerialize(bin)
		if the_basic and the_basic.flag~=member[i].flag then
			member[i].flag = the_basic.flag
			o.set_member(key,i,member[i])
		end
	end
	
	table.sort(member,function(a,b)
		if a.flag > b.flag then
			return true
		else
			return false
		end
	end)
	
	local flag = 0
	for i = 1,#member do
		if i <= 10 then
			flag = flag + member[i].flag * 0.5
		elseif i <= 20 then
			flag = flag + member[i].flag * 0.25
		elseif i <= 30 then
			flag = flag + member[i].flag * 0.12
		elseif i <= 40 then
			flag = flag + member[i].flag * 0.1
		else
			flag = flag + member[i].flag * 0.03
		end
	end
	
	basic.flag_sum = flag
	
		--更新数据
	if nil == o.set_guild(key,basic) then
		error('save failed')
	end
	
	o.command_and_wait('ZADD %s %s %s',guild_flag_zset,tostring(flag),key)
	
	return 0
end

-- Public接口End


function o.command_and_wait(formatt,...)
	return redis.command_and_wait(guild_redis_index,formatt,...)
end


function o.on_has_guild(p)
	if nil~=p.basic.guild then
		local function id_to_channel_name(a)
			return 'gc'..a
		end
		
		local function cb(me,mkey,msg)
			if nil==me.heap then
				me.heap = {}
			end
			if nil==me.heap.chat then
				me.heap.chat = {}
			end
			
			table.insert(me.heap.chat,{key,msg})
		end
	
		local key = p.basic.guild.id
		channel.subscribe(guild_subscribe_redis_index,id_to_channel_name(key),cb)
	end
end

local guild_history_max_lenth = 200

function o.publish_msg(guild_id,typee,msg)
	if nil==guild_id or nil==msg then
		return false
	end
	
	local list_name = nil
	if 1==typee then
		list_name = 'gla'..guild_id
	elseif 2==typee then
		list_name = 'glb'..guild_id
	elseif 3==typee then
		list_name = 'glc'..guild_id
	elseif 4==typee then
		-- nothing
	else
		return false
	end
	
	if 4~=typee then
		local lenth = o.command_and_wait('RPUSH %s %b',list_name,msg,ffi.cast('size_t',#msg))
		if lenth>guild_history_max_lenth then
			o.command_and_wait('LPOP %s',list_name)
		end
	end
	
	local key = 'gc'..guild_id
	return channel.publish(guild_redis_index,key,msg)
	
end

function o.del_msg(guild_id,typee,index)
	if nil==guild_id or nil==index then
		return false
	end
	
	local list_name = nil
	if 1==typee then
		list_name = 'gla'..guild_id
	elseif 2==typee then
		list_name = 'glb'..guild_id
	elseif 3==typee then
		list_name = 'glc'..guild_id
	else
		return false
	end
	
	-- 由于redis没有提供直接删除指定index处元素的指令，只能用如下方式曲线救国
	o.command_and_wait('LSET %s %d %s',list_name,ffi.cast('int',index-1),'__removed')
	o.command_and_wait('LREM %s 0 %s',list_name,'__removed')
end

function o.modify_msg(guild_id,typee,index,value)
	if nil==guild_id or nil==index then
		return false
	end
	
	local list_name = nil
	if 1==typee then
		list_name = 'gla'..guild_id
	elseif 2==typee then
		list_name = 'glb'..guild_id
	elseif 3==typee then
		list_name = 'glc'..guild_id
	else
		return false
	end
	
	if 'table'==type(value) then
		value = box.serialize(value)
	end
	o.command_and_wait('LSET %s %d %b',list_name,ffi.cast('int',index-1),value,ffi.cast('size_t',#value))
end


function o.pull_msg(guild_id,typee,from,endd,need_rev)
	if nil==guild_id then
		return nil
	end
	
	local list_name = nil
	if 1==typee then
		list_name = 'gla'..guild_id
	elseif 2==typee then
		list_name = 'glb'..guild_id
	elseif 3==typee then
		list_name = 'glc'..guild_id
	else
		return nil
	end
	
	local aa = {o.command_and_wait('LRANGE %s %s %s',list_name,tostring(-endd),tostring(-from))}
	if true==need_rev then
		local rev = {}
		for i=#aa,1,-1 do
			table.insert(rev,aa[i])
		end
		return rev
	end
	return aa
end

-- 按照原始顺序pull
function o.pull_msg2(guild_id,typee,from,endd)
	if nil==guild_id then
		return nil
	end
	
	local list_name = nil
	if 1==typee then
		list_name = 'gla'..guild_id
	elseif 2==typee then
		list_name = 'glb'..guild_id
	elseif 3==typee then
		list_name = 'glc'..guild_id
	else
		return nil
	end
	
	local aa = {o.command_and_wait('LRANGE %s %s %s',list_name,tostring(from-1),tostring(endd-1))}
	return aa
end

function o.delete_record(index,me)
	if nil==me.map.list[index].donate_receive then
		return
	end
	
	local don_re=me.map.list[index].donate_receive
	local record={}
	------------处理捐兵记录
	local j_count=0
	local j_notback_count=0		
	
	for i=1,#don_re.list do
		if don_re.list[i].stat==0 then
			j_count=j_count+1
			if don_re.list[i].repay_time<l_cur_game_time() and don_re.list[i].isback==0 then
				j_notback_count=j_notback_count+1
			end			
		end
	end
	--捐赠总数>20
	if j_count>20 then
		--未归还的>20				
		if j_notback_count>20 then
			for i=1,#don_re.list do
				if don_re.list[i].stat==0 and don_re.list[i].repay_time<l_cur_game_time() and  don_re.list[i].isback==1 then
					table.insert(record,i)
				end
			end
		elseif j_notback_count<=20 then				
			--未归还的<=20			
			
			for i=#don_re.list,1,-1 do				
				if don_re.list[i].stat==0 and don_re.list[i].repay_time<l_cur_game_time() and don_re.list[i].isback==1 then											
					table.insert(record,i)
					j_count=j_count-1
					if j_count<=20 then
						break
					end
				end
			end				
		end		
	end
	
	local po=0
	if #record>0 then
		table.sort(record)
		for i=1,#record do	
			table.remove(don_re.list,record[i]-po,me)
			po=po+1
		end
	end		
	--------------------处理接收记录
	record={}
	local co=0
	for i=1,#don_re.list do
		if don_re.list[i].stat==1 and  don_re.list[i].repay_time+1800<l_cur_game_time() then
			co=co+1
		end
	end	
	if co<10 then
		return 
	end
	
	
	for i=#don_re.list,1,-1 do
		if don_re.list[i].stat==1 and  don_re.list[i].repay_time+1800<l_cur_game_time() then
			table.insert(record,i)
			co=co-1
			if co<=10 then
				break
			end
		end
	end
	po=0
	if #record>0 then		
		table.sort(record)
		for i=1,#record do	
			table.remove(don_re.list,record[i]-po)
			po=po+1
		end	
	end			
	me.map.list[index].donate_receive=don_re
	
end
