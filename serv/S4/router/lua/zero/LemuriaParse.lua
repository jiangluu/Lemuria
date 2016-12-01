
local pg = require"lpeglj"

function LemuriaParse(buf, pindex)
	print("LemuriaParse")
	print(buf, #buf, pindex)

	
	local aa = pg.P('LEM')
	print(aa:match(buf))

	local ack = buf.." ACK"
	ffi.C.gx_push_link_buffer(pindex, #ack, ack)

	return 0,#buf
end
