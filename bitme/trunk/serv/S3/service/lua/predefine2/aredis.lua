
local bak = redis

local o = {}

redis = o

local aredis_begin_pos = 400


local lcf = ffi.C



function o.init()
	-- redis连接是box们共享的，所以只有一个box能初始化它们
	if 0 == g_box_id then
		-- 先释放可能存在的老链接
		for i=0,512 do
			local aa = lcf.boxover_get_shared_ptr(i)
			if nil~=aa then
				aa = ffi.cast('redisAsyncContext*',aa)
				lcf.redis_free_an_connection(aa)
				lcf.boxover_set_shared_ptr(i,nil)
			end
		end
	
		for i=1,#redis_port do
			local aa = redis_port[i]
			local con = lcf.redis_make_an_connection(aa[1],aa[2])
			assert(nil ~= con)
			
			assert(true == lcf.boxover_set_shared_ptr(aredis_begin_pos+i-1,con))
		end
	end
end

function o.get_conn(redis_index)
	if redis_index >= #redis_port then
		print('redis_index too big')
		return nil
	end
	
	local aa = lcf.boxover_get_shared_ptr(aredis_begin_pos+redis_index)
	if nil==aa then
		return nil
	end
	
	return ffi.cast('redisAsyncContext*',aa)
end

function o.command_and_wait(redis_index,formatt,...)
	local con = o.get_conn(redis_index)
	assert(nil~=con)
	
	local r = lcf.box_redis_async_command(con,formatt,...)
	return select(2,transaction.wait())
end


function o.set(redis_index,key,value)
	key = tostring(key)
	return o.command_and_wait(redis_index,'SET %s %b',key,value,ffi.cast('size_t',#value))
end

function o.get(redis_index,key)
	key = tostring(key)
	return o.command_and_wait(redis_index,'GET %s',key)
end


if nil==bak then
	o.init()
end

