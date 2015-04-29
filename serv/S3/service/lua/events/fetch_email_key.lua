
local function gen_random()
	local t = {}
	for i=1,8 do
		local ff = 65+(math.random(100000)%58)
		if ff>=91 and ff<=96 then
			ff = ff+6
		end
		table.insert(t,ff)
	end
	return string.char(unpack(t))
end

function onEvent(me)
	if isServ() then
		local prefix = 'emailkey'
		local key = gen_random()
		local db_key = prefix..me.basic.usersn
		
		redis.command_and_wait(2,'SETEX %s 1800 %s',db_key,key)		-- 时效1800秒
		
		local dd = { key=key }
		local str = box.serialize(dd)
		daily.push_data_to_c('cache.email_key',str)
	end
	
	return 0		
end
