
-- 全球排行榜更新
local lcf = ffi.C

local global_phb_redis = 6
local phb_redis_name = 'phb'
local phb_redis_name_bak = 'phb_bak'

function onMsg(me)
	-- if 'S0'==g_app_id then
		-- redis.command_and_wait(global_phb_redis,'RENAME %s %s',phb_redis_name,phb_redis_name_bak)
	-- end
	
	ranklist.global_phb_fill()
	
	print('global_phb_fill()')
	
	l_gx_simple_ack()
	
	return 0
end
