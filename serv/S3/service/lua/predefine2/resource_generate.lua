
local o = {}

RG = o

function o.RGCreasteLog(p,now,force_run)
	now = now or l_cur_game_time()
	
	local min_calc_sec = 5	-- 至少时间差不小于这个值才计算，否则认为没有意义
	local gap = 3600
	
	local prev_time = 0
	if isServ() then
		local len2 = #p.llog.rg
		if len2 > 0 then
			prev_time = p.llog.rg[len2].t	-- last time RG
		else
			-- add a log for next call
			-- 下面time1这段是为了兼容老数据
			local time1 = nil
			util.travalPlayerMap(p,function(m)
				if ('hf'==m.type or 'fn'==m.type) and m.last_op_time then
					time1 = m.last_op_time
					return true
				end
			end)
			table.insert(p.llog.rg,{t=(time1 or now),from='RG'})
			prev_time = (time1 or now)
		end
	else
		-- client has NO llog.rg
		if nil==p.cache.rg_time then
			-- 下面time1这段是为了兼容老数据
			local time1 = nil
			util.travalPlayerMap(p,function(m)
				if ('hf'==m.type or 'fn'==m.type) and m.last_op_time then
					time1 = m.last_op_time
					return true
				end
			end)
			
			p.cache.rg_time = (time1 or now)
		end
		prev_time = p.cache.rg_time
	end
	
	if (not force_run) and (now - prev_time < min_calc_sec) then
		return false
	end
	
	
	local batch = {t=now,from='RG',l={}}
	
	local function count(map,key,res_key)
		if key == map.type then
			local o = {}
			o.key = key
			o.lv = map.level
			o.aid = map.aid
			o.gen_speed = sd.scene[key]['detail'][o.lv]['gen_speed']
			o.res_key = res_key
			
			if map.boost_time and prev_time<map.boost_time then		-- 有加速
				if now<=map.boost_time then
					o.is_boost = true
					table.insert(batch.l,o)
				else
					local o2 = table.deepclone(o)	-- 这是有加速的前半段
					o2.is_boost = true
					o2.t2 = map.boost_time
					table.insert(batch.l,o2)
					
					-- 下面是无加速的后半段
					o.t1 = map.boost_time
					table.insert(batch.l,o)
				end
			else		-- 无加速
				table.insert(batch.l,o)
			end
			
			map.last_op_time = now	-- TO BE REMOVED. 现在只是为了兼容老脚本
		end
	end
	
	util.travalPlayerMap(p,function(map)
		count(map,'hf','meat_w')
		count(map,'fn','elixir_w')
	end)
	
	for i=1,#batch.l do
		local o = batch.l[i]
		
		local fix_multi = 0
		-- boost
		if true==o.is_boost then
			fix_multi = fix_multi+1
		end
		-- buff
		if 'meat_w'==o.res_key and nil~=p.buff.f_sd then
			fix_multi = fix_multi+0.03
		elseif 'elixir_w'==o.res_key and nil~=p.buff.f_rd then
			fix_multi = fix_multi+0.03
		end
		
		-- calc
		local times = ((o.t2 or batch.t) - (o.t1 or prev_time)) / gap
		if times<=0 then
			-- something wrong
			if isServ() then
				error(string.format('times<=0  %s %s %s %d',(o.t2 or 'NA'),batch.t,(o.t1 or 'NA'),prev_time))
			else
				return false
			end
		end
		
		local fixed = o.gen_speed * (1+fix_multi) * times
		
		o[o.res_key] = fixed	-- @NOTE：这里不在意是否超过上限；commit时才在意
		
		-- cleanup
		o.gen_speed = nil
		o.is_boost = nil
		o.res_key = nil
	end
	
	-- 最后把 batch记入日志
	if #batch.l>0 then
		if isServ() then
			table.insert(p.llog.rg,batch)
		else
			p.cache.rg_time = now
			g_rg_batch = batch		-- 客户端无奈记在一个全局变量里，没有副作用
		end
	end
	
	return true
end

function o.RGCommitBatch(p,is_real,batch)
	if (not batch.commited) and batch.l then
		
		if 'RG'==batch.from then
			local aa = {}
			
			local function foo(p,batch,res_key)
				for i=1,#batch.l do
					local o = batch.l[i]
					if o[res_key] then
						local carrage = sd.scene[o.key]['detail'][o.lv]['carrage']
						
						util.travalPlayerMap(p,function(m)
							if o.aid==m.aid and o.key==m.type then
								local old = (m[res_key] or 0)
								
								m[res_key] = (m[res_key] or 0) + o[res_key]
								m[res_key] = math.min(m[res_key],carrage)
								m[res_key] = math.max(m[res_key],0)
								
								aa[res_key] = (aa[res_key] or 0) + m[res_key] - old
								
								return true
							end
						end)
					end
				end
			end
			
			foo(p,batch,'meat_w')
			foo(p,batch,'elixir_w')
		
			if is_real then
				batch.commited = true
			end
			
			return (aa.meat_w or 0),(aa.elixir_w or 0)
		elseif 'PVP'==batch.from then
			for i=1,#batch.l do
				local o = batch.l[i]
				
				if o.a then
					local map_index = tonumber(o.a)
					
					local function poo(key)
						if o[key] then
							local the_map = p.map.list[map_index]
							if the_map and the_map[key] then
								the_map[key] = math.max(the_map[key]+o[key],0)
							end
						end
					end
					
					poo('meat_w')
					poo('elixir_w')
				else
					local function foo(key)
						if o[key] and p.basic[key] then
							p.basic[key] = math.max(p.basic[key]+o[key],0)
						end
					end
					
					foo('meat')
					foo('elixir')
				end
			end
			
			if is_real then
				batch.commited = true
			end
			
			return
		end
		
	end
end

function o.RGCommitTrapBatch(p,is_real,batch)
	if (not batch.commited) and batch.l then
		for i=1,#batch.l do
			local o = batch.l[i]
			
			local map_index = tonumber(o.a)
			local trap_index = tonumber(o.b)
			local the_map = p.map.list[map_index]
			if the_map and the_map.trap and #the_map.trap.list>=trap_index then
				the_map.trap.list[trap_index].o = true
			end
		end
		
		if is_real then
			batch.commited = true
		end
	end
end


-- @NOTE: fake commit只能调用一次，且调用以后不能存盘。因为它不消耗log，但是改了basic块
function o.RGCommitLog(p,is_real)
	if isServ() then
		for i=1,#p.llog.rg do
			local batch = p.llog.rg[i]
			if not batch.commited then
				local meat_w,elixir_w = o.RGCommitBatch(p,is_real,batch)
				
				if is_real and 'RG'==batch.from and nil~=meat_w then
					ach.key_inc4(p,'meat_w',meat_w)
					ach.key_inc4(p,'elixir_w',elixir_w)
				end
			end
		end
		
		for i=1,#p.llog.trap do
			local batch = p.llog.trap[i]
			if not batch.commited then
				o.RGCommitTrapBatch(p,is_real,batch)
			end
		end
		
		if is_real then
			-- 只留最后一个类型是RG的，而且目的只是为了她的时间戳而已
			while true do
				local the_last = table.remove(p.llog.rg)
				if nil==the_last then
					break
				elseif 'RG'==the_last.from then
					the_last.commited = true
					p.llog.rg = { the_last }
					break
				end
			end
			
			-- cleanup Trap log
			p.llog.trap = {}
		end
	else
		if g_rg_batch then
			local meat_w,elixir_w = o.RGCommitBatch(p,is_real,g_rg_batch)
			
			if is_real then
				g_rg_batch = nil
			end
		end
	end
end


local __bin = nil

function o.fixOldData(usersn)
	if nil==__bin then
		local llog = {}
		local conf = box.second_layer_block.llog
		for k,v in pairs(conf) do
			llog[v] = {}
		end
		
		__bin = box.serialize(llog)
	end
	
	box.save_player_one_block(usersn,'llog',__bin)
	
	return __bin
end


