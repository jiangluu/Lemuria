
function onEvent(binlog,date_and_time)
	local small,usersn,left = string.match(binlog,'verbose_(.-),usersn(%d+),(.+)')
	if small and usersn and left then
		print(binlog)
		
		local q = ''
		if 'pve'~=small then
			local key1,level,meat,elixir,diamond = string.match(left,'(%w+),(%d+),meat(%d+),elixir(%d+),diamond(%d+)')
			if key1 then
				q = string.format('INSERT into t_verbose_general (op,usersn,key1,level,meat,elixir,diamond,ltime) values ("%s",%d,"%s",%d,%d,%d,%d,"%s");',small,usersn,key1,level,meat,elixir,diamond,date_and_time)
			end
		else
			local name,hero,h_equip,h_pet,use_time,add_meat,add_elixir,HP,star,percent = string.match(left,'name_(.-),hero=(%w+),h_equip(.-),h_pet(.-),use_time(%d+),add_meat(%d+),add_elixir(%d+),HP(%d+),star(%d+),percent([^,]+)')
			if name then
				q = string.format('INSERT into t_verbose_pve (usersn,name,hero,h_equip,h_pet,use_time,add_meat,add_elixir,HP,star,percent,ltime) values (%d,"%s","%s","%s","%s",%d,%d,%d,%d,%d,%s,"%s");',usersn,name,hero,h_equip,h_pet,use_time,add_meat,add_elixir,HP,star,percent,date_and_time)
			end
		end
		
		-- 记入mysql日志
		if ''==q then
			print('error',left)
			return
		end
		
		local r = mysql.exec(1,q)
		if 0~=r then
			print(q)
			print(mysql.error_str(1))
			return
		end
		
		print('affected_rows',mysql.get_affected_rows(1))
		
		return 200
	end
end

