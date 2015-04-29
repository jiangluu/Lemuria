
function onEvent(me)
	local heroType,equipIndex=getUEParams()
	if   nil==equipIndex or nil==heroType then
		error('invalid input param')	
	end
			
	local ishave=false
	local lpNum=0
	util.travalPlayerMob(me,function(mob,map)
		if 'tm'==mob.type then		
			lpNum=lpNum+1
			if nil==mob.next_enable_time then
				ishave=true				
			elseif mob.next_enable_time<l_cur_game_time() then			
				ishave=true
			end
			return true
		end
	end)	
	
	
		if lpNum==0 then 
		return 1
	end
	
	
	if false==ishave then 
		return 1
	end
		
	local equipType;
	local level;
	util.travalHero(me,function(hero)
		if heroType==hero.type then		
			level=hero.equip.list[equipIndex].level
			equipType=hero.equip.list[equipIndex]['type']
			--level=hero.equip.list[equipIndex].level
			return true
		end
	end)
	
if nil==equipType or nil==level then
	return 1
	end	
		
	--升级武器花费类型
local spendtype=sd.equip[equipType]['info'][level+1]['cost_type']	
	--升级武器花费数量
local num=sd.equip[equipType]['info'][level+1]['cost']
	--升级武器花费时间
local times=sd.equip[equipType]['info'][level+1]['time']


 local foo=function(res_key)
	local falg=false
	if 'meat'==res_key then
		if me.cache.meat>=num then
			falg=true
		end
	elseif 'elixir'==res_key then
		if me.cache.elixir>=num then
			falg=true
		end	
	elseif 'diamond'==res_key then
		if me.basic.diamond>=num then
			falg=true
		end	
	end	
	
	if false==falg then
		return 1
	end
	
	util.dec(me,res_key,num,'upg_equip')
	return 0
end


	local suc=1;
	
	if 0==spendtype then
	suc=foo('meat')
	elseif 1==spendtype then
	suc=foo('elixir')
	elseif 2==spendtype then
	suc=foo('diamond')
	else
		return 1
	end
		
	
	if 0~=suc then
		return 1
	end
	-----加经验
	util.add_exp_level(me,sd.equip[equipType]['info'][level+1]['exp'])
	--升级装备次数
	if isServ() then
		ach.key_inc3(me,'equip')
	end
	
	local count1 = 0
	util.travalPlayerMob(me,function(mob,map)	
		if 'tm'==mob.type then		
			count1 = count1+1
			util.worker_into_cd(mob,times)			
			return true
		end
	end)
	
	if 0==count1 then 
		return 1
	end

	
	util.travalHero(me,function(hero)
		if heroType==hero.type then		
			hero.equip.list[equipIndex].level=hero.equip.list[equipIndex].level+1
			return true
		end
	end)
	
	util.fillCacheData(me)
	
	if isServ() then
		local ss = string.format('verbose_upgrade_equip,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,equipType,level+1,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0	
end