
local lcf = ffi.C

function l_gx_cur_stream_get_slice()
	local a = lcf.gx_cur_stream_get_slice()
	if 0==a.len_ then
		return nil
	end
	
	return ffi.string(a.mem_,a.len_)
end

function l_gx_cur_stream_push_slice(bin)
	return lcf.gx_cur_stream_push_slice2(bin,#bin)
end

function l_gx_cur_writestream_cleanup()
	lcf.gx_cur_writestream_cleanup()
end

function l_gx_simple_ack()
	return lcf.gx_cur_writestream_syncback()
end

