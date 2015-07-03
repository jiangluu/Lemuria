
function onEvent(binlog,date_and_time)
	local sn,lkey,ip = string.match(binlog,'login,(%d+),(%S+),([^,]+)')
	if sn and lkey then
		-- 记入mysql
		print('login',sn,lkey,date_and_time,ip)
		local q = string.format('INSERT into t_login values (0,%d,"%s","%s","%s")',sn,lkey,date_and_time,ip)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
		
		print('affected_rows',mysql.get_affected_rows(1))
		
		return 200
	end
end

