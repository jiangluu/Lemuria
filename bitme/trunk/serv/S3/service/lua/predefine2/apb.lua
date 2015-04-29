
-- Artme pbc

local o = {}

apb = o


local lcf = ffi.C
local filename = 'test.pb'


function o.init()
	-- 初始化环境
	o.env = lcf.pbc_new()
	
	-- 注册proto
	local f = io.open(filename,'rb')
	local text = f:read('*a')
	f:close()
	
	local slice = ffi.new('struct pbc_slice')
	slice.len = #text
	slice.buffer = ffi.cast('void*',text)
	
	lcf.pbc_register(o.env, slice)
	
	-- 准备缓冲
	o.slice = ffi.new('struct pbc_slice')
	o.slice.len = 8192	-- 8192 should be enough
	o.slice.buffer = ffi.new('char[?]',o.slice.len)
	
	-- 准备最常用proto
	o.user = lcf.pbc_wmessage_new(o.env,'Person')
end

function o.begin_push_user()
	o.begin_push(o.user)
end

function o.push_user(key,d)
	o.push(o.user,key,d)
end

function o.end_push_user()
	o.end_push2(o.user)
end

function o.begin_push(m)
	lcf.pbc_wmessage_reset(m)
end

function o.push(m,key,d)
	key = tostring(key)
	if 'number'==type(d) then
		local hi = 0
		if d<0 then
			hi = -1
		end
		lcf.pbc_wmessage_integer(m,key,d,hi)		-- 数字只支持32位
	elseif 'string'==type(d) then
		lcf.pbc_wmessage_string(m,key,d,#d+1)
	end
end

function o.end_push(m)
	local r = lcf.pbc_wmessage_buffer(m,o.slice)
	if nil==r then
		print(ffi.string(lcf.pbc_error(o.env)))
		return nil
	end
	return o.slice
end

-- 把protobuf消息m放入将要发给客户端的stream。方便使用
function o.end_push2(m)
	local s = o.end_push(m)
	if nil==s then
		return false
	end
	
	lcf.cur_stream_push_string(ffi.cast('const char*',s.buffer),s.len)
	return true
end


function o.test1()

	local env = lcf.pbc_new()
	
	local f = io.open('test.pb','rb')
	local text = f:read('*a')
	f:close()
	
	local slice = ffi.new('struct pbc_slice')
	slice.len = #text
	slice.buffer = ffi.cast('void*',text)
	
	print(lcf.pbc_register(env, slice))
	
	local p = lcf.pbc_wmessage_new(env,'Person')
	print(p)
	
	print(lcf.pbc_wmessage_integer(p,'id',8,0))
	local name = 'tomas'
	print(lcf.pbc_wmessage_string(p,'name',name,#name))
	local email = 'aaa'
	print(lcf.pbc_wmessage_string(p,'email',email,#email))
	
	print(lcf.pbc_wmessage_integer(p,'test',11,0))
	print(lcf.pbc_wmessage_integer(p,'test',12,0))
	
	lcf.pbc_wmessage_buffer(p,slice)
	print(ffi.string(slice.buffer,slice.len))
	
	--print(ffi.string(lcf.pbc_error(env)))
	-- 复用
	lcf.pbc_wmessage_reset(p)
	print(lcf.pbc_wmessage_integer(p,'id',8,0))
	local name = 'tomas'
	print(lcf.pbc_wmessage_string(p,'name',name,#name))
	lcf.pbc_wmessage_buffer(p,slice)
	print(ffi.string(slice.buffer,slice.len))
	
	
end

--jlpcall(o.test1)
--o.init()

