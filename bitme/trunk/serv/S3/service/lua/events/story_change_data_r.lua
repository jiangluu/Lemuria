
function onEvent(me)
	local index,star,point_array,add_meat,add_elixir,name,use_time,hp,per = getUEParams()
	
	if nil==index or nil==tonumber(star) or nil==point_array then
		error('invalid param')
	end
	
	if tonumber(star)<0 or tonumber(star)>4 then
		error('invalid param')
	end
	
	local old = me.var.stat_daily.story_r[index]
	if nil==old then
		error('invalid param')
	end
	
	local old_star = old.star or 0
	old.star = math.max(star,old_star)
	old.points = point_array
	if star>=1 then
		old.stat = 1
	end
	
	
	local function add_waste(key,amount,logstype)
		local to_add = amount
		if 'diamond'~=key then
			local limit = me.basic[key..'_limit']
			to_add = math.min(to_add,limit-me.basic[key])
		end
		
		if to_add>0 then
			util.add(me,key,to_add,logstype)
		elseif to_add<0 then
			util.dec(me,key,-to_add,logstype)
		end
	end
	if star>old_star then
		add_waste('meat',(add_meat or 0),'story')
		add_waste('elixir',(add_elixir or 0),'story')
	end
	
	if star>=2 then
		if nil==me.addition.story_r then
			me.addition.story_r = {}
		end
		
		local old2 = me.addition.story_r[index]
		if nil==old2 then
			me.addition.story_r[index] = {}
			me.addition.story_r[index].stat = 1
		elseif nil==old2.stat then
			old2.stat = 1
		end
	end
	
	-- 找到当前用的英雄
	local hero_id = nil
	util.travalHero(me,function(h)
		if nil~=h.inuse then
			hero_id = h.type
			h.encounrage = nil
			return true
		end
	end)
	
	if isServ() then
		ach.key_inc4(me,'pve')
		ach.key_inc_daily(me,'PVE')
		
		--征服模式胜利次数
		if tonumber(star)>=2 then
			ach.key_inc3(me,'finiChan')
		end
		
		if nil~=hero_id then
			ach.key_inc4(me,string.format('pve_%s',hero_id))
			
			if tonumber(star)>=2 then
				ach.key_inc4(me,string.format('pve_win_%s',hero_id))
			else
				ach.key_inc4(me,string.format('pve_lose_%s',hero_id))
			end
		end
	end
	
	
	
	local cur_hero = nil
	util.travalHero(me,function(h)
		if nil~=h.inuse then
			cur_hero = h
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
	
	if isServ() and use_time and hp and per and name then
		local ss = string.format('verbose_pve,usersn%d,name_%s,hero=%s,h_equip%s,h_pet%s,use_time%d,add_meat%d,add_elixir%d,HP%d,star%d,percent%s',me.basic.usersn,name,h_type,h_equip_str,h_pet_str,use_time,add_meat,add_elixir,hp,star-1,per)
		yylog.log(ss)
	end
	
	-----------------------------------------------------	
	if 1~=me.addition.story_r[index].stat then
		return 1
	end
	local key=sd.dungeon[index].reward_action
	local conf = sd.reward[key]
	if conf then
		me.addition.story_r[index].stat = 2
		
		for i=1,table.getn(conf.detail) do
			local r_type = conf.detail[i].type
			local r_num = conf.detail[i].count
			if util.has_housekeeper(me) then
				r_num = conf.detail[i].count_vip1
			end
			
			if 0==r_type then
				add_waste('meat',r_num,'story_reward')
			elseif 1==r_type then
				add_waste('elixir',r_num,'story_reward')
			elseif 2==r_type then
				util.add(me,'diamond',r_num,'story_reward')
			elseif 3==r_type then
				util.travalHero(me,function(h)
					if nil~=h.inuse then
						h.stamina = math.min(h.stamina + r_num,100)
						return true
					end
				end)
			elseif 4==r_type then
				util.add_exp_level(me,r_num)
			end
		end
	else
		return 2
	end
	-----------------------------------------------------
	
	
	util.fillCacheData(me)
	return 0		
end
