
function onEvent(binlog,date_and_time)
	local sn,ta_sn,all_left = string.match(binlog,'pvp,usersn(%d+),targetsn(%d+),(.+)')
	if sn and ta_sn and all_left then
		print(binlog)
		
		-- 记入mysql日志
		local q = string.format('UPDATE t_pvp set stat=1,var="%s",etime="%s" WHERE stat=0 and usersn=%d and targetsn=%d;',
		mysql.escape_string(1,all_left),date_and_time,sn,ta_sn)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
		
		print('affected_rows',mysql.get_affected_rows(1))
		
		return 200
	end
end

