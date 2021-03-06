
local lcf = ffi.C

local hd1 = {}

function on_message_2(con_index, mid, bod)
	print('on_message_2',con_index,mid,bod)
		local hd = hd1[mid]
		if hd then
			local actor = ma.get(con_index)
			if nil==actor then
				actor = ma.new(con_index)
			end

			local f_sendback = function(a)
				a = 'LEM '..mid.."ACK 3\r\n"..tostring(a)
				lcf.gx_push_link_buffer(con_index, #a, a)
			end
			
			local ok,ret = pcall(hd,actor,bod,f_sendback)
			if ok then
				return ret
			else
				print(ret)
				alog.debug(ret)
				return -1
			end
		else
			print(string.format('msg %s has NO handle',mid))
			return -1
		end
end


function regAllHandlers2()
	-- 注册消息handler
	local the_dir = g_lua_dir..'msg_custom/'
	for file in lfs.dir(the_dir) do
		local msg_id = string.match(file,'msg_(%w+)%.lua')
		if msg_id then
			onMsg = nil
			jlpcall(dofile,the_dir..file)
			if nil~=onMsg then
				hd1[tostring(msg_id)] = onMsg
			end
			onMsg = nil
		end
	end
end


-- register custom msgs
regAllHandlers2()
