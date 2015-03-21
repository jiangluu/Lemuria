
local lcf = ffi.C

function onMsg()
	local node_id = l_gx_cur_stream_get_slice()
	local port = l_gx_cur_stream_get_slice()
	
	nodes_table[node_id] = {node_id,port,1}
	
	-- TODO: 通知其他可能关心的节点
	
	
	l_gx_simple_ack()
	
	return 0
end
