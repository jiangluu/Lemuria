
local o = {}

local lcf = ffi.C

function OnInternalMessage()
	local msg_id = lcf.gx_get_message_id()
	local hd = o.handle[msg_id]
	if hd then
		local ok,ret = pcall(hd)
		if ok then
			return ret
		else
			print(ret)
			alog.debug(ret)
			return -1
		end
	else
		print(string.format('msg %d has NO handle',msg_id))
		return -1
	end
end


function regAllHandlers()
	o.handle = {}
	-- 注册消息handler
	local the_dir = g_lua_dir..'msg_internal/'
	for file in lfs.dir(the_dir) do
		local msg_id = string.match(file,'msg_(%d+)%.lua')
		if msg_id then
			onMsg = nil
			jlpcall(dofile,the_dir..file)
			if nil~=onMsg then
				o.handle[tonumber(msg_id)] = onMsg
			end
			onMsg = nil
		end
	end
end

regAllHandlers()
