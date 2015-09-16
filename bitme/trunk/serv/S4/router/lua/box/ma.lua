
local o = {}

local bak = nil
if ma then
	bak = ma.actors
end

ma = o		-- ma means manager of actors


o.actors = bak or {}

function o.get(i)
	return rawget(o.actors,tonumber(i))
end

function o.new(i)
	local r = { __id=i }
	rawset(o.actors,tonumber(i),r)
	return r
end

function o.release(i)
	rawset(o.actors,tonumber(i),nil)
end

function o.find_actor_by_usersn(sn)
	for __, u in pairs(o.actors) do
		if nil~=u.basic and sn == u.basic.usersn then
			return u
		end
	end
	
	return nil
end
