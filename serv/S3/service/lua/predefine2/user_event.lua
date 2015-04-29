
local o = {}

local lcf = ffi.C

local clo_happened_time = 0



-- 19是User Event。在User Event的范畴内继续分派
box.reg_handle(19,function(actor)
	local log_level = 3
	
	local event_hash = lcf.cur_stream_get_int32()
	clo_happened_time = lcf.cur_stream_get_int32()
	local begin_time = prof.cur_usec()
	
	local hd = o[tonumber(event_hash)]
	if nil==hd then
		print(string.format('userevent handler not found. [%d]',tonumber(event_hash)))
		writebackWrap(1,event_hash)
		return 2
	end
	
	local err,ret = pcall(hd,actor)
	
	if false == err then
		print(ret)
		writebackWrap(1,event_hash)
		local s = string.format('userevent [%d] usersn [%s]  errmsg [%s]',event_hash,actor.basic.usersn,ret)
		lcf.log_write(log_level,tostring(s),#s)
		return 1
	else
		if -10086~=ret then		-- 返回-10086不回包
			writebackWrap(ret,event_hash)
		end
		
		
		if 0==ret then
			-- TODO: 自动处理变化了的数据
		end
		
		local tran_name = string.format('event%d',event_hash)
		prof.incr_counter(tran_name)
		prof.commit_transaction(tran_name,begin_time)
		
		return ret
	end
	
end)



function getUEParams()
	local ret = {}
	
	for i=0,999 do	-- 为了安全起见，不用无限循环
		local is_end = lcf.cur_stream_is_end()
		if true==is_end then
			break
		end
		
		local t = lcf.cur_stream_get_int8()
		if nil==t or 0==t or t>6 then
			error(string.format('invalid T in TV protocol  [%d]',t or 0))
			break
		end
		
		if 1==t then
			table.insert(ret,lcf.cur_stream_get_int16())
		elseif 2==t then
			table.insert(ret,lcf.cur_stream_get_int32())
		elseif 3==t then
			table.insert(ret,lcf.cur_stream_get_int64())
		elseif 4==t then
			table.insert(ret,lcf.cur_stream_get_float32())
		elseif 5==t then
			table.insert(ret,lcf.cur_stream_get_float64())
		elseif 6==t then
			local aa = l_cur_stream_get_slice()
			table.insert(ret,aa or '')
		end
	end
	
	return unpack(ret)
end

function o.regHandle(hash,fn)
	if nil~=fn and 'function'==type(fn) then
		o[tonumber(hash)] = fn
	end
end

function writebackWrap(err,event_hash)
	lcf.cur_write_stream_cleanup()
	lcf.cur_stream_push_int16(err)
	lcf.cur_stream_push_int32(event_hash)
	lcf.cur_stream_write_back()
end


-- @NOTE: getHappenedTime() 如果在应用逻辑里需要调用的话，必须在一开始（先于任何远程调用之前）调用。否则取到的值可能不是本事务的。因为 clo_happened_time 这个变量是所有actor共享的
function getHappenedTime()
	return clo_happened_time
end


function regAllHandlers()
	if isServ() then
		-- 注册消息handler
		for file in lfs.dir(g_lua_dir..'msg/') do
			if string.match(file,'%.lua') then
				jlpcall(dofile,g_lua_dir..'msg/'..file)
			end
		end
		
		-- 注册UserEvent
		for file in lfs.dir(g_lua_dir..'events/') do
			if string.match(file,'%.lua') then
				local aa = string.gsub(file,'%.lua','')
				local hash = lcf.string_hash(aa)
				print(aa,'--->',bson.type(hash))
				
				jlpcall(dofile,g_lua_dir..'events/'..file)
				o.regHandle(hash,onEvent)
				onEvent = nil
			end
		end
	end
end

regAllHandlers()


