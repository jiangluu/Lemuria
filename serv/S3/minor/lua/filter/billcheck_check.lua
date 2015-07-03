
local lcf = ffi.C

local hd = curl.new()

-- ////////////////////////////////////
local refresh_token_arg = '--data grant_type=refresh_token --data client_id=519274754341-ng9cq2lsh4ve812g7ic2c3io15dq46qp.apps.googleusercontent.com --data client_secret=BKIhze3ycbuo1j2GwmAZmidc --data refresh_token="1/Hwf8OZxGGqhYJPHBWAO87VC8f-9Ic4HHFpnKVor69eA" https://accounts.google.com/o/oauth2/token'
-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



local function send_todo(usersn,tt)
	local todo_data = db.exec_and_reply(tonumber(usersn),'HGET %s todo',tostring(usersn))
	if nil==todo_data then
		todo_data = { l={} }
	else
		todo_data = - bson.decode2(todo_data)
	end
	table.insert(todo_data.l,tt)
	local bin = bson.encode(todo_data)
	db.exec_and_reply(tonumber(usersn),'HSET %s todo %b',tostring(usersn),bin,ffi.cast('size_t',#bin))
	
	
	local connection_onlinelist = lcf.redisConnectWithTimeout2(pipeline_redis_ip,16488,2000)
	connection_onlinelist = ffi.cast('redisContext*',connection_onlinelist)

	table.insert(redis.conn,connection_onlinelist)
	local onlinelist_index = table.getn(redis.conn)	-- 我们的链接是最后一个
	
	
	-- 访问在线列表得到usersn究竟在哪个频道
	local ok,box_channel = redis.exec_and_reply(onlinelist_index,'HGET %s b',tostring(usersn))
	print('box_channel',ok,box_channel)
	
	-- cleanup
	table.remove(redis.conn)
	lcf.redisFree(connection_onlinelist)
	
	
	if not (ok and box_channel) then
		return false
	end
	
	
	local aa = {a='notify_todo',b=usersn}
	bin = bson.encode(aa)
	print('bin',bin)
	print(redis.exec_and_reply(1,'PUBLISH %s %b',box_channel,bin,ffi.cast('size_t',#bin)))
	
	return true
end


function onEvent(binlog,date_and_time)
	local usersn,item_id,e_json = string.match(binlog,'bill,usersn=(%d+),item_id=(%w+),e_json=(.+)')
	if usersn and e_json and item_id then
		print(binlog)
		
		-- 解析e_json串
		local token = string.match(e_json,'"purchaseToken":"([^"]+)"')
		print(token)
		local product_id = string.match(e_json,'"productId":"([^"]+)"')
		print(product_id)
		local order_id = string.match(e_json,'"orderId":"([^"]+)"')
		print(order_id)
		
		if nil==token or nil==product_id or nil==order_id then
			send_todo(usersn,{type='billcheck',a=10,b=order_id,c='df'})
			return 200
		end
		
		
		local google_ret_access_token = curl.http_get(hd,refresh_token_arg)
		print(google_ret_access_token)
		
		local access_token = string.match(google_ret_access_token,'"access_token"%s+:%s+"([^"]+)"')
		if nil==access_token then
			print('get access_token failed')
			send_todo(usersn,{type='billcheck',a=10,b=order_id,c=item_id})
			return 1
		end
		
		
		
		local url = string.format('https://www.googleapis.com/androidpublisher/v2/applications/com.artme.hf/purchases/products/%s/tokens/%s?access_token=%s',product_id,token,access_token)
		
		local google_ret = curl.http_get(hd,url)
		print(google_ret)
		
		local err = 999
		if string.match(google_ret,'"purchaseState":%s+0') then
			-- check passed
			print('check passed')
			
			err = 0
		else
			-- check fail
			print('check fail')
			
			err = 1
		end
		
		-- 记入mysql日志
		local e_json_esc = mysql.escape_string(1,e_json)
		local q = string.format('INSERT into t_cpay (usersn,e_sn,item_id,e_time,checked,e_json) values (%d,"%s","%s",NOW(),%d,"%s");',usersn,order_id,item_id,err+1,e_json_esc)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
		
		send_todo(usersn,{type='billcheck',a=err,b=order_id,c=item_id})
		
		
		return 200
	end
end

