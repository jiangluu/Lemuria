
local o = {}

redis = o


local lcf = ffi.C




o.conn = {}

function o.parse_reply(c_reply)
	if 1==c_reply.type or 5==c_reply.type then
		return ffi.string(c_reply.str,c_reply.len)
	elseif 3==c_reply.type then
		return tonumber(c_reply.integer)
	elseif 2==c_reply.type then
		local t = {}
		-- 目前仅实现一层，应该也够了
		for i=0,tonumber(c_reply.elements)-1 do
			local aa = o.parse_reply(c_reply.element[i])
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


function o.exec_and_reply(cli_index,cformat,...)
	local connection = o.conn[cli_index]
	if nil==connection then
		return false
	end
	
	local re = lcf.redisCommand(connection, cformat,...)
	--print(re)
	if nil~=re then
		-- parse it
		local parsed = o.parse_reply(re)
		
		-- cleanup
		lcf.freeReplyObject(re)
		
		if 'table'~=type(parsed) then
			return true,parsed
		else
			return true,unpack(parsed)
		end
	end
	
	return false
end


function o.test()
	--local connection = lcf.redisConnect('192.168.1.14',16491)
	local connection = lcf.redisConnectWithTimeout2('192.168.1.14',16491,1000)
	connection = ffi.cast('redisContext*',connection)
	print(connection)
	table.insert(o.conn,connection)
	
	
	print(o.exec_and_reply(1, 'set foo 123'))
	
	print(o.exec_and_reply(1, 'get foo'))
	
	print(o.exec_and_reply(1, 'RPOP list1'))
end


--o.test()
