
function onEvent(me)
	local trap_type = getUEParams()
	
	if nil == trap_type then
		error('invalid input param')
	end
	
	local conf = sd.trap[trap_type]
	if nil==conf then
		return 1
	end
	
	local now = l_cur_game_time()
	
	local tm_idle = nil
	util.travalPlayerMob(me,function(mob,map)
		if 'tm'==mob.type and (nil==mob.next_enable_time or mob.next_enable_time<=now) then		
			tm_idle = mob
			return true
		end
	end)
	
	if nil==tm_idle then
		return 1
	end
	
	local level = me.var.research[trap_type] or 1
	
	-- ¿ÛÇ®
	local foo = function(res_key,cost)
		if me.basic[res_key]<cost then
			alog.debug('not enough res to upgrade trap')
			return 1
		end
		
		util.dec(me,res_key,cost,'upg_trap')
		
		return 0
	end
	
	local cost = conf.info[level+1].re_cost
	local cost_type = conf.info[level+1].cost_type
	
	local suc = 1
	if 0==cost_type then
		suc = foo('meat',cost)
	elseif 1==cost_type then
		suc = foo('elixir',cost)
	elseif 2==cost_type then
		suc = foo('diamond',cost)
	else
		return 1
	end
	
	if 0~=suc then
		return 1
	end
	
	me.var.research[trap_type] = level+1
	
	util.travalPlayerMap(me,function(m)
		if nil~=m.trap then
			for i=1,#m.trap.list do
				if trap_type==m.trap.list[i].type then
					m.trap.list[i].level = level+1
				end
			end
		end
	end)
	
	util.worker_into_cd(tm_idle,conf.info[level].re_time)
	
	
		--Ë¢ÐÂÊý¾Ý
	util.fillCacheData(me)
	
	if isServ() then
		ach.key_inc_daily(me,'upgrade_trap',1)
		
		local ss = string.format('verbose_upgrade_trap,usersn%d,%s,%d,meat%d,elixir%d,diamond%d',me.basic.usersn,trap_type,level+1,me.basic.meat,me.basic.elixir,me.basic.diamond)
		yylog.log(ss)
	end
	
	return 0	
end