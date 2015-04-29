
local lcf = ffi.C


-- Trusted-pull 	17 	<<(string)key 	客户端从服务端拉取数据
function onMsg(me)
	
	local key = l_cur_stream_get_slice()
	
	if 'cache'==key then
		util.fillCacheData(me)
	end
	
	if nil==me[key] then
		-- 只要客户端没有被黑，应该不会进这个分支
		return 1
	end
	
	local ss = box.serialize(me[key])
	
	daily.push_data_to_c(key,ss)
	
	return 0
end

