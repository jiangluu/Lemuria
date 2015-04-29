
local lcf = ffi.C


local pvpreport_list_max = 10
local pvp_protect_time_1 = 3600*6
local pvp_protect_time_2 = 3600*8

-- 一些辅助函数，基本从客户端的process.lua拷贝
local function calc_population(map)
	local r = 0
	
	for i=1, #map.list do
		local m = map.list[i]
		if m.mob then
			for j=1, #m.mob.list do
				local a_m = m.mob.list[j]
				a_m.pop = sd.creature[a_m.type].population
				r = r + a_m.pop
			end
		end
	end
	
	return r
end

local function get_to_level(maps)
	for i=1,#maps.list do
		if 'to'==maps.list[i].type then
			return maps.list[i].level
		end
	end
	
	return 1
end

local function calc_recoup(me,who)
	local to_level_player = get_to_level(me.map)
	local to_level_enemy = get_to_level(who.map)

	local diff = to_level_player - to_level_enemy

	if diff > 4 then
		diff = 4
	elseif diff < -3 then
		diff = -3
	end

	for __,v in pairs(sd.battle.default.recoup) do
		if diff == tonumber(v.sub_level) then
			return tonumber(v.recoup)
		end
	end

	return 0
end

-- 给怪身上临时的赋值金丹、肉
local function calc_res(who)
	local res_key = {'meat','elixir','meat_w','elixir_w'}
	
	for j=1,#who.map.list do
		local m = who.map.list[j]

		for i=1,#res_key do
			local res = m[res_key[i]]
			if nil~=res then
				local num_of_mob = 0
				if m.mob then
					num_of_mob = #m.mob.list
				end
				-- test by zy
				local dp = sd.scene[m.type].detail[m.level].protection
				
				if (nil == dp) then
					dp = 0
				end
				
					--厨房、丹房修改百分比
				if 'vt' == m.type then
					
					if (nil ~= who.buff) then
						if nil ~= who.buff.f_od then
							dp = dp + sd.buff['f_od']['formula'][1]['modulus']
						end
					end
				elseif 'kc' == m.type then
					if (nil ~= who.buff) then
						if nil ~= who.buff.f_td then
							dp = dp + sd.buff['f_td']['formula'][1]['modulus']
						end
					end
				end
				
				if num_of_mob>0 then

					local per = math.floor(res/num_of_mob)

					for kk=1,num_of_mob do
						m.mob.list[kk][res_key[i]] = per
						m.mob.list[kk]['protection_s'] = dp
					end
					
					-- 如果不是整除的，最后一个补上1
					if (res/num_of_mob)>per then
						m.mob.list[num_of_mob][res_key[i]] = per+1
					end
				end
			end
		end
	end
end

local function calc_result(me,who)
	local res_key = {'meat','elixir','meat_w','elixir_w'}
	local ret = {}
	local res_w_dec = {}
	local recoup = calc_recoup(me,who)
	local pop_killed = 0
	local pop_killed_f = 0
	local pop_killed_d = 0
	local boss_killed = false
	local total_pop = calc_population(who.map)
	
	if nil==me.inbattle then
		me.inbattle = { kills={} }
	end
	
	local kill_nums = 0
	if me.inbattle.kills then
		kill_nums = #me.inbattle.kills
	end
	
	for i=1,kill_nums do
		local block_index,mob_index = string.match(tostring(me.inbattle.kills[i]),'(%d+),(%d+)')
		if block_index and mob_index then
			local block = who.map.list[tonumber(block_index)]
			if nil~=block and nil~=block.mob then
				local mob = block.mob.list[tonumber(mob_index)]
				
				-- 这个怪挂了，看看它有无携带资源
				if mob and nil==mob.killed then
					--mob.killed = true		会跟随map块一起被记入DB的
					ach.key_inc_daily(me,'kill_'..mob.type,1)
					
					pop_killed = pop_killed + mob.pop
					
					local big_type = sd.creature[mob.type].count_type
					ach.key_inc_daily(me,'kill_'..big_type,1)
					if 'boss'==big_type then
						boss_killed = true
					elseif 'monster'==big_type or 'chief'==big_type then
						pop_killed_d = pop_killed_d + 1
					else
						local sss = string.sub(big_type,1,2)
						if 'w-'==sss or 's-'==sss then
							pop_killed_f = pop_killed_f + 1
						end
					end
					
					for j=1,#res_key do
						if mob[res_key[j]] then
							local mob_protect = tonumber(sd.creature[mob.type].fight[mob.level].protection)
							
							local ret_key = 'get_'..res_key[j]
							
							local to_dec = 0
							if nil==mob_protect then
								to_dec = math.floor(tonumber(mob[res_key[j]]) * recoup * (mob.protection_s))
							elseif string.match(res_key[j],'_w') then
								to_dec = math.floor(tonumber(mob[res_key[j]]) * (mob_protect - mob.protection_s))
							else
								to_dec = math.floor(tonumber(mob[res_key[j]]) * recoup * (mob_protect - mob.protection_s))
							end
							
							mob[res_key[j]] = tonumber(mob[res_key[j]]) - to_dec
							if nil==ret[ret_key] then
								ret[ret_key] = to_dec
							else
								ret[ret_key] = ret[ret_key] + to_dec
							end
							
							if nil==res_w_dec[tonumber(block_index)] then
								res_w_dec[tonumber(block_index)] = {to_dec,res_key[j]}
							else
								res_w_dec[tonumber(block_index)][1] = res_w_dec[tonumber(block_index)][1] + to_dec
							end
							
						end
					end
				end
			end
		end
	end
	
	
	local starcount = 0
	local M = 0
	local K = 60
	
	if boss_killed then
		starcount = 1
		--杀守将数量
		ach.key_inc3(me,'killHero')
	end
	--杀防御型怪数量
	if pop_killed_d > 0 then
		ach.key_inc3(me,'killDef',pop_killed_d)
	end
	--杀功能型怪数量
	if pop_killed_f > 0 then
		ach.key_inc3(me,'killWork',pop_killed_f)
	end
	
	if (pop_killed / total_pop) >= 0.5 then
		starcount = starcount + 1
	end
	if pop_killed>0 and pop_killed==total_pop then
		starcount = 3
	end
	
	ret.starcount = starcount
	ret._percentage = pop_killed / total_pop
	
	if starcount>0 then
		M = 1
	end
	
	local Rn = math.floor(K*(M - (1/(1+10^(-1*(me.basic.flag - who.basic.flag)/400)))))
	
	if Rn>=0 then
		Rn = math.max(Rn,3)
	else
		Rn = math.min(Rn,-3)
	end
	
	
	if 0==starcount then
	
		ret.flag_chg_atk =  (Rn)
		ret.flag_chg_def = -(Rn)

		ret.win = 0
	else
	
		ret.flag_chg_atk =  math.floor((Rn * (starcount/3)))
		ret.flag_chg_def =  -1 * math.floor((Rn * (starcount/3)))

		ret.win = 1
	end
	
	ret.end_time = lcf.cur_game_time()
	ret.use_time = ret.end_time - me.cache.pvp_start_time
	
	
	ret.get_meat = ret.get_meat or 0
	ret.get_elixir = ret.get_elixir or 0
	ret.get_meat_w = ret.get_meat_w or 0
	ret.get_elixir_w = ret.get_elixir_w or 0
	
	
	return ret,res_w_dec
end
-- END


local function print_table(t)
	for k,v in pairs(t) do
		print(k,v)
	end
end


local function do_save_record(me)
	
	if nil==me.inbattle then
		return false
	end
	
	if nil==me.pvpreport2.sn then
		me.pvpreport2.sn = 0
	end
	
	me.pvpreport2.sn = me.pvpreport2.sn + 1	-- 每一次进攻有一个唯一自增编号（对同一个玩家而言）
	
	local function gen_battle_id(attacker_sn,inc)
		return string.format('b%d_%d',attacker_sn,inc)
	end
	
	local battle_id = gen_battle_id(me.basic.usersn,me.pvpreport2.sn)
	
	if nil==me.inbattle.record or 0==string.len(me.inbattle.record) then
		return battle_id
	end
	
	
	local bin = box.serialize(me.cache.pvp_copy)
	
	local r = db.command_and_wait(db.hash(battle_id),'HMSET %s a %b b %b',battle_id,
	bin,ffi.cast('size_t',#bin),
	me.inbattle.record,ffi.cast('size_t',#me.inbattle.record))
	
	
	return battle_id
end


local function do_battle_end(me,c_req)
	
	if nil==me.cache.pvp_usersn or nil==me.cache.pvp_copy or nil==me.cache.pvp_start_time then
		yylog.log(string.format('me.cache.pvp_usersn nil  usersn%d',me.basic.usersn))
		return 1
	end
	
	-- 先记录下录像，再计算得分之类  这样至少“罪证”还在
	local battle_id = do_save_record(me)
	if false==battle_id then
		yylog.log(string.format('pvp-record error,usersn%d,targetsn%d',me.basic.usersn,me.cache.pvp_usersn))
		
		local ta_usersn = tostring(me.cache.pvp_usersn)
		ownership.lock(ta_usersn,0)
		
		return 2
	end
	
	
	local ta_usersn = tostring(me.cache.pvp_usersn)
	local he = me.cache.pvp_copy
	
	ownership.lock(ta_usersn,0)	-- 这是保底释放
	
	
	-- 计算
	calc_res(he)
	local er,battle_result,map_res_modify = pcall(calc_result,me,he)
	if false==er then
	end
	
	local trap_log = me.inbattle.trap_log
	
	me.inbattle = nil	-- 清理
	
	
	-- 比较客户端提交的和自己计算的，如果有出入，记日志。最后用自己计算的值覆盖客户端的
	battle_result.get_meat = battle_result.get_meat + battle_result.get_meat_w
	battle_result.get_elixir = battle_result.get_elixir + battle_result.get_elixir_w
	--计算夺得的肉和金丹
	ach.key_inc3(me,'robMeat',battle_result.get_meat)
	ach.key_inc3(me,'robElixir',battle_result.get_elixir)
	
	
	local my_to_level = 1
	local ta_to_level = 1
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			my_to_level = m.level
			return true
		end
	end)
	util.travalPlayerMap(me.cache.pvp_copy,function(m)
		if 'to'==m.type then
			ta_to_level = m.level
			return true
		end
	end)
	local dur_time = sd.battle.default.info[ta_to_level].dur_time
	local elixir_count = sd.battle.default.info[my_to_level].elixir_count
	
	
	local function check(key,d)
		if math.abs(c_req[key] - battle_result[key])>d then
			yylog.log(string.format('check detail dismatch usersn%d  key[%s] distance[%d]',me.basic.usersn,key,c_req[key] - battle_result[key]))
			c_req[key] = battle_result[key]
			return false
		end
		
		c_req[key] = battle_result[key]
		return true
	end
	
	if c_req then
		check('flag_chg_atk',1)
		check('flag_chg_def',1)
		check('starcount',0)
		check('win',0)
		check('get_meat',10)
		check('get_elixir',10)
		check('_percentage',0.1)
		
		local to_use_elixir = math.floor(c_req.use_time * elixir_count / dur_time)
		--c_req.use_elixir = math.max(c_req.use_elixir,to_use_elixir)
		c_req.use_elixir = math.max(c_req.use_elixir,0)
		c_req.end_time = lcf.cur_game_time()
		
	else
		c_req = table.deepclone(battle_result)
		c_req.end_time = lcf.cur_game_time()
		c_req.stat = 1
		
		util.travalHero(me,function(h)
			if h.inuse then
				c_req.hero_type = h.type
				c_req.hero_lvl = h.level
				return true
			end
		end)
		
		--c_req.use_elixir = math.floor(c_req.use_time * elixir_count / dur_time)
		c_req.use_elixir = 0
		
	end
	
	local ta_basic = he.basic
	local max_meat = ta_basic.meat + (ta_basic.meat_w or 0)
	local max_elixir = ta_basic.elixir + (ta_basic.elixir_w or 0)
	
	
	-- 改被攻击者的数据
	battle_result.get_meat = battle_result.get_meat - battle_result.get_meat_w
	battle_result.get_elixir = battle_result.get_elixir - battle_result.get_elixir_w
	
	-- 都是记日志，不直接修改basic、map等
	local ta_flag_bak = ta_basic.flag
	local me_flag_bak = me.basic.flag
	me.basic.flag = me.basic.flag + c_req.flag_chg_atk
	me.basic.flag = math.max(me.basic.flag,0)
	
	local online_stat = 0
	if c_req._percentage>=0.9 then
		online_stat = l_cur_game_time() + pvp_protect_time_2
	elseif c_req._percentage>=0.4 or c_req.starcount>=1 then
		online_stat = l_cur_game_time() + pvp_protect_time_1
	end
	
	c_req.flag1 = me.basic.flag
	c_req.flag2 = math.max(ta_basic.flag+c_req.flag_chg_def,0)
	
	-- flag的修改还是即时merge入basic块，不用记账式思路了
	local ta_data = { db.command_and_wait(db.hash(ta_usersn),'HMGET %s pvpreport1 llog basic',tostring(ta_usersn)) }
	if 3~=table.getn(ta_data) then
		yylog.log('get target pvpreport1 error')
		return 1
	end
	
	local ta_pvpreport1 = box.unSerialize(ta_data[1])
	local ta_llog = box.unSerialize(ta_data[2])
	local ta_basic_2 = box.unSerialize(ta_data[3])
	
	ta_basic_2.flag = math.max(ta_basic_2.flag + c_req.flag_chg_def,0)
	ta_basic_2.shield_end_time = online_stat
	
	ta_basic_2.ver = ta_basic_2.ver or {}
	ta_basic_2.ver.pvpreport1 = ta_basic_2.ver.pvpreport1 or { a=1,b=1 }
	ta_basic_2.ver.pvpreport1.b = ta_basic_2.ver.pvpreport1.b + 1
	
	util.makesureListExists(ta_pvpreport1)
	table.insert(ta_pvpreport1.list,{name=me.basic.name,usersn=me.basic.usersn,bson=c_req,id=battle_id,sh_time=online_stat,flag_add=c_req.flag_chg_def})
	while table.getn(ta_pvpreport1.list)>pvpreport_list_max do
		if ta_pvpreport1.list[1].pending then
			break
		end
		
		table.remove(ta_pvpreport1.list,1)
	end
	
	local batch_list = {}
	table.insert(batch_list,{ meat=-battle_result.get_meat })
	table.insert(batch_list,{ elixir=-battle_result.get_elixir })
	
	for i=1,#he.map.list do
		local aa = map_res_modify[i]
		if aa then
			local m = he.map.list[i]
			
			local tt = { a=i,aid=m.aid }
			tt[aa[2]] = -aa[1]
			table.insert(batch_list,tt)
		end
	end
	
	table.insert(ta_llog.rg,{ t=l_cur_game_time(),from='PVP',l=batch_list })
	
	if nil~=trap_log and table.getn(trap_log)>0 then
		local trap_batch = { t=l_cur_game_time(),from='PVP',l=trap_log }
		table.insert(ta_llog.trap,trap_batch)
	end
	
	
	-- 修改了被攻击者的数据马上写回，因为ta不在线
	local ss1 = box.serialize(ta_basic_2)
	local ss2 = box.serialize(ta_pvpreport1)
	local ss3 = box.serialize(ta_llog)
	local r = db.command_and_wait(db.hash(ta_usersn),'HMSET %s basic %b pvpreport1 %b llog %b',tostring(ta_usersn),
	ss1,ffi.cast('size_t',#ss1),
	ss2,ffi.cast('size_t',#ss2),
	ss3,ffi.cast('size_t',#ss3))
	
	ownership.lock(ta_usersn,online_stat)
	
	ranklist.add(ta_usersn,c_req.flag2,ta_flag_bak)
	
	
	c_req.use_meat = 0
	
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'pvp')
		elseif to_add<0 then
			if util.check(me,key,-to_add) then
				util.dec(me,key,-to_add,'pvp')
			else
				util.dec(me,key,me.basic[key],'pvp')
			end
		end
	end
	
	-- 改自己的数据
	local aa = c_req.get_meat - c_req.use_meat
	if aa>0 then
		add_waste('meat',aa)
	elseif aa<0 then
		add_waste('meat',aa)
	end
	
	aa = c_req.get_elixir - c_req.use_elixir
	if aa>0 then
		add_waste('elixir',aa)
	elseif aa<0 then
		add_waste('elixir',aa)
	end
	
	
	
	-- 记录战报
	util.makesureListExists(me.pvpreport2)
	
	table.insert(me.pvpreport2.list,{name=ta_basic.name,usersn=ta_usersn,bson=c_req,id=battle_id})
	while #me.pvpreport2.list>pvpreport_list_max do
		table.remove(me.pvpreport2.list,1)
	end
	
	--加经验
	util.add_exp_level(me,sd.battle.default.info[my_to_level].exp)
	
	--出战结束时，买的鼓舞作废
	util.travalHero(me,function(hh)
		if nil~=hh.encounrage and nil~=hh.inuse then
			hh.encounrage = nil
			return true
		end
	end)
	
	ach.key_inc4(me,'pvp_elixir',c_req.get_elixir)
	ach.key_inc4(me,'pvp_meat',c_req.get_meat)
	
	ach.key_inc_daily(me,'PVP',1)
	
	local cur_hero = nil
	util.travalHero(me,function(h)
		if nil~=h.inuse then
			cur_hero = h
			
			if c_req.starcount >=1 then
				ach.key_inc4(me,'pvp_hero_win_'..h.type)
			else
				ach.key_inc4(me,'pvp_hero_lose_'..h.type)
			end
			return true
		end
	end)
	
	util.fillCacheData(me)
	
	me.cache.pvp_usersn = nil
	me.cache.pvp_copy = nil
	me.cache.pvp_start_time = nil
	me.cache.pvp_way = nil
	
	
	box.do_save_player(me)
	
	local defend_boss_type = ''
	util.travalPlayerMob(he,function(m,map)
		if 'to'==map.type then
			defend_boss_type = m.type
			return true
		end
	end)
	
	local h_type = (cur_hero and cur_hero.type) or ''
	local h_equip_str = ''
	if cur_hero and cur_hero.equip then
		for i=1,#cur_hero.equip.list do
			local a = cur_hero.equip.list[i]
			h_equip_str = h_equip_str .. ';' .. string.format('%s;%d',a.type,a.level)
		end
	end
	local h_pet_str = ''
	if cur_hero and cur_hero.pet then
		for i=1,#cur_hero.pet.list do
			local a = cur_hero.pet.list[i]
			h_pet_str = h_pet_str .. ';' .. string.format('%s;%d',a.type,a.level)
		end
	end
	
	local ss = string.format('pvp,usersn%d,targetsn%d,starcount%d,defend_boss_%s,meat%d,elixir%d,hero=%s,h_equip%s,h_pet%s,per%s,h_HP%d,use_time%d,max_meat%d,max_elixir%d,tolv%d,ta_flag%d,ta_name%s',
	me.basic.usersn,ta_usersn,c_req.starcount,defend_boss_type,c_req.get_meat,c_req.get_elixir,h_type,h_equip_str,h_pet_str,c_req._percentage,(c_req.hero_blood or 0),(c_req.use_time or 0),max_meat,max_elixir,ta_to_level,ta_basic.flag,ta_basic.name)
	yylog.log(ss)
	
	return 0
end

local function do_battle_end_league(me,c_req)
	
	if nil==me.cache.pvp_usersn or nil==me.cache.pvp_copy or nil==me.cache.pvp_start_time then
		yylog.log(string.format('me.cache.pvp_usersn nil  usersn%d',me.basic.usersn))
		return 1
	end
	
	local ta_usersn = tostring(me.cache.pvp_usersn)
	local he = me.cache.pvp_copy
	
	
	-- 计算
	calc_res(he)
	local er,battle_result,map_res_modify = pcall(calc_result,me,he)
	if false==er then
	end
	
	me.inbattle = nil	-- 清理
	
	
	-- 比较客户端提交的和自己计算的，如果有出入，记日志。最后用自己计算的值覆盖客户端的
	battle_result.get_meat = battle_result.get_meat + battle_result.get_meat_w
	battle_result.get_elixir = battle_result.get_elixir + battle_result.get_elixir_w
	--计算夺得的肉和金丹
	ach.key_inc3(me,'robMeat',battle_result.get_meat)
	ach.key_inc3(me,'robElixir',battle_result.get_elixir)
	
	local my_to_level = 1
	local ta_to_level = 1
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			my_to_level = m.level
			return true
		end
	end)
	util.travalPlayerMap(me.cache.pvp_copy,function(m)
		if 'to'==m.type then
			ta_to_level = m.level
			return true
		end
	end)
	local dur_time = sd.battle.default.info[ta_to_level].dur_time
	local elixir_count = sd.battle.default.info[my_to_level].elixir_count
	
	
	local function check(key,d)
		if math.abs(c_req[key] - battle_result[key])>1 then
			yylog.log(string.format('check detail dismatch usersn%d  key[%s] distance[%d]',me.basic.usersn,key,c_req[key] - battle_result[key]))
			c_req[key] = battle_result[key]
			return false
		end
		
		c_req[key] = battle_result[key]
		return true
	end
	
	if c_req then
		check('flag_chg_atk',1)
		check('flag_chg_def',1)
		check('starcount',0)
		check('win',0)
		check('get_meat',10)
		check('get_elixir',10)
		
		local to_use_elixir = math.floor(c_req.use_time * elixir_count / dur_time)
		--c_req.use_elixir = math.max(c_req.use_elixir,to_use_elixir)
		c_req.use_elixir = math.max(c_req.use_elixir,0)
		c_req.end_time = lcf.cur_game_time()
		
	else
		c_req = table.deepclone(battle_result)
		c_req.end_time = lcf.cur_game_time()
		c_req.stat = 1
		
		util.travalHero(me,function(h)
			if h.inuse then
				c_req.hero_type = h.type
				c_req.hero_lvl = h.level
				return true
			end
		end)
		
		--c_req.use_elixir = math.floor(c_req.use_time * elixir_count / dur_time)
		c_req.use_elixir = 0
		
	end
	
	c_req.use_meat = 0
	
	local function add_waste(key,amount)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,'league')
		elseif to_add<0 then
			if util.check(me,key,-to_add) then
				util.dec(me,key,-to_add,'league')
			else
				util.dec(me,key,me.basic[key],'league')
			end
		end
	end
	
	-- 改自己的数据
	local aa = c_req.get_meat - c_req.use_meat
	if aa>0 then
		add_waste('meat',aa)
	elseif aa<0 then
		add_waste('meat',aa)
	end
	
	aa = c_req.get_elixir - c_req.use_elixir
	if aa>0 then
		add_waste('elixir',aa)
	elseif aa<0 then
		add_waste('elixir',aa)
	end
	
	
	league.on_fight_over(me,ta_usersn,c_req.starcount)
	
	--加经验
	util.add_exp_level(me,sd.battle.default.info[my_to_level].exp)
	
	--出战结束时，买的鼓舞作废
	util.travalHero(me,function(hh)
		if nil~=hh.encounrage and nil~=hh.inuse then
			hh.encounrage=nil
			return true
		end
	end)
	
	ach.key_inc_daily(me,'PVL',1)
	
	util.travalHero(me,function(h)
		if nil~=h.inuse then
			if c_req.starcount >=1 then
				ach.key_inc4(me,'pvp_hero_win_'..h.type)
			else
				ach.key_inc4(me,'pvp_hero_lose_'..h.type)
			end
			return true
		end
	end)
	
	util.fillCacheData(me)
	
	me.cache.pvp_usersn = nil
	me.cache.pvp_copy = nil
	me.cache.pvp_start_time = nil
	me.cache.pvp_way = nil
	
	
	local defend_boss_type = ''
	util.travalPlayerMob(he,function(m,map)
		if 'to'==map.type then
			defend_boss_type = m.type
			return true
		end
	end)
	
	
	yylog.log(string.format('pvp-league,usersn%d,targetsn%d,starcount%d,defend_boss_%s',me.basic.usersn,ta_usersn,c_req.starcount,defend_boss_type))
	
	return 0
end

-- 注意这是个全局函数，因为在其他地方要调用（如，下线时）
function check_and_do_battle_end(me,c_req)
	if nil~=me.cache.pvp_usersn or nil~=me.cache.pvp_copy or nil~=me.cache.pvp_start_time then
		if 3~=me.cache.pvp_way then
			local ok,ret = pcall(do_battle_end,me,c_req)
			if false==ok then
				alog.debug(ret)
				return 1
			else
				return ret
			end
		else
			local ok,ret = pcall(do_battle_end_league,me,c_req)
			if false==ok then
				alog.debug(ret)
				return 1
			else
				return ret
			end
		end
	end
end


-- CombatEnd 	23 	<<(WORD)way<<(string)json_string 	结束一次PVP战斗 way:0-正常完成 1-中途退出的 其他待定 json_string：描述战斗结果的json串
box.reg_handle(23,function(me)

	local function err_ack(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_write_back()
	end
	
	-- 对网络输入的读取一定要放在任何异步操作之前。因为上下文切换时，没有保存网络输入。异步操作后就丢失了
	local way = lcf.cur_stream_get_int16()
	local bin = l_cur_stream_get_slice()
	
	local client_req = box.unSerialize(bin)
	
	local ret1 = check_and_do_battle_end(me,client_req)
	
	if 0==ret1 then
		local ss1 = box.serialize(me.basic)
		daily.push_data_to_c('basic',ss1)
		
	end
	
	
	err_ack(ret1)
	
	return 0
end)

