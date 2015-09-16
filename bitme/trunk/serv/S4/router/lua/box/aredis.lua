
local lcf = ffi.C

local o = {}

redis = o


local function parse_reply(c_reply)
	if 1==c_reply.type or 5==c_reply.type then
		return ffi.string(c_reply.str,c_reply.len)
	elseif 3==c_reply.type then
		return tonumber(c_reply.integer)
	elseif 2==c_reply.type then
		local t = {}
		-- 目前仅实现一层，应该也够了
		for i=0,tonumber(c_reply.elements)-1 do
			local aa = parse_reply(c_reply.element[i])
			if 'table'==type(aa) then
				for j=0,#aa do
					table.insert(t,aa[j])
				end
			else
				table.insert(t,aa)
			end
		end
		return t
	elseif 4==c_reply.type then
		return nil
	elseif 6==c_reply.type then
		print(ffi.string(c_reply.str,c_reply.len))
		return nil
	end
end

function o.command_and_wait(redis_index,formatt,...)
	-- 做参数类型安全检查
	--[[
	local dd = 8
	local ee = ffi.cast('size_t',dd)
	print(type(ee))										cdata
	print(ffi.istype('size_t',ee),'size_t')	true
	print(ffi.istype('int',ee),'int')				false
	print(ffi.istype('uint32_t',ee),'uint32_t')	true
	--]]
	local pa = { ... }
	local offset = 0
	for cc in string.gmatch(formatt,'%%(%a)') do
		if 'd'==string.lower(cc) then
			offset = offset+1
			if not (ffi.istype('size_t',pa[offset]) or ffi.istype('int',pa[offset])) then
				error('format check failed, need size_t')
			end
		elseif 's'==string.lower(cc) then
			offset = offset+1
			if not ('string'==type(pa[offset]) or ffi.istype('char*',pa[offset])) then
				error('format check failed, need string')
			end
		elseif 'b'==string.lower(cc) then
			offset = offset+2
			local c = pa[offset-1]
			local lenth = pa[offset]
			if not ('string'==type(c) or ffi.istype('char*',c)) then
				error('format check failed, need string and size_t')
			end
			if not (ffi.istype('size_t',lenth) or ffi.istype('int',lenth)) then
				error('format check failed, need string and size_t')
			end
		else
			error('unsupported format '..cc)
		end
	end
	
	
	local context = __g_cur_context
	if nil==context then
		context = coroutine.yield()
	end
	
	local r = lcf.c_redisAsyncCommand(redis_index,context,formatt,...)
	if 0~=r then
		error('redis command error')
	end
	
	local reply = coroutine.yield()
	
	if nil==reply then
		return nil
	end
	
	reply = ffi.cast('redisReply*',reply)
	local ret = parse_reply(reply)
	if 'table'~=type(ret) then
		return ret
	else
		return unpack(ret)
	end
	
end


function o.get(redis_index,key)
	key = tostring(key)
	return o.command_and_wait(redis_index,'GET %s',key)
end

function o.set(redis_index,key,value)
	key = tostring(key)
	value = tostring(value)
	return o.command_and_wait(redis_index,'SET %s %b',key,value,ffi.cast('size_t',#value))
end

