
local lcf = ffi.C

local hd1 = {}

function on_message_1(mid)
		local hd = hd1[mid]
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
			print(string.format('msg %d has NO handle',mid))
			return -1
		end
end


function regAllHandlers()
	-- 注册消息handler
	local the_dir = g_lua_dir..'msg_internal/'
	for file in lfs.dir(the_dir) do
		local msg_id = string.match(file,'msg_(%d+)%.lua')
		if msg_id then
			onMsg = nil
			jlpcall(dofile,the_dir..file)
			if nil~=onMsg then
				hd1[tonumber(msg_id)] = onMsg
			end
			onMsg = nil
		end
	end
end


-- register internal msgs
regAllHandlers()
