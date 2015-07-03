
function onEvent(binlog,date_and_time)
	print(date_and_time,binlog)
	
		-- 记入mysql日志
		local q = string.format('INSERT into t_proflog (strtime,content) values ("%s","%s");',date_and_time,binlog)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
	
	return 200
end

