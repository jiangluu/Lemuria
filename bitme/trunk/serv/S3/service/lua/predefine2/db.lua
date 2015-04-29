
local bak = db

local o = {}

db = o

local db_begin_pos = 0


local lcf = ffi.C


local bulk_num = 1024

local function hash_to_bulk(str)	-- 我们先决定hash到哪个“桶”
	if nil~=tonumber(str) then
		return tonumber(str) % bulk_num
	else
		return lcf.string_hash(str) % bulk_num
	end
end

local function db_hash(str)
	-- local bulk_id = hash_to_bulk(str)
	-- local num = bulk_num / 8
	-- local db_id = math.floor(bulk_id / num)	-- 0~127号桶在第一个DB，128~255号桶在第二个DB。。。以此类推
	-- return db_id
	return 0	-- 目前总是hash到0号 db实例
end


o.hash = db_hash

function o.init()
	-- redis连接是box们共享的，所以只有一个box能初始化它们
	if 0 == g_box_id then
		for i=1,#db_port do
			local aa = db_port[i]
			local con = lcf.redis_make_an_connection(aa[1],aa[2])
			assert(nil ~= con)
			
			assert(true == lcf.boxover_set_shared_ptr(db_begin_pos+i-1,con))
			print(string.format('DB[%d] connected',i))
		end
	end
end

function o.get_conn(redis_index)
	if redis_index>= #db_port then
		print('redis_index too big')
		return nil
	end
	
	local aa = lcf.boxover_get_shared_ptr(db_begin_pos+redis_index)
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


function o.set(key,value)
	key = tostring(key)
	return o.command_and_wait(db_hash(key),'SET %s %b',key,value,ffi.cast('size_t',#value))
end

function o.get(key)
	key = tostring(key)
	return o.command_and_wait(db_hash(key),'GET %s',key)
end

function o.hset(key,field,value)
	key = tostring(key)
	field = tostring(field)
	return o.command_and_wait(db_hash(key),'HSET %s %s %b',key,field,value,ffi.cast('size_t',#value))
end

function o.hget(key,field)
	key = tostring(key)
	field = tostring(field)
	return o.command_and_wait(db_hash(key),'HGET %s %s',key,field)
end

function o.command_and_wait_all(formatt,...)
	-- 现在只有一个DB实例
	local con = o.get_conn(0)
	assert(nil~=con)
	
	local r = lcf.box_redis_async_command(con,formatt,...)
	return select(2,transaction.wait())
end


if nil==bak then
	o.init()
end

