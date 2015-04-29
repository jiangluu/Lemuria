
-- һЩɽկ����Ϸ�ĳ��ú���

local o = {}


if isServ() then
	local lcf = ffi.C
	l_cur_game_time = function()
		return lcf.cur_game_time()
	end
	
	function o.string_hash(s)
		return lcf.string_hash(s)
	end
else
	-- �ͻ���C#���ʵ�� l_cur_game_time()
	
	o.string_hash = l_string_hash
end


util = o


--�Ӿ���
function o.add_exp_level(p,amount)
	local experience1 = (p.basic.exp or 0) + amount
	local level = (25+((625-100*(-experience1)))^0.5)/50
	p.basic.exp = experience1
	p.basic.level = level
	--p.cache.re_exp = experience1-level * (level - 1) * 25
end

-- ��Դ�Ӽ� ==============================

-- ����Ƿ񹻿���Щ��Դ
function o.check(p,key,amount)
	if nil==tonumber(amount) then
		return false
	end
	return (p.basic[key] >= amount)
end

function o.checkMeat(p,amount)
	return (p.basic.meat>=amount)
end

function o.checkElixir(p,amount)
	return (p.basic.elixir>=amount)
end

function o.checkDiamond(p,amount)
	return (p.basic.diamond>=amount)
end


-- ����Դ
function o.dec(p,key,amount,tag)
	if o.check(p,key,amount)~=true then
		return false
	end
	p.basic[key] = p.basic[key] - amount
	if 'diamond'~=key then
		p.cache[key] = p.basic[key]
	end
	
	if isServ() then
		if 'diamond'~=key then
			ach.key_inc4(p,key..'_dec',amount)
			if nil~=tag then
				ach.key_inc4(p,string.format('%s_dec_%s',key,tag),amount)
			end
		else
			ach.key_inc3(p,key..'_dec',amount)
			if nil~=tag then
				ach.key_inc3(p,string.format('%s_dec_%s',key,tag),amount)
			end
		end
	end
	
	return true
end

function o.decMeat(p,amount)
	return o.dec(p,'meat',amount)
end

function o.decElixir(p,amount)
	return o.dec(p,'elixir',amount)
end

function o.decDiamond(p,amount)
	return o.dec(p,'diamond',amount)
end

-- ����Ƿ��ܴ洢����Щ��Դ
function o.checkA(p,key,amount)
	if nil==tonumber(amount) then
		return false
	end
	return (p.basic[key]+amount <= p.basic[key..'_limit'])
end

function o.checkMeatA(p,amount)
	return (p.basic.meat+amount <= p.basic.meat_limit)
end

function o.checkElixirA(p,amount)
	return (p.basic.elixir+amount <= p.basic.elixir_limit)
end

-- ����Դ
function o.add(p,key,amount,tag)
	if 'diamond'~=key and o.checkA(p,key,amount)~=true then
		return false
	end
	p.basic[key] = p.basic[key]+amount
	if 'diamond'~=key then
		p.cache[key] = p.basic[key]
	end
	
	if isServ() then
		if 'diamond'~=key then
			ach.key_inc4(p,key..'_add',amount)
			if nil~=tag then
				ach.key_inc4(p,string.format('%s_add_%s',key,tag),amount)
			end
		else
			ach.key_inc3(p,key..'_add',amount)
			if nil~=tag then
				ach.key_inc3(p,string.format('%s_add_%s',key,tag),amount)
			end
		end
	end
	
	return true
end

function o.addMeat(p,amount)
	return o.add(p,'meat',amount)
end

function o.addElixir(p,amount)
	return o.add(p,'elixir',amount)
end

-- ������Դ����
function o.calcResLimit(p,res_key)
	local ret = 0
	
	-- �ȿ�����������������ģ���Դ�ڽ�������������ڹ���
	local map_i = o.f_find_v_in_array(p.map.list,'type','to')
	if map_i<0 then
		-- û����������Ч����
		return -1
	end
	
	local to_level = p.map.list[map_i].level
	ret = sd.scene.to.container[to_level][res_key]
	
	-- �ټ���ֵ�
	o.travalPlayerMob(p,function(mob,map)
		local conf = sd.creature[mob.type]
		if conf~=nil then
			if conf.store and conf.store[mob.level] then
				ret = ret + conf.store[mob.level][res_key]
			end
		end
	end)
	
	return ret
end

function o.has_housekeeper(p,now)
	if nil==p then
		return false
	end
	
	if nil==now then
		now = l_cur_game_time()
	end
	
	return (nil~=p.basic.steward_end_time and now<=p.basic.steward_end_time)
end


function o.heroHPRegen(p,now)
	-- Ӣ�������ָ�
	now = now or l_cur_game_time()
	
	local to_level = 1
	o.travalPlayerMap(p,function(m)
		if 'to'==m.type then
			to_level = m.level
			return true
		end
	end)
	
	local cc = sd.battle.default.info[to_level]
	local hero_stamina_gen_timeval = cc.heal_time_nature or 30		-- 10���1%
	
	o.travalHero(p,function(h)
		if h.stamina >= 100 then
			h.stamina = 100
			h.heal = nil
			return
		end
		
		if h.heal then
			if o.has_housekeeper(p,now) then
				hero_stamina_gen_timeval = cc.heal_time_vip1
			else
				hero_stamina_gen_timeval = cc.heal_time
			end
		end
		
		if nil==h.last_battle_time then
			h.last_battle_time = now
		end
		
		local aa = math.floor((now-h.last_battle_time) / hero_stamina_gen_timeval)
		if aa>=1 then
			h.stamina = math.min(h.stamina+aa,100)
			h.last_battle_time = h.last_battle_time + hero_stamina_gen_timeval*aa
		end
	end)
end

-- ����ͽ���ƽ
function o.resPeipin(p)
	
	local foo = function(key)
		local res_has = p.basic[key] or 0
		local sum = 0
		local aa = {}
		
		local boo = function(m,map_type,kk)
			if map_type==m.type and kk==key then
				local con = sd.scene[m.type]['detail'][m.level]['carrage']
				
				if con>0 then
					table.insert(aa,{m,con})
					sum = sum+con
				end
			end
		end
		
		o.travalPlayerMap(p,function(m)
			if 'to'==m.type then
				local con = sd.scene.to.container[m.level][key..'_limit']
				if con then
					table.insert(aa,{m,con})
					sum = sum+con
				end
			else
				boo(m,'kc','meat')
				boo(m,'vt','elixir')
			end
		end)
		
		-- ˳��������һ������
		p.basic[key..'_limit'] = sum
		-- ʵ�ʰ��հٷֱȷ���
		if sum>0 then
			for i=1,#aa do
				local map = aa[i][1]
				map[key] = math.floor(res_has * aa[i][2] / sum)
			end
		end
	end	-- END foo
	
		
	foo('meat')
	foo('elixir')
end

-- ========================================

function o.addMap(p,map_type,x,y,direction)
	local conf = sd.scene[map_type]
	if nil==conf then
		return
	end
	
	local aid = nil
	if p.map.max_aid then
		aid = p.map.max_aid + 1
		p.map.max_aid = aid
	end
	
	table_insert(p.map.list,{type=map_type,x=x,y=y,direction=direction,level=1,aid=aid})
	return true
end


function o.addToLobby(p,mm)
	o.makesureListExists(p.lobby)
	local mob = {type=mm.type,level=mm.level,num=mm.num or 1,num_used=mm.num_used or 0}
	
	local index = -1
	for i=1,#p.lobby.list do
		local aa = p.lobby.list[i]
		if mob.type==aa.type and mob.level==aa.level then
			index = i
			break
		end
	end
	
	if index<0 then
		table_insert(p.lobby.list,mob)
	else
		local aa = p.lobby.list[index]
		aa.num = aa.num + mob.num
	end
end


function o.fillCacheData(p)
	--p.basic.meat_limit = o.calcResLimit(p,'meat_limit')
	--p.basic.elixir_limit = o.calcResLimit(p,'elixir_limit')
	
	o.resPeipin(p)
	
	--alog.debug(string.format('fillcache  SN[%d]  diamond[%d] ',tonumber(cf.cur_user_sn()),p.basic.diamond))
	
	p.cache = p.cache or {}
	p.cache.meat,p.cache.meat_limit = p.basic.meat,p.basic.meat_limit
	p.cache.elixir,p.cache.elixir_limit = p.basic.elixir,p.basic.elixir_limit
	p.cache.lm,p.cache.lm_total = o.calcAvMobCountWisely(p,'lm','next_enable_time')
	
	--p.cache.shop = o.generateShop(p)
end

--[[
-- ��������ܴ�����ͬʱ�������ڴ������������
function o.calcMeatStore(p)
	return o.calcResWisely(p,'meat_limit','meat_init')
end

-- ����𵤵��ܴ�����ͬʱ�������ڴ������������
function o.calcElixirStore(p)
	return o.calcResWisely(p,'elixir_limit','elixir_init')
end

function o.calcResWisely(p,var_key,var_key2)
	local has,max_has = 0,0
	
	-- �������֣���ʵֻ������
	o.travalPlayerMap(p,function(map)
		local conf = sd.scene[string.lower(map.type)]
		if conf and conf.container then
			local max2 = conf.container[map.level][var_key]
			if nil~=max2 then
				max_has = max_has+max2
				
				if nil~=map[var_key2] then
					has = has+map[var_key2]
				end
			end
		end
	end)
	
	-- �ֲ��֣���Դ��Ҫ���ڹ�����
	
	return has,max_has
end
--]]

-- ����ĳ�����ùֵĸ���
function o.calcAvMobCountWisely(p,var_key,var_key2)	-- AV means available
	local count,count2 = 0,0
	
	o.travalPlayerMob(p,function(mob,map)
		if var_key==mob.type then
			count2 = count2+1
			
			if nil==mob[var_key2] then
				count = count+1
			elseif mob[var_key2] and mob[var_key2] <= l_cur_game_time() then
				count = count+1
			end
		end
	end)
	
	return count,count2
end


----------------�ɾ�ϵͳ
function o.getCount(p,key)
	local times = 0
	if key == 'player' then 
		times = p.basic.level or 0
	elseif key=='flag' then
		times= p.basic.flag or 0
	else
		times = p.var.stat[key] or 0
	end
	
	return times
end

function o.getCountDaily(p,key)
	local times = 0
	if 'finiQuest'==key then
		if p.addition.daily.list then
			for i=1,#p.addition.daily.list do
				local entry = p.addition.daily.list[i]
				if not (entry.mc or 50==tonumber(entry.id)) then
					local aa = tonumber(entry.stat)
					if aa and aa>=1 then
						times = times+1
					end
				end
			end
		end
	else
		times = p.var.stat_daily[key] or 0
	end
	
	return times
end

function o.getLevel(p,key)
	local level = 0
	o.travalPlayerMap(p,function(m)
		if key == m.type then
			level = math.max(m.level,level)
		end
	end)
	
	return level
end

function o.getKillCountDaily(p,key)
	local ret = 0
	
	local skey = string.format('kill_%s',key)
	ret = p.var.stat_daily[skey] or 0
	
	return ret
end


function o.f_find_v_in_array(arr,col_name,v)
	for i=1,#arr do
		if v==arr[i][col_name] then
			return i
		end
	end
	return -1
end

-- ��ʼ������ҵ�����
function o.initNewPlayer(p)
	local basic_d = sd.default.basic
	local map_d = sd.default.map
	
	if nil==basic_d or nil==map_d then
		error('No default data!')
	end
	
	local now = tonumber(l_cur_game_time())
	
	p.basic = deepCloneTable(basic_d.default)
	
	p.basic.daily_expire = 21
	p.basic.shield_end_time = now + p.basic.shield		-- ��û�����ֻ��ܱ��������ڲ���
	p.basic.shield = nil
	-- p.basic.steward_end_time = now + p.basic.vip
	p.basic.vip = nil
	
	p.map = deepCloneTable(map_d)
	o.make_map_aid(p)
	p.buff = deepCloneTable(sd.default.buff)
	
	
	-- ��ʼ����Դ����
	local to_conf = sd.scene.to
	p.basic.meat = to_conf.container[1].meat_init
	p.basic.meat_limit = to_conf.container[1].meat_limit
	p.basic.elixir = to_conf.container[1].elixir_init
	p.basic.elixir_limit = to_conf.container[1].elixir_limit
	
	
	-- ��mob�ŵ��ؿ���
	for _,mm in pairs(sd.default.mob.list) do
		local conf = sd.creature[mm.type]
		if nil==conf then
			break
		end
		
		local to_map = mm.scene
		local map_i = o.f_find_v_in_array(p.map.list,'type',to_map)
		if map_i>=0 then
			local map_data = p.map.list[map_i]
			
			if nil==map_data.mob then
				map_data.mob = {}
				map_data.mob.list = {}
			end
			
			local aa = map_data.mob.list
			
			table_insert(aa,{type=mm.type,level=mm.level,num=1})
			--print('add a mob',to_map,map_i,mm.type,mm.level)
		end
		
	end
	
	-- �ͳ�ʼӢ��
	p.hero = {}
	p.hero.list = {}
	--table_insert(p.hero.list,{type='ht',level=1,inuse=true,stamina=sd.battle.default.info[1].max})
	
	box.makesure_all_block_exist(p)
	
	p.basic.cver = 2	-- �ºű��
	
	o.resPeipin(p)
	
	--alog.debug(string.format('initplayer  SN[%d]  diamond[%d] ',tonumber(cf.cur_user_sn()),p.basic.diamond))
	
	
	return p
end



function o.travalPlayerMap(p,fun)
	for i=1,#p.map.list do
		local map = p.map.list[i]
		if fun(map)==true then
			return
		end
	end
end

function o.travalPlayerLobby(p,fun)
	for i = 1,#p.lobby.list do
		local lobby = p.lobby.list[i]
		if fun(lobby) == true then
			return
		end
	end
end

function o.travalPlayerMob(p,fun)
	for i=1,#p.map.list do
		local map = p.map.list[i]
		if map.mob then
			for j=1,#map.mob.list do
				if fun(map.mob.list[j],map)==true then
					return
				end
			end
		end
	end
end

function o.travalHero(p,fun)
	for i=1,#p.hero.list do
		local hero = p.hero.list[i]
		if fun(hero)==true then
			return
		end
	end
end

function o.getCounter()
	local counter = 0
	
	return function()
		counter = counter+1
		return counter
	end
end

-- �����ݱ仯ʱ������Ӣ��ӵ�е�װ���������
function o.updateHeroEquip(p)
	local bs_lv = 0
	o.travalPlayerMap(p,function(m)
		if 'bs'==m.type then
			bs_lv = m.level
			return true
		end
	end)
	
	if bs_lv<=0 then
		return
	end
	
	
	--for k,v in pairs(sd.equip.index.enum) do
	o.travalHero(p,function(h)
		table.travel_sd(sd.equip,function(t,k)
				local v = t[k]
				if v.info and h.type==v.hero and (nil==v.info[1].bs_level or v.info[1].bs_level<=bs_lv) then
				-- ȷ����hero��װ��k
					if nil==h.equip then
						h.equip = {}
						h.equip.list = newArray()
					end
					
					local found = false
					for jj=1,#h.equip.list do
						if k == h.equip.list[jj].type then
							found = true
							break
						end
					end
					
					if not found then
						table_insert(h.equip.list,{type=k,level=1})
					end
				end
		end)
	end)
	
end

function o.traval_shop(sub_key,f)
	local big_data = sd.shop[sub_key]
	
	for k,v in pairs(big_data) do
		pcall(f,big_data,k)
	end
end

function o.generateShop(p)
	local my_shop = {}
	local counter = o.getCounter()
	
	--local hash_str = p.basic.login_key or p.basic.name
	--hash_str = hash_str..'nmb'
	local hash_str = 'yaomeizhi'
	local getunique = function(t)
		return o.string_hash(t.type .. hash_str .. tostring(t.sort))
	end
	
	local to_level = 1		-- �����ȼ�
	o.travalPlayerMap(p,function(m) if 'to'==m.type then to_level=m.level end end)
	
	local now = l_cur_game_time()
	
	
	-- ��������
	o.traval_shop('map',function(t,k)
		local v = t[k]
		local conf = sd.scene[k]
		local name = conf.name
		
		local to_limit = conf.limit[to_level]
		if nil==to_limit then
			alog.warning('TO level too high in generateShop. usersn'..tonumber(cf.cur_user_sn()))
			return
		end
		
		local has_num = 0
		o.travalPlayerMap(p,function(m)
			if m.type == k then
				has_num = has_num+1
			end
		end)
		local level=1	-- ����ʱ�϶���1��
		
		local vv = v[level]
		
		table_insert(my_shop,{catagory=1 ,type=k, cost_type=vv.cost_type, cost=vv.cost_count, time=vv.time ,name=name , level=level,
			has=has_num,limit=to_limit.limit_count,sort=vv.sort or counter()})
	end)
	
	
	-- �ֲ���
	--[[
		�̵�����������
1. creature.type = chief �Ĺֿ��Թ������ : creature.build����Ӧ�������ĵȼ� >= creature.build_lvl �Ľ�������
	���磺�ݵ㳤���ΪѲ�߾ݵ�3��������Ŀǰ�ѽ��쳡����2��3��Ѳ�߾ݵ㣬1��2��Ѳ�߾ݵ㣬��ݵ㳤��⬿ɽ������=2
2. creature.type = monster �Ĺֿ��Թ������ : creature.build����Ӧ�������ĵȼ� >= creature.build_lvl  �� (�������� * scene.detail.population) / creature.population (С����ȥ)
	*** creature.type =(w.meat �� w.elixir �� s.meat �� s.godden���μ���һ�� ***
	--]]
	
	o.traval_shop('monster',function(t,k)	
		local v = t[k]
		local mob_conf = sd.creature[k]
		
		local has_num = 0
		local limit_total_pop = 0
		local limit_total_num = 0
		
		-- ���� limit_total_pop
		if nil~=mob_conf.build then
			o.travalPlayerMap(p,function(m)
				if mob_conf.build==m.type and m.level>=(mob_conf.build_lvl or 1) then
					local map_conf = sd.scene[m.type]
					if map_conf then
						if 'chief'==mob_conf.type then
							limit_total_num = limit_total_num + 1
						else
							if nil~=map_conf.detail[m.level] then
								limit_total_pop = limit_total_pop + (tonumber(map_conf.detail[m.level].population) or 0)
							end
						end
					end
				end
			end)
			
			-- ���� has_num
			if 'chief'==mob_conf.type or 'monster'==mob_conf.type then
				if p.lobby.list then
					for i=1,#p.lobby.list do
						local aa = p.lobby.list[i]
						if k==aa.type then
							has_num = has_num+aa.num
						end
					end
				end
			else
				o.travalPlayerMob(p,function(m,map)
					if k==m.type then
						has_num = has_num+(m.num or 1)
					end
				end)
			end
			
		end
		
		if 'chief'~=mob_conf.type then
			limit_total_num = math.floor(limit_total_pop / mob_conf.population)
		end
		
		local level = p.var.research[k] or 1	-- �����о���
		
		local aa = nil
		-- ��������ӵ�и������۸����ǵ�
		for ii=1,table.getn(v) do
			if has_num == v[ii].condition then
				aa = v[ii]
			end
			
			if has_num+1 == v[ii].condition then
				aa = v[ii]
				break
			end
		end
		-- ��ȼ���
		if nil==aa then
			aa = v[level] or v[level-1]
		end
		
		local name = mob_conf.name
		
		if nil~=aa then
			table_insert(my_shop,{catagory=2 ,type=k, cost_type=aa.cost_type, cost=aa.cost_count, time=aa.time ,name=name , level=level,
				has=has_num,limit=limit_total_num,sort=aa.sort or counter(),sp=aa.show_point})
		end
	end)
	
	-- hero����
	o.traval_shop('hero',function(t,k)
		local v = t[k]
		local level = 1
		local aa = v[level]
		local mob_conf = sd.creature[k]
		local has_num = 0
		o.travalHero(p,function(h)
			if k==h.type then
				has_num = 1
			end
		end)
		
		table_insert(my_shop,{catagory=3 ,type=k, cost_type=aa.cost_type, cost=aa.cost_count, time=aa.time ,name=mob_conf.name , level=to_level,
			has=has_num,limit=1,sort=aa.sort or counter()})
	end)
	
	-- boss����
	o.traval_shop('boss',function(t,k)
		local v = t[k]
		local mob_conf = sd.creature[k]
		local level = 1
		local aa = v
		local has_num = 0
		
		if p.lobby.list then
			for i=1,#p.lobby.list do
				if k==p.lobby.list[i].type then
					has_num = 1
				end
			end
		end
		
		local limit = 1
		if mob_conf.build_lvl and mob_conf.build_lvl>to_level then
			limit = 0
		end
		
		table_insert(my_shop,{catagory=4 ,type=k, cost_type=aa.cost_type, cost=aa.cost_count, time=aa.time ,name=mob_conf.name , level=level,
			has=has_num,limit=limit,sort=aa.sort or counter()})
	end)
	
	-- �Ʊ�����
	o.traval_shop('precious',function(t,k)
		local v = t[k]
		local aa = v
		local cost_fixed = aa.cost_count
		local willget = aa.get_count
		local has_num = 0
		
		local get_has_num = function(key,key2)
				local youhui = 1	-- �Ż�
				--[[
				��ʯ���� = K*��Ҹ���^Z
��ʯ���� = ��Ҹ���/��ʯ����
->��ʯ���� = ��Ҹ���/��K*��Ҹ���^Z��
->�Żݹ��� -> ��ʯ���� =(��Ҹ���/(K*��Ҹ���^Z))*A
��������������

������
K = 23.82
Z = 0.31
A = 1
--]]
				
				local tofill = p.basic[key2] - p.basic[key]
				if 0==aa.get_count then		-- ���ǡ��������ģ�ֻҪ���������ľͿ�����
					if tofill>0 then
						has_num = 1
						willget = tofill
						cost_fixed = o.getDiamondExchange(willget)
					end
				else	-- ��������Ҫ������get_count������
					local bb = tofill / (p.basic[key2]*aa.get_count)
					has_num = math.floor(bb)
					if has_num>=1 then
						willget = p.basic[key2]*aa.get_count
						cost_fixed = o.getDiamondExchange(willget)
					end
				end
		end
		
		-- ��ʼ���㡰����10%���⡱���ֱ仯��
		--[[
		if nil==aa.cost_count then
			if 0==aa.get_type then
				get_has_num('meat','meat_limit')
			else
				get_has_num('elixir','elixir_limit')
			end
		else
			has_num = 99
		end
		--]]
		
		table_insert(my_shop,{catagory=5 ,type=k, cost_type=aa.cost_type,get_type=aa.get_type,cost=cost_fixed,
			has=has_num,willget=willget,name=aa.desc,sort=aa.sort or counter()})
		--print('precious',cost_fixed,willget,has_num)
	end)
	
	-- ����֮��
	o.traval_shop('contract',function(t,k)
		local v = t[k]
		local aa = v
		
		local has = 0
		if nil~=p.var.cd[k] and now<p.var.cd[k] then
			has = 1
		end
		
		table_insert(my_shop,{catagory=6 ,type=k, cost_type=aa.cost_type,cost=aa.cost_count,
			has=has,sh_time=aa.sh_time,cd_time=aa.cd_time,name=aa.name,desc=aa.desc,sort=aa.sort or counter()})
	end)
	
	o.traval_shop('trap',function(t,k)
		local v = t[k]
		local trap_conf = sd.trap[k]
		local level = 1
		local aa = v[level]
		local has_num = 0
		
		o.travalPlayerMap(p,function(m)
			if m.trap then
				for i=1,#m.trap.list do
					local aa = m.trap.list[i]
					if k==aa.type then
						has_num = has_num + 1
					end
				end
			end
		end)
		
		local limit = trap_conf.limit[to_level].limit_count
		
		table_insert(my_shop,{catagory=7 ,type=k, cost_type=aa.cost_type, cost=aa.cost_count, time=aa.time , level=level,
		name = trap_conf.name,has=has_num,limit=limit,
		sort=aa.sort or counter()} )
	end)
	
	
	table.sort(my_shop,function(a,b)
		if a.catagory ~= b.catagory then
			return a.catagory<b.catagory
		else
			return a.sort<b.sort
		end
	end)
	
	
	for i=1,#my_shop do
		my_shop[i].hash = getunique(my_shop[i])
		-- debug
		--print(i,my_shop[i].type,my_shop[i].sort,my_shop[i].hash)
	end
	
	if isServ() then
		return my_shop
	else
		local ud = newArray()
		deepCloneTableToUserData(ud,my_shop)
		return ud
	end
end


function o.makesureListExists(t)
	if not t.list then
		t.list = newArray()
	end
end


function o.getDiamondExchange(res_amount,res_type)
	local youhui = 1	-- �Ż�
	local cost_fixed = math.floor(res_amount/(23.82*res_amount^0.31) * youhui) + 1
	return cost_fixed
end


o.t_time_exchange = {
	{0,1,246},
	{247,18,186.33},
	{3600,240,345},
	{86400,-1,700.5},
}
function o.getDiamondExchangeTime(amount)
	if amount<=0 then
		return 0
	end
	
	local aa = amount
	local ret = 0
	for i=2,#o.t_time_exchange do
		local lv = o.t_time_exchange[i]
		if aa>=lv[1] then
			ret = ret+o.t_time_exchange[i-1][2]
			aa = aa-lv[1]
		else
			ret = ret + math.floor(aa / o.t_time_exchange[i-1][3])+1
			aa = 0
			break
		end
	end
	
	if aa>0 then
		ret = ret + math.floor(aa / o.t_time_exchange[4][3])+1
	end
	
	return ret
end

function o.getDiamondExchangeTime_recall(amount)
	if amount<=0 then
		return 0
	end
	
	local aa = amount
	local ret = 0
	for i=2,#o.t_time_exchange do
		local lv = o.t_time_exchange[i]
		if aa>=lv[1] then
			ret = ret+o.t_time_exchange[i-1][2]
			aa = aa-lv[1]
		else
			ret = ret + aa / o.t_time_exchange[i-1][3]
			aa = 0
			break
		end
	end
	
	if aa>0 then
		ret = ret + aa / o.t_time_exchange[4][3]
	end
	
	return math.floor(ret*0.1)+1
	
end



function o.worker_into_cd(lm,cd_time)
	lm.next_enable_time = l_cur_game_time() + cd_time
	lm.cd = cd_time
end

function o.is_newbie_name(b)	-- �Ƿ���������
	local def_name = sd.default.basic.default.name
	if def_name == b.name then
		return true
	end
	return false
end

function o.make_map_aid(p)
	if p.map then
		local max_aid = 0
		local absent = false
		o.travalPlayerMap(p,function(m)
			if nil==m.aid then
				absent = true
			else
				max_aid = math.max(max_aid,m.aid)
			end
		end)
		
		if false==absent then
			p.map.max_aid = max_aid
		else
			o.travalPlayerMap(p,function(m)
				if nil==m.aid then
					max_aid = max_aid+1
					m.aid = max_aid
				end
			end)
			
			p.map.max_aid = max_aid
		end
	end
end

function o.update_array(me,key)
	if nil == key or nil == me.var.jin[key] then
		return 1
	end
	
	if nil == me.var.jin[key].starttime then
		return 1
	end
	
		--ȡ����һ������ʱ���Լ����ܴ�������
	local ai = 0 --���ܹܼҿ�����������
	local onceTime = sd.jin[key]['charge_time']
	local limit = sd.jin[key]['count'] + ai
		
		--�Ƿ��Ѵ����޴���
	if me.var.jin[key].count >= limit then
		me.var.jin[key].starttime = 0
		return 0
	end
	
		--����
	local leftTime = l_cur_game_time() - me.var.jin[key].starttime
	local count = 0
	
	if leftTime>0 then
		count = count + math.floor(leftTime/onceTime)
	end
	
	me.var.jin[key].count = me.var.jin[key].count + count
	
		--��������
	if me.var.jin[key].count >= limit then
		me.var.jin[key].count = limit
		me.var.jin[key].starttime = 0
	else
		me.var.jin[key].starttime = l_cur_game_time() - leftTime
	end

end

function o.use_update_array(me)
	local key1 = 'jin_atk'
	local key2 = 'jin_def'
	
	o.update_array(me,key1)
	o.update_array(me,key2)
end

-- �ṩ���ͻ����õĺ���

function clientUpdateRes()
	if not isServ() then
		local lp = player
		RG.RGCreasteLog(lp)
		RG.RGCommitLog(lp,true)
		
		o.heroHPRegen(lp)
		o.use_update_array(lp)
	end
end

function clientGenShop()
	if not isServ() then
		player.cache.shop = o.generateShop(player)
	end
end

function calcDiamondExchange(res_amount,res_type)
	return o.getDiamondExchange(res_amount,res_type)
end

function calcDiamondExchangeTime(amount)
	return o.getDiamondExchangeTime(amount)
end

function calcDiamondExchangeTime_recall(amount)
	return o.getDiamondExchangeTime_recall(amount)
end

function calcResRepairAllTrap()
	local me = player
	
	local res_key = 'meat'
	local res_sum = 0
	
	util.travalPlayerMap(me,function(v)
		if nil~=v.trap then 
			for j=1,#v.trap.list do
				local trap = v.trap.list[j]
				if nil~=trap.o then
					local conf = sd.trap[trap.type].info[trap.level]
					res_sum = res_sum + conf.rp_cost
				end
			end
		end
	end)
	
	return res_sum
end

function calcResRepairOneTrap(map_index,trap_index)
	local me = player
	
	local res_key = 'meat'
	
	if map_index<=#me.map.list and nil~=me.map.list[map_index] then
		local mm = me.map.list[map_index]
		if nil~=mm.trap and trap_index<=#mm.trap.list and nil~=mm.trap.list[trap_index] then
			local trap = mm.trap.list[trap_index]
			
			if nil~=trap.o then
				local conf = sd.trap[trap.type].info[trap.level]
				return conf.rp_cost
			end
		end
	end
	
	return -1
end

function o.calcEliExchangeHp(me,types)
	if  nil==types then
		return -1
	end
	local level=1
	for i=1,#me.map.list do
		if 'to'==me.map.list[i].type then
			level=me.map.list[i].level
			break
		end
	end
	
	local eli=sd.battle.default.info[level].heal_elixir
	local cur_hp=100
	for i=1,#me.hero.list do
		if types==me.hero.list[i].type then
			cur_hp=me.hero.list[i].stamina
			break
		end
	end
	
	if cur_hp == 100  then
		return -1
	end
	
	local totel_eli=(100-math.floor(cur_hp))*eli
	return totel_eli	
end

function calcEliExchangeHp(types)	-- ���ֻ�пͻ��˲��ܵ�
	return o.calcEliExchangeHp(player,types)
end

function o.client_search_hero(me)
	for i=1,#me.hero.list do
		if nil~=me.hero.list[i].inuse then
			return me.hero.list[i].type
		end
	end
end

function client_search_hero()
	return o.client_search_hero(player)
end

function clientUpdateLM()
	player.cache.lm,player.cache.lm_total = o.calcAvMobCountWisely(player,'lm','next_enable_time')
end

function o.clientSearchLMMaxTimes(p,var_key,var_key2)
	local times=0	
	local now = l_cur_game_time()
	local timeList={}
	
	o.travalPlayerMob(p,function(mob,map)		
		if var_key==mob.type then						
			if mob[var_key2] and mob[var_key2] > now and  mob[var_key2]>times then				
				--times=mob[var_key2]				
				table.insert(timeList,tonumber(mob[var_key2]))
			end
		end
	end)	
	
	if #timeList>0 then
		table.sort(timeList)
		times=timeList[1]
	end	
	
	if 0 ~= times then
		times=times-l_cur_game_time()		
	end	
	return times
end

function clientSearchLMMaxTimes()	
	return o.clientSearchLMMaxTimes(player,'lm','next_enable_time')
end

function o.calcHealEli(p,left)
	local now = l_cur_game_time()
	
	local to_level = 1
	o.travalPlayerMap(p,function(m)
		if 'to'==m.type then
			to_level = m.level
			return true
		end
	end)
	local cc = sd.battle.default.info[to_level]
	
	local cost = 0
	if o.has_housekeeper(p,now) then
		cost = cc.heal_elixir_vip1 * left
	else
		cost = cc.heal_elixir * left
	end
	
	return cost
end

function clientCalcHealEli(left)
	return o.calcHealEli(player,left)
end

function o.calcHealDiamond(p,left)
	local now = l_cur_game_time()
	
	local to_level = 1
	o.travalPlayerMap(p,function(m)
		if 'to'==m.type then
			to_level = m.level
			return true
		end
	end)
	local cc = sd.battle.default.info[to_level]
	
	local time_left = 0
	if o.has_housekeeper(p,now) then
		time_left = cc.heal_time_vip1 * left
	else
		time_left = cc.heal_time * left
	end
	
	if time_left<=0 then
		return 0
	end
	
	return o.getDiamondExchangeTime(time_left)
end

function clientCalcHealDiamond(left)
	return o.calcHealDiamond(player,left)
end
