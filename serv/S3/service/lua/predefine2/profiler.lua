
-- 一些性能数据的收集等

local o = {}

prof = o


local lcf = ffi.C

function o.log(s)
	yylog.log_prof(s)
	print(s)
end


-- 计数器模块
o.t_counter_meta = {}
o.t_counter = {}
o.t_counter_s = {}
o.t_counter_prev_time = {}
o.t_counter_first_time = {}

function o.incr_counter(name,now)	-- 计数器加一
	-- o.update_counter(name,now)
	
	-- o.t_counter[name] = (o.t_counter[name] or 0) + 1
	-- o.t_counter_s[name] = (o.t_counter_s[name] or 0) + 1
end

-- 如果有写出日志就返回true
function o.update_counter(name,now)
	if nil==name then
		return
	end
	
	if nil==now then
		now = tonumber(lcf.cur_game_usec())
	end
	
	if nil==o.t_counter_first_time[name] then
		o.t_counter_first_time[name] = now
	end
	
	local pre_t = o.t_counter_prev_time[name]
	if nil~=pre_t then
		local interval = o.t_counter_meta[name] or 300*1000000
		if now - pre_t>=interval then
			o.log(string.format('counter_%s,usec%d,num%d,TPS%s,totalusec%d,totalnum%d',
				name,now-pre_t,o.t_counter[name],o.t_counter[name]*1000000/(now-pre_t),now-o.t_counter_first_time[name],o.t_counter_s[name]))
			o.t_counter[name] = 0
			o.t_counter_prev_time[name] = now
			
			return true
		end
	else
		o.t_counter_prev_time[name] = now
	end
end


-- 注册一下计数器，主要关心它多久生成一个计数报告
function o.reg_counter(name,interval)
	o.t_counter_meta[name] = interval
end


-- 时间模块
o.t_time_num = {}
o.t_time_sum = {}
o.t_time_max = {}

function o.cur_usec()
	return tonumber(lcf.cur_game_usec())
end

function o.commit_transaction(name,begin_t,now)
	if nil==name or nil==begin_t then
		return
	end
	
	if nil==now then
		now = tonumber(lcf.cur_game_usec())
	end
	
	local r1 = o.update_counter(name,now)
	
	o.t_counter[name] = (o.t_counter[name] or 0) + 1
	o.t_counter_s[name] = (o.t_counter_s[name] or 0) + 1
	
	if true==r1 then
		if nil~=o.t_time_num[name] then
			o.log(string.format('transaction_%s,AT%s,maxT%d',name,o.t_time_sum[name]/o.t_time_num[name],o.t_time_max[name]))
		end
		
		o.t_time_num[name] = 0
		o.t_time_sum[name] = 0
		o.t_time_max[name] = 0
	end
	
	local num = o.t_time_num[name] or 0
	local time_sum = o.t_time_sum[name] or 0
	local max_t = o.t_time_max[name] or 0
	
	o.t_time_num[name] = num+1
	o.t_time_sum[name] = time_sum+(now - begin_t)
	o.t_time_max[name] = math.max(max_t,now - begin_t)
	
end


