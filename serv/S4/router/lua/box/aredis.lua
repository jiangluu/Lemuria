
local lcf = ffi.C

local o = {}

redis = o


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
	
	
	local context = lcf.box_cur_context()
	local r = lcf.c_redisAsyncCommand(redis_index,context,formatt,...)
	
	return select(2,coroutine.yield())
end

