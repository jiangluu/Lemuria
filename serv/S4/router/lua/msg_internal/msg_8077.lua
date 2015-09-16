
local lcf = ffi.C


-- AllOffline 8077
function onMsg(me)

	local t = {}
	-- 先记下所有的ID
	for actor_id,ac in pairs(ma.actors) do
		if 0<=actor_id then
			table.insert(t,actor_id)
		end
	end
	
	print('OfflineAllPlayer()  begin')
	local count = 0
	for i=1,#t do
		local id = t[i]
		local ac = ma.get(id)
		if ac then
			pcall(box.on_player_offline,ac,id)
			count = count+1
		end
	end
	print('OfflineAllPlayer()  end',count)
	
	
	return 0
end

