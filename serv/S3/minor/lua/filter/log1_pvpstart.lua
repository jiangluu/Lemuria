
function onEvent(binlog,date_and_time)
	local sn,ta_sn = string.match(binlog,'pvpstart,usersn(%d+),targetsn(%d+)')
	if sn and ta_sn then
		print(binlog)
		
		-- 记入mysql日志
		local q = string.format('INSERT into t_pvp (usersn,targetsn,stat,stime) values (%d,%d,0,"%s");',sn,ta_sn,date_and_time)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
		
		return 200
	end
end

