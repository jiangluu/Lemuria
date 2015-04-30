
local lcf = ffi.C

nodes_table = {}	-- 全局节点map

function onMsg()
	local node_id = l_gx_cur_stream_get_slice()
	local port = l_gx_cur_stream_get_slice()
	local portal_index = lcf.gx_get_portal_pool_index()
	
	print('msg8011',node_id,port)
	
	l_gx_simple_ack()
	
	-- TODO: 通知其他可能关心的节点
	for k,v in pairs(nodes_table) do
		if 1==v[4] then		-- 如果在线
			local index = v[3]
			
			lcf.gx_cur_writestream_cleanup()
			l_gx_cur_writestream_put_slice(node_id)
			l_gx_cur_writestream_put_slice(port)
			lcf.gx_cur_stream_push_int16(1)		-- 节点状态
			
			lcf.gx_cur_writestream_send_to(index,8013)
			
			
			lcf.gx_cur_writestream_cleanup()
			l_gx_cur_writestream_put_slice(v[1])
			l_gx_cur_writestream_put_slice(v[2])
			lcf.gx_cur_stream_push_int16(1)		-- 节点状态
			
			lcf.gx_cur_writestream_syncback2(8013)
		end
	end
	
	
	nodes_table[node_id] = {node_id,port,portal_index,1}
	
	lcf.gx_bind_portal_id(portal_index,node_id)
	
	
	return 0
end
