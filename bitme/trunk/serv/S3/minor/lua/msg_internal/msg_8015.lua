
local lcf = ffi.C

function onMsg()
	local node_id = l_gx_cur_stream_get_slice()
	
	l_gx_simple_ack()
	
	local aa = nodes_table[node_id]
	if aa then
		aa[4] = 0
	end
	
	
	return 0
end
