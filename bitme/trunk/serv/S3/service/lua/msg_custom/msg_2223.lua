
-- 全球排行榜更新
local lcf = ffi.C

function onMsg(me)
	local guding = l_gx_cur_stream_get_slice()
	local gusersn = l_gx_cur_stream_get_slice()
	local ta_basic = l_gx_cur_stream_get_slice()
	local ta_map = l_gx_cur_stream_get_slice()
	
	if 'phb'==guding and gusersn and ta_basic and ta_map then
		db.hset(gusersn,'basic',ta_basic)
		db.hset(gusersn,'map',ta_map)
		
		l_gx_simple_ack()
	end
	
	return 0
end
