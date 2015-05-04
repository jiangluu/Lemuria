

local buf = 0

if isServ() then
	buf = ffi.new('unsigned char[32]')
end

function onEvent(me)
	local item_id,e_sn,e_json,e_time,e_check = getUEParams()	-- UE Param means User Event Param
	
	if nil==e_sn or nil==item_id or nil==e_json or nil==e_time or nil==e_check then
		error('invalid param')
	end
	
	local conf = sd.shop.precious[item_id]
	if nil==conf then
		error('invalid item_id')
	end
	
	if 2~=conf.get_type then
		-- 是月卡，判断CD
		if nil~=me.var.cd.mc and l_cur_game_time()<=me.var.cd.mc then
			error('monthly_card CD ing')
		end
	end
	
	local diamond = conf.get_count
	
	if isServ() then
		-- 防止在todo_handle之前重复提交
		if nil~=me.addition.cpay_log2 then
			for i=1,#me.addition.cpay_log2 do
				if tostring(e_sn) == tostring(me.addition.cpay_log2[i]) then
					return 3
				end
			end
		end
		
		if nil~=me.addition.cpay_log then
			for i=1,#me.addition.cpay_log.list do
				if tostring(e_sn) == tostring(me.addition.cpay_log.list[i]) then
					yylog.log(string.format('cpay duplicated. usersn%d,e_sn%s',me.basic.usersn,e_sn))
					return 3
				end
			end
		end
		
		-- TODO: 验证字符串是否合法
		local s = string.format('%s%s%skingofszsavetheworld',e_sn,item_id,tostring(e_time))
		
		local lcf = ffi.C
		lcf.MD5(s,#s,buf)
		
		local md5_string = ''
		for i=1,16 do
			local a = tonumber(buf[i-1])
			md5_string = md5_string .. string.format('%02x',a)
		end
		
		
		if md5_string~=e_check then
			local qq = string.format('cpay MD5 check failed. usersn%d,e_sn%s,md5%s',me.basic.usersn,e_sn,e_check)
			yylog.log(qq)
			return 2
		end
		
		if nil==me.addition.cpay_log2 then
			me.addition.cpay_log2 = {}
		end
		table.insert(me.addition.cpay_log2,e_sn)
		
		if #me.addition.cpay_log2 > 10 then
			table.remove(me.addition.cpay_log2,1)
		end
	end
	
	
	-- 对账通过才给玩家钻石
	--[[
	util.add(me,'diamond',diamond,'cpay')
	
	if isServ() then
		if nil==me.addition.cpay_log then
			me.addition.cpay_log = { list={} }
			table.insert(me.addition.cpay_log.list,e_sn)
		end
		
		if #me.addition.cpay_log.list > 10 then
			table.remove(me.addition.cpay_log.list,1)
		end
		
		ach.key_inc3(me,'cpay',1)
		
		local s = string.format('cpay,usersn=%d,e_sn=%s,item_id=%s,e_time=%s,e_json=[%s]',
		me.basic.usersn,e_sn,item_id,e_time,e_json)
		yylog.log(s)
	else
		me.var.stat.cpay = 1
	end
	--]]
	
	if isServ() then
		local s = string.format('bill,usersn=%d,item_id=%s,e_json=%s',me.basic.usersn,item_id,e_json)
		yylog._log(2,'billcheck',s)
	end
	
	return 999		-- 充值尚未结束
end


if isServ() then
	local lcf = ffi.C
	
	box.reg_todo_handle('billcheck',function(me,dd)
		
		local ach_cpay = me.var.stat.cpay or 0
		
		local client_code = dd.a
		if 0==tonumber(client_code) and 0==ach_cpay then
			client_code = 999
		end
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(client_code)
		lcf.cur_stream_push_string(dd.c,#dd.c)
		lcf.cur_stream_write_back2(32)
		
		if 0==tonumber(dd.a) then
			local item_id = dd.c
			local conf = sd.shop.precious[item_id]
			if nil==conf then
				print('invalid item_id')
				return 1
			end
			
			if 2==conf.get_type then
				local diamond = conf.get_count
				
				util.add(me,'diamond',diamond,'cpay')
				
				ach.key_inc3(me,'cpayamount',diamond)
			else
				-- 是月卡
				util.add(me,'diamond',1000,'buy_mc')
				
				local old = me.addition.daily.mc_time or l_cur_game_time()
				me.addition.daily.mc_time = old + (sd.misc.default.mc_day*24*3600)
				
				me.var.cd.mc = l_cur_game_time() + (conf.cd_time or 25*24*3600)
				
				ach.key_inc3(me,'cpayamount',1001)
				
				-- update daily
				local ok = false
				for i=1,#me.addition.daily.list do
					local aa = me.addition.daily.list[i]
					if aa.mc then
						aa.stat = math.max(1,aa.stat)
						if aa.mc<=0 then
							aa.mc = sd.misc.default.mc_day
						else
							aa.mc = aa.mc+sd.misc.default.mc_day
						end
						
						ok = true
						
						break
					end
				end
				if not ok then
					-- 加一条新的
					table.travel_sd(sd.daily,function(t,k)
						local conf = t[k]
						
						if 'mc'==conf.spec then
							table.insert(me.addition.daily.list,{id=k,stat=1,a=0,b=conf.value,mc=sd.misc.default.mc_day})
						end
					end)
				end
				
				-- 推送客户端
				local bson_str = box.serialize(me.addition.daily)
				daily.push_data_to_c('addition.daily',bson_str)
				
			end
			
			if nil==me.addition.cpay_log then
				me.addition.cpay_log = { list={} }
				table.insert(me.addition.cpay_log.list,e_sn)
			end
			if #me.addition.cpay_log.list > 10 then
				table.remove(me.addition.cpay_log.list,1)
			end
			
			ach.key_inc3(me,'cpay',1)
			
			
			local s = string.format('cpay2,usersn=%d,e_sn=%s',me.basic.usersn,dd.b)
			yylog.log(s)
			
			
			
			-- 下面是首冲活动
			if 0==ach_cpay then
				local count = 0
				util.travalPlayerMob(me,function(mob,map)
					if 'lm'==mob.type then
						count = count+1
					end
				end)
				local mob_conf = sd.creature['lm']
				
				if count<5 then
					util.travalPlayerMap(me,function(m)
						if m.type == mob_conf.build then
							if nil==m.mob then
								m.mob = { list={} }
							end
							table.insert(m.mob.list,{type='lm',level=m.level,num=1})
							
							return true
						end
					end)
				else
					local times = 30*24*3600
					local mm_end_time = me.basic.steward_end_time
					local now = l_cur_game_time()
					if nil==mm_end_time or mm_end_time<now then
						me.basic.steward_end_time = now+times
					else
						me.basic.steward_end_time = mm_end_time+times
					end
				end
			end
			
			
			daily.push_data_to_c('basic',box.serialize(me.basic))
			
		end
		
		return 0
	end)
end
