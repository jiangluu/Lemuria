
local guild_name_hash = 'guild_name_hash'

function onEvent(me)
	local the_name = getUEParams()
	
	if nil == the_name then
		error('invalid param')
	end
	
	if isServ() then
		local aa = guild.command_and_wait('HGET %s %s',guild_name_hash,tostring(the_name))
		if nil==aa then
			return 1
		end
		
		local t_com = {'MGET'}
		for id in string.gmatch(aa,'(%d+)') do
			table.insert(t_com,tostring(id))
		end
		local all_data = { guild.command_and_wait(table.concat(t_com,' ')) }
		
		local guild_list = {list = {}}
		for i=1,#all_data do
			table.insert(guild_list.list,box.unSerialize(all_data[i]))
		end
		
		local str = box.serialize(guild_list)
		daily.push_data_to_c('guild_list',str)
	
	end
	
	return 0
end
