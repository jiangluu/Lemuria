
function onEvent(binlog,date_and_time)
	local usersn,e_sn,item_id,e_time,e_json = string.match(binlog,'cpay,usersn=(%d+),e_sn=(.-),item_id=(%w+),e_time=(%w+),e_json=(.+)')
	if usersn and e_sn and item_id and e_time and e_json then
		print(binlog)
		
		-- 记入mysql日志
		local e_json_esc = mysql.escape_string(1,e_json)
		local q = string.format('INSERT into t_cpay (usersn,e_sn,item_id,e_time,e_json) values (%d,"%s","%s",from_unixtime(%d),"%s");',usersn,e_sn,item_id,e_time,e_json_esc)
		local r = mysql.exec(1,q)
		if 0~=r then
			print(mysql.error_str(1))
			return
		end
		
		return 200
	end
end

