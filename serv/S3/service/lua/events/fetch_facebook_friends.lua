
function onEvent(me)
	local table_fb_id = { getUEParams() }
	if 0==#table_fb_id then
		error('invalid param')
	end
	
	if isServ() then
		local ret = { list={} }
		
		for i=1,#table_fb_id do
			local fb_id = table_fb_id[i]
			local key = string.format('facebook%s',fb_id)
			local ta_usersn = db.get(key)
			if nil~=ta_usersn then
				local bb = db.hget(tonumber(ta_usersn),'basic')
				if bb then
					local basic = box.unSerialize(bb)
					if basic.guild then
						table.insert(ret.list,{ usersn=ta_usersn,fb=fb_id,name=basic.name,flag=basic.flag,level=basic.level,guild_id=basic.guild.id,guild_name=basic.guild.name,guild_icon=basic.guild.mark,guild_pos=basic.guild.pos})
					else
						table.insert(ret.list,{ usersn=ta_usersn,fb=fb_id,name=basic.name,flag=basic.flag,level=basic.level})
					end
				end
			end
		end
		
		
		local bin = box.serialize(ret)
		daily.push_data_to_c('cache.facebook_friends',bin)
	end
	
	return 0		
end
