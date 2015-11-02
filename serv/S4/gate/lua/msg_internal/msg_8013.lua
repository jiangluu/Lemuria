
local lcf = ffi.C

function onMsg()
	local node_id = l_gx_cur_stream_get_slice()
	local port = l_gx_cur_stream_get_slice()
	local stat = lcf.gx_cur_stream_get_int16()
	
	l_gx_simple_ack()
	
	-- G0只关心S0
	local me_concern = string.gsub(gGXContextID,'G','S')
	if 1==stat and me_concern==node_id then
		local old = nodes_table[node_id]
		if nil==old or old[4]<1 then
			local r = lcf.gx_make_portal_sync(node_id,port)
			if r<0 then
				print(string.format('make_portal failed. id: %s  port: %s',node_id,port))
				return -1
			end
			
			nodes_table[node_id] = {node_id,port,r,1}
			
			lcf.gx_cur_writestream_cleanup()
			l_gx_cur_writestream_put_slice(gGXContextID)
			l_gx_cur_writestream_put_slice(getMyPort())
			
			lcf.gx_cur_writestream_send_to(r,8011)
			
			print('say HI to',node_id,port,r)
		end
	end
	
	
	return 0
end
