
local lcf = ffi.C



local function before_offline(me)
	if nil~=me.basic.guild then
		local member = guild.get_all_member(me.basic.guild.id)
		for i=1,#member do
			if member[i].usersn==me.basic.usersn then
				local target=member[i]				
				if target.exp~=me.basic.exp or target.flag~=me.basic.flag or target.name~=me.basic.name then
					target.exp=me.basic.exp
					target.flag=me.basic.flag
					target.name=me.basic.name
					guild.set_member(me.basic.guild.id,i,target)
				end			
				break
			end
		end
	
	end
end


-- Offline 1000
box.reg_handle(1000,function(me)

	pcall(before_offline,me)
	
	box.on_player_offline(me)
	
	return 0
end)


box.add_exit_message(1000)
