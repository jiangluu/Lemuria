
function PostInit()
	print('zero PostInit')
	local ls = require('luastate')
	
	for i=1,boxraid.box_num do
		local box = boxraid.getboxc(i)
		if nil~=box then
			jlpcall(gRemoteCall,box,'postinit',8000)
		end
	end
	
	-- ===================================
	if nil==gGXContextID or nil==getMyPort() or nil==getRouterID() or nil==getRouterPort() then
		print('NO GXContextID')
		return -1
	end
	
	local lcf = ffi.C
	local r = lcf.gx_make_portal_sync(getRouterID(),getRouterPort())
	if r<0 then
		print('can NOT connect to Router')
		return -1
	end
	
	-- 发送服务自举消息
	l_gx_cur_writestream_cleanup()
	l_gx_cur_stream_push_slice(gGXContextID)
	l_gx_cur_stream_push_slice(getMyPort())
	lcf.gx_cur_writestream_send_to(r,8011)
	
	return 0
	
end
