
function LemuriaParse(buf, pindex)
	local cmd,bodylen,addr,custom_cookie = string.match(buf, 'LEM ([%w_]+) (%d+) ([%w%.:]+) ?(.-)\r\n')
	if nil==cmd or nil==bodylen or nil==addr then
		return -4,0
	end

	print(cmd,bodylen,addr,custom_cookie, "@@")

	local ack = buf.." ACK"
	ffi.C.gx_push_link_buffer(pindex, #ack, ack)

	return 0,#buf
end
