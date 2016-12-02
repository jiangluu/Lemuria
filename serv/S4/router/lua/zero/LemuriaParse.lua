
function LemuriaParse(buf, pindex)
	buf = "LEM cmdhere 3 127.00.1:5566 CUSTOM\r\nBOD"
	local cmd,bodylen,addr,custom_cookie = string.match(buf, 'LEM ([%w_]+) (%d+) ([%w%.:]+) ?(.-)\r\n')
	if nil==cmd or nil==bodylen or nil==addr then
		return -4,0
	end
	bodylen = tonumber(bodylen)

	local pos = string.find(buf,"\r\n")
	print(#buf, pos, #buf-pos-1, "LEN")
	if #buf-pos-1 < bodylen then
		-- it's incomplete
		return 0,0
	end

	local body = string.sub(buf, pos+2, pos+2+bodylen-1)

	print(cmd,bodylen,addr,custom_cookie,body, "@@")

	local box_id = ctb_strategy.get(pindex)
	local boxc = boxraid.getboxc(box_id)
	if nil==boxc then
		return -4, 0
	end
	gRemoteCall(boxc, 'on_message_2',pindex, cmd, body, addr)

	local ack = buf.." ACK"
	ffi.C.gx_push_link_buffer(pindex, #ack, ack)

	return 0,#buf
end
