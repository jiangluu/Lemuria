
local function table_print(t)
	if 'table'==type(t) then
		for k,v in pairs(t) do
			print(k,v)
		end
	end
end

function onEvent(binlog,date_and_time)
	local sn,lkey = string.match(binlog,'logout,(%d+),(%S+)')
	if sn and lkey then
		
		print('filter logout',sn,lkey,date_and_time)
		
		-- 先去DB里读此人数据
		local basic_bin,var_bin = db.exec_and_reply(sn,'HMGET %s basic var',tostring(sn))
		print(#basic_bin,#var_bin)
		if basic_bin  then
			local basic_plain = - bson.decode2(basic_bin)
			local var = - bson.decode2(var_bin)
			if var.stat_s then
				--print('var.stat_s  ----------------')
				--table_print(var.stat_s)
			end
			
			print('var.stat  ----------------')
			table_print(var.stat)
			
			local to_level = basic_plain.tol
			
			print(basic_plain.lkey,to_level,basic_plain.flag,basic_plain.meat,basic_plain.elixir)
			
			-- 记入mysql日志
			local bin_var_stat_s = mysql.escape_string(1,bson.encode(var.stat_s))
			local var_bin_s = mysql.escape_string(1,var_bin)
			--print('bin_var_stat_s',bin_var_stat_s)
			local q = string.format('INSERT into t_logout (aid,usersn,lkey,ltime,session_data,var_data) values (0,%d,"%s","%s","%s","%s");',sn,lkey,date_and_time,bin_var_stat_s,var_bin_s)
			local r = mysql.exec(1,q)
			if 0~=r then
				print(mysql.error_str(1))
				return
			end
			
			print('affected_rows',mysql.get_affected_rows(1))
			
			-- 刷新mysql中玩家数据
			q = string.format('REPLACE into t_player values (%d,"%s",%d,%d,%d,%d);',sn,mysql.escape_string(1,basic_plain.name),to_level,basic_plain.flag,basic_plain.meat,basic_plain.elixir)
			r = mysql.exec(1,q)
			if 0~=r then
				print(mysql.error_str(1))
				return
			end
			
			print('affected_rows',mysql.get_affected_rows(1))
		end
		
		
		return 200
	end
end

