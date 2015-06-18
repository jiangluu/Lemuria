
-- Artme pbc

local o = {}

apb = o


local lcf = ffi.C
local filename = 'proto/user.pb'


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
	
	o.to_free = {}
end

--[[
function o.wrap_cdata_w(cdata)
	if nil==o.__meta_w then
		local function m_newindex(t,k,v)
			o.push(t.__m,k,v)
		end
		
		local function m_tostring(t)
			local aa = o.slice
			local r = lcf.pbc_wmessage_buffer(t.__m,aa)
			if nil==r then
				return nil
			end
			
			return ffi.string(aa.buffer,aa.len)
		end
		
		o.__meta_w = { __newindex=m_newindex,__tostring=m_tostring }
	end
	
	local t = { __m=cdata }
	t = setmetatable(t,o.__meta_w)
	
	return t
end
--]]

function o.new_w(type_name)
	local aa = lcf.pbc_wmessage_new(o.env,type_name)
	table.insert(o.to_free,aa)
	
	return aa
end

function o.clean()
	local num = #o.to_free
	for i=1,num do
		lcf.pbc_wmessage_delete(o.to_free[i])
	end
	for i=1,num do
		table.remove(o.to_free)
	end
end

function o.table_to_wm(t,type_name)
	local aa = nil
	if 'string'==type(type_name) then
		aa = o.new_w(type_name)
	else
		aa = type_name
	end
	
	for k,v in pairs(t) do
		if '_'~=string.sub(k,1,1) then
			if 'table'==type(v) then
				if #v>0 then
					for i=1,#v do
						local child = lcf.pbc_wmessage_message(aa,k)
						if child then
							o.table_to_wm(v[i],child)
						end
					end
				else
					local child = lcf.pbc_wmessage_message(aa,k)
					if child then
						o.table_to_wm(v,child)
					end
				end
			else
				o.push(aa,k,v)
			end
		end
	end
	
	return aa
end

function o.begin_push_user()
	if nil~=o.user then
		lcf.pbc_wmessage_delete(o.user)
		o.user = nil
	end
	o.user = lcf.pbc_wmessage_new(o.env,'User')
end

function o.push_user(key,d)
	o.push(o.user,key,d)
end

function o.end_push_user()
	o.end_push2(o.user)
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

function o.test2()
	print('o.test2()')
	
	local fh = io.open('proto/msg_1.out','r')
	local bin = fh:read('*a')
	fh:close()
	
	o.slice.buffer = ffi.cast('char*',bin)
	o.slice.len = #bin
	
	local cb = ffi.cast('pbc_decoder',function(ud, type1, type_name, pbc_v, id, key)
		print('enter CB')
		if 5==type1 then
			print(type1, ffi.string(type_name), ffi.string(pbc_v.s.buffer), id, ffi.string(key))
		else
			print(type1, ffi.string(type_name), id, ffi.string(key))
		end
		print('CB end')
	end)
	
	local r = lcf.pbc_decode(o.env, 'User' , o.slice, cb, nil);
	cb:free()
	print('END3')
end

--jlpcall(o.test1)
o.init()
jlpcall(o.test2)

