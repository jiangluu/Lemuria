
function PostInit()
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
	l_gx_cur_writestream_put_slice(gGXContextID)
	l_gx_cur_writestream_put_slice(getMyPort())
	lcf.gx_cur_writestream_send_to(r,8011)
	
	
	-- TEST
	if 'S1'==gGXContextID then
		l_gx_cur_writestream_cleanup()
		lcf.gx_cur_stream_push_int16(88)
		
		local r = lcf.gx_cur_writestream_route_to('S0',2221)
		print('gx_cur_writestream_route_to',r)
	end
	
	
	return 0
end
