
local bak = channel

local o = {}

-- 频道
channel = o


local lcf = ffi.C

if nil~=bak then	-- 热更新时保留订阅好的频道
	o.interested = bak.interested
else
	o.interested = {}
end

function o.subscribe(redis_index,key,hd,actor_id)
	key = tostring(key)
	if nil==actor_id then
		actor_id = tonumber(lcf.cur_actor_id())
	end
	
	if nil==o.interested[key] then
		redis.command_and_wait(redis_index,'SUBSCRIBE %s',key)
		o.interested[key] = {}
	end
	o.interested[key][actor_id] = hd
end

function o.publish(redis_index,key,v)
	key = tostring(key)
	v = tostring(v)
	return redis.command_and_wait(redis_index,'PUBLISH %s %b',key,v,ffi.cast('size_t',#v))
end

function o.unsubscribe_all_of_actor(actor_id)
	actor_id = tonumber(actor_id)
	
	for key,hd_list in pairs(o.interested) do
		hd_list[actor_id] = nil
	end
	
end

-- 说明一下思路：Redis订阅和反订阅消息是以一个客户端为单位。我们N个Box  share一个redis客户端，无法天然的做到，以BOX为单位订阅。
-- 所以只要有一个BOX订阅过某个频道，大家都会收到。所以会收到不在自己的 interested列表中的消息，这时简单的忽略即可。
-- 如下面代码所示，消息从Redis-cli分发到BOX，BOX再分发到订阅过的actor
-- 另外隐含非常重要的一点，对于actor来说，这些Redis主动 push过来的消息与 redis-reply不同，并没有一个事务在等着它。
-- 对它的处理只能是：1、启动一个新的事务处理它；2、根本不启用事务概念，只是用一个function处理它了。
-- 这里我们用方法2
function o.on_recv(key,msg)
	local found = false
	
	local aa = o.interested[key]
	if aa then
		for ac,hd in pairs(aa) do
			local actor = box.get_actor(ac)
			if nil==actor then
				-- invalid, remove it
				aa[ac] = nil
			else
				found = true
				pcall(hd,actor,key,msg)
			end
		end
	end
	
	-- extra cleanup
	if false==found and nil~=aa then
		o.interested[key] = nil
	end
	
	if false==found then
		return 0
	else
		return 1
	end
	
end

function o.clear_channel_cb(channel_name)
	if nil~=o.interested[channel_name] then
		o.interested[channel_name] = {}
	end
end


