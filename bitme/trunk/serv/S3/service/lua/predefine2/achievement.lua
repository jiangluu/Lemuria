
-- 成就系统
local o = {}

ach = o		-- ach means achievement


local lcf = ffi.C

function o.test()
	local f = loadstring('return aa*2')
	print(f)
	
	aa = 9
	print('o.test()',f())
	aa = nil
end


function o.post_init()
	table.travel_sd(sd.achieve,function(t,k)
		local v = t[k]
		local ss = 1
		
		if nil==string.match(v.condition,',') then
			ss = string.format('return tonumber(util.%s(player_longlonglong))',v.condition)
		else
			ss = string.gsub(v.condition,',','(player_longlonglong,"')
			ss = string.format('return tonumber(util.%s"))',ss)
		end
		v.func = loadstring(ss)
	end)
end

o.post_init()


function o.check_all(p)
	table.travel_sd(sd.achieve,function(t,k)
		local v = t[k]
		
		player_longlonglong = p		-- 不得已用全局变量
		local err,result = pcall(v.func)
		if false==err then
			--print('achievement condition error',k,v.condition)
			--print(result)
		else
			for ii,vv in pairs(v.info) do
				if result ~= tonumber(vv.init) then
					local ss = string.format('%s_%d',k,ii)
					if nil==p.addition.achieve[ss] then
						p.addition.achieve[ss] = {stat=0,a=vv.init,b=vv.value}
					end
					
					if 0==p.addition.achieve[ss].stat and result~=p.addition.achieve[ss].a then
						jlpcall(o.on_achievement_change,p,ss,result)
						break
					end
				-- else  result == init的是初始值，根本不用处理，也没有这一条数据
				end
			end
		end
		
	end)
end


-- 成就的条件发生改变。注意不等同于成就完成
function o.on_achievement_change(p,cp_key,new_value)
	p.addition.achieve[cp_key].a = new_value
	if new_value >= p.addition.achieve[cp_key].b then
		-- 成就阶段完成
		p.addition.achieve[cp_key].stat = 1
		
		ach.key_inc4(p,'ach')
	end
	
	
	-- 推送客户端
	local bson_str = tostring(bson.encode(p.addition.achieve))
	daily.push_data_to_c('addition.achieve',bson_str)
	
end


-- 新加，与日志支持有关
function o.key_inc3(p,cp_key,incre)		-- 生存期终身类（可以理解为成就）
	if nil==cp_key then
		return
	end
	
	if nil==incre then
		incre = 1
	end
	
	if nil==p.var then
		return
	end
	
	p.var.stat[cp_key] = (p.var.stat[cp_key] or 0) + incre
	
	-- extra
	o.key_inc_daily(p,cp_key,incre)
	o.key_inc4(p,cp_key,incre)
end

function o.key_inc4(p,cp_key,incre)		-- 每session记录类
	if nil==cp_key then
		return
	end
	
	if nil==incre then
		incre = 1
	end
	
	if nil==p.var then
		return
	end
	
	if nil==p.var.stat_s then
		p.var.stat_s = {}
	end
	p.var.stat_s[cp_key] = (p.var.stat_s[cp_key] or 0) + incre
end

function o.key_inc_daily(p,cp_key,incre)
	if nil==cp_key then
		return
	end
	
	if nil==incre then
		incre = 1
	end
	
	if nil==p.var then
		return
	end
	
	if nil==p.var.stat_daily then
		p.var.stat_daily = {}
	end
	p.var.stat_daily[cp_key] = (p.var.stat_daily[cp_key] or 0) + incre
end

