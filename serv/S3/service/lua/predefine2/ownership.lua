
local o = {}

ownership = o


-- 因为优先级需要存在value里。这里定一个规则：
-- 小于0的值，其绝对值是优先级。 大于等于0的值，其优先级视为0（最低）


local stat_taken = -2
local stat_lock_by_other = -4

local ownership_time_out = tostring(3600*72)
local session_time_out = tostring(3600*24*30)

local lcf = ffi.C

-- 从65（A）开始，到122（z）
local function gen_session_key()
	local t = {}
	for i=1,16 do
		table.insert(t,65+(math.random(100000)%58))
	end
	return string.char(unpack(t))
end

local function skey(usersn)
	return 'S'..usersn
end

local function value2prority(v)
	v = tonumber(v)
	if nil==v then
		return 0
	end
	
	if v>=0 then
		return 0
	else
		return -v
	end
end


function o.is_mine(usersn,existing_session_key)
	usersn = tostring(usersn)
	
	local aa = redis.get(0,skey(usersn))
	if aa==existing_session_key then
		return true
	end
	
	return false
end

function o.get_current_stat(usersn)
	usersn = tostring(usersn)
	local stat = tonumber(redis.command_and_wait(0,'HGET %s a',usersn))
	return stat
end

function o.take(usersn,new_value,existing_session_key)
	usersn = tostring(usersn)
	new_value = tostring(new_value)
	
	-- 这里严格的说，应该使用redis的事务来实现。
	-- 但是，我们是异步模式，多个actor共享一个redis连接，不能使用redis的事务，因为指令序列都被打乱了。
	local stat = tonumber(redis.command_and_wait(0,'HGET %s a',usersn))
	local prority = value2prority(stat)
	
	-- 注意下面这行是大于等于，所以能顶号
	local could_take = value2prority(new_value)>=prority
	
	if nil==existing_session_key then
		
		if false == could_take then
			return false,stat
		end
			
		local ss = gen_session_key()
		--redis.command_and_wait(0,'SETEX %s %s %s',usersn,ownership_time_out,new_value)
		-- usersn.a - 在线状态  usersn.b - 所在位置
		redis.command_and_wait(0,'HMSET %s a %s b %s',usersn,new_value,box.get_channel_name())
		redis.command_and_wait(0,'EXPIRE %s %s',usersn,ownership_time_out)
		redis.command_and_wait(0,'SETEX %s %s %s',skey(usersn),session_time_out,ss)
		
		return true,ss
		
	else
		if false == could_take then
			return false,stat
		end
		
		if o.is_mine(usersn,existing_session_key) then
			--redis.command_and_wait(0,'SETEX %s %s %s',usersn,ownership_time_out,new_value)
			redis.command_and_wait(0,'HMSET %s a %s b %s',usersn,new_value,box.get_channel_name())
			redis.command_and_wait(0,'EXPIRE %s %s',usersn,ownership_time_out)
			redis.command_and_wait(0,'SETEX %s %s %s',skey(usersn),session_time_out,existing_session_key)
			return true,existing_session_key
		else
			return false,-6
		end
	end
end

function o.lock(usersn,new_value,timeout)	-- 此函数其实既是lock又是unlock，因为实现一样
	usersn = tostring(usersn)
	new_value = tostring(new_value)
	timeout = tonumber(timeout) or ownership_time_out
	
	redis.command_and_wait(0,'HSET %s a %s',usersn,new_value)
	redis.command_and_wait(0,'EXPIRE %s %d',usersn,ffi.cast('int',timeout))
end

function o.release(usersn,new_value,existing_session_key,timeout)
	usersn = tostring(usersn)
	local timeout2 = ownership_time_out
	if timeout then
		timeout2 = tostring(timeout)
	end
	
	if existing_session_key and o.is_mine(usersn,existing_session_key) then
		--redis.command_and_wait(0,'SETEX %s %s %s',usersn,ownership_time_out,tostring(new_value))
		redis.command_and_wait(0,'HMSET %s a %s b %s',usersn,tostring(new_value),box.get_channel_name())
		redis.command_and_wait(0,'EXPIRE %s %s',usersn,timeout2)
	-- 上面一行释放了ownership。 session不用释放，坐等过期
	--redis.command_and_wait(0,'DEL %s',skey(usersn))
	elseif nil==existing_session_key then
		--redis.command_and_wait(0,'SETEX %s %s %s',usersn,ownership_time_out,tostring(new_value))
		redis.command_and_wait(0,'HMSET %s a %s b %s',usersn,tostring(new_value),box.get_channel_name())
		redis.command_and_wait(0,'EXPIRE %s %s',usersn,timeout2)
	end
end


