
-- yylog是运营日志的意思。和程序用的日志不同。

local o = {}

yylog = o

local log_redis_index = 2
local log_list_name = 'log1'


local lcf = ffi.C

function o.log(s)
	return o._log(log_redis_index,log_list_name,s)
end

function o.log_prof(s)
	return o._log(log_redis_index,'logprof',s)
end


function o._log(redis_i,list_name,s)
	s = tostring(s)
	local a = 0
	if 'Windows'~=jit.os then
		a = os.date('%F %T')
	else
		a = os.date('%Y-%m-%d %H:%M:%S')
	end
	s = string.format('%s,%s',a,s)
	local r = lcf.log_write2(1,s,#s)
	
	redis.command_and_wait(redis_i,'LPUSH %s %s',list_name,s)
	
	return r
end

