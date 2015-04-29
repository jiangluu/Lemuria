
-- 每日任务
local o = {}

daily = o


local lcf = ffi.C


function o.post_init()
	table.travel_sd(sd.daily,function(t,k)
		local v = t[k]
		if v.condition and v.value then
			local ss = 1
			if nil==string.match(v.condition,',') then
				ss = string.format('return tonumber(util.%s(player_longlonglong))',v.condition)
			else
				ss = string.gsub(v.condition,',','(player_longlonglong,"')
				ss = string.format('return tonumber(util.%s"))',ss)
			end
			v.func = loadstring(ss)
		end
	end)
end

o.post_init()

local daily_expire_clock = 21

function o.check_and_give_daily(p)
	local now = os.time()
	
	local need = false
	local absent_day_num = 0
	if nil == p.addition.daily.accept_time then
		need = true
	--elseif now - tonumber(p.addition.daily.accept_time) >= 3600*24 then	-- 超过24小时。。先这么写
	else
		-- 计算过期否
		local m = p.addition.daily.accept_time % (24*3600)
		local config_time = daily_expire_clock * 3600
		local expire_time = p.addition.daily.accept_time - m + config_time
		if m>config_time then
			expire_time = expire_time + (24*3600)
		end
		
		if now >= expire_time then	-- 过期
			need = true
			absent_day_num = math.floor((now - expire_time) / (24*3600))
		end
	end
	
	if need then
		local accept_time_bak = p.addition.daily.accept_time
		
		p.addition.daily.accept_time = now
		p.addition.daily.list = {}
		p.var.stat_daily = {}
		
		local keys = {}
		local N = 6		-- 确保每日出现N个任务（不包括【月卡】及【完成其他任务的任务】） （当前版本N=6）
		local to_lv = 0		-- 王座等级
		util.travalPlayerMap(p,function(m)
			if 'to'==m.type then
				to_lv = m.level
				return true
			end
		end)
		
		local yueka_stat = 0
		local now = l_cur_game_time()
		
		local function is_lv_limit(cf)
			return ((0==tonumber(cf.limited) and to_lv>=cf.lvl_limit) or (1==tonumber(cf.limited) and to_lv==cf.lvl_limit))
		end
		
		table.travel_sd(sd.daily,function(t,k)
			local conf = t[k]
			
			local day_left = -1
			
			if 'mc'==conf.spec then
				if nil~=p.addition.daily.mc_time and now<p.addition.daily.mc_time then
					yueka_stat = 1
					day_left = math.floor((p.addition.daily.mc_time-now)/(24*3600))+1
				end
				
				table.insert(p.addition.daily.list,{id=k,stat=yueka_stat,a=0,b=conf.value,mc=day_left})
			end
		end)
		
		table.travel_sd(sd.daily,function(t,k)
			local conf = t[k]
			
			if 'all'==conf.spec and is_lv_limit(conf) then
				table.insert(p.addition.daily.list,{id=k,stat=0,a=0,b=conf.value})
			end
		end)
		
		table.travel_sd(sd.daily,function(t,k)
			local conf = t[k]
			
			if (nil==conf.spec or ''==conf.spec) and is_lv_limit(conf) then
				table.insert(keys,k)
			end
		end)
		
		if true then
			--凑满N个
			local more = N - (#p.addition.daily.list-2)
			for i=1,more do
				if #keys>0 then
					local aa = math.random(10000) % (#keys)
					local k = keys[aa+1]
					local conf = sd.daily[k]
					
					table.insert(p.addition.daily.list,{id=k,stat=0,a=0,b=conf.value})
					table.remove(keys,aa+1)
				end
			end
		end
		
		-- if yueka_stat>=2 then
			-- 放到最后一条
			-- local yueka_item = table.remove(p.addition.daily.list,1)
			-- table.insert(p.addition.daily.list,yueka_item)
		-- end
		
		-- 判断是否进入一个新的自然月
		local old_month = tonumber(os.date('%m',accept_time_bak))
		local new_month = tonumber(os.date('%m',now))
		if new_month > old_month then
			p.var.stat_monthly = {}
		end
	end
	
	o.sign_after_cleanup(p,absent_day_num)
	o.newbeeSign_after_cleanup(p,absent_day_num)
	o.calendar_after_cleanup(p,absent_day_num)
end


function o.check_all(p)
	if p.addition.daily.list then
		for i=1,#p.addition.daily.list do
			local dd = p.addition.daily.list[i]
			local conf = sd.daily[dd.id]
			
			if 0 == dd.stat then
				player_longlonglong = p		-- 不得已用全局变量
				local err,result = pcall(conf.func)
				
				if false==err then
					-- print('daily condition error',dd.id,conf.condition)
					-- print(result)
				else
					if result ~= dd.a then
						jlpcall(o.on_daily_change,p,i,result)
					end
				end
			end
		end
	end
end


-- 成就的条件发生改变。注意不等同于成就完成
function o.on_daily_change(p,index,new_value)
	p.addition.daily.list[index].a = new_value
	if new_value >= p.addition.daily.list[index].b then
		-- 成就阶段完成
		p.addition.daily.list[index].stat = 1
		
		ach.key_inc4(p,'daily')
	end
	
	
	-- 推送客户端
	local bson_str = tostring(bson.encode(p.addition.daily))
	o.push_data_to_c('addition.daily',bson_str)
end

local daily_sign_max_num = 7

function o.sign_after_cleanup(p,absent_day_num)
	-- if absent_day_num>=1 then
		-- p.addition.daily.sign = 1
		-- p.addition.daily.sign2 = 1
		-- p.var.stat_daily.sign = 1
	if nil==p.var.stat_daily.sign then
		p.var.stat_daily.sign = 1
		local old = p.addition.daily.sign or 0
		p.addition.daily.sign = old+1
		p.addition.daily.sign2 = p.addition.daily.sign2 or 1
		
		if p.addition.daily.sign2>daily_sign_max_num then
			p.addition.daily.sign = 1
			p.addition.daily.sign2 = 1
		end
	end
end

function o.newbeeSign_after_cleanup(p,absent_day_num)	
	if nil==p.var.stat_daily.newbeeSign then
		p.var.stat_daily.newbeeSign = 1
		p.addition.daily.newbeeSign2 = p.addition.daily.newbeeSign2 or 1
	end
end

function o.calendar_after_cleanup(p,absent_day_num)	
	if nil==p.var.stat_monthly.calendar then
		p.var.stat_daily.calendar = nil
		p.addition.daily.calendar2 = nil		
		p.var.stat_monthly.calendar = true
	end	
	if nil==p.var.stat_daily.calendar then
		p.var.stat_daily.calendar = 1
		p.addition.daily.calendar2 = p.addition.daily.calendar2 or 1
	end
end



-- a help function
function o.push_data_to_c(key,value)
	local is_zip = 0
	if #value>=128 then
		value = lz.compress(value)
		is_zip = 1
	end
	
	lcf.cur_write_stream_cleanup()
	lcf.cur_stream_push_int16(0)
	lcf.cur_stream_push_string(key,0)
	lcf.cur_stream_push_int16(is_zip)
	lcf.cur_stream_push_string(value,#value)
	lcf.cur_stream_write_back2(18)
end

function o.send_broadcast_msg(key,msg)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(100)
		
		local tt = { type=key,c=msg,d=tonumber(lcf.cur_game_time()) }
		local bin = box.serialize(tt)
		lcf.cur_stream_push_string(bin,#bin)		
		lcf.cur_stream_write_back2(14)
end

function o.send_broadcast_bson(obj)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(100)		
		local tt = obj
		local bin = box.serialize(tt)
		lcf.cur_stream_push_string(bin,#bin)
		
		lcf.cur_stream_write_back2(14)
end

function o.send_systemmsg(obj)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(100)		
		local tt = obj
		local bin = box.serialize(tt)
		lcf.cur_stream_push_string(bin,#bin)
		
		lcf.cur_stream_write_back2(30)
end


function o.ensure_version(p,key)
	if nil==p.basic.ver then
		p.basic.ver = {}
	end
	
	if nil==p.basic.ver[key] then
		p.basic.ver[key] = { a=1,b=1 }
	end
end

function o.set_version(p,key,a_or_b,v)
	o.ensure_version(p,key)
	
	p.basic.ver[key][a_or_b] = v
end

function o.incr_version(p,key,a_or_b,offset)
	offset = offset or 1
	o.ensure_version(p,key)
	
	local old = p.basic.ver[key][a_or_b]
	p.basic.ver[key][a_or_b] = old + offset
	return old
end

