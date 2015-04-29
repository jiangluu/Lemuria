
function onEvent(me)
	local boss_index = getUEParams()	-- UE Param means User Event Param
	
	if nil==boss_index then
		error('invalid input param')
	end
	
	-- 找到自己的王座
	local my_to = nil
	util.travalPlayerMap(me,function(m)
		if 'to'==m.type then
			my_to = m
			return true
		end
	end)
	
	if nil==my_to then
		error('has no TO')
	end
	
	util.makesureListExists(me.lobby)
	
	
	local boss = me.lobby.list[boss_index]
	if nil==boss then
		error('invalid index')
	end
	
	local conf = sd.creature[boss.type]
	if 'boss'~=conf.type then
		error('not BOSS')
	end
	
	-- init mob.list at first time
	if nil==my_to.mob then
		my_to.mob = {}
	end
	util.makesureListExists(my_to.mob)
	
	
	-- 王座里的拿掉
	if #my_to.mob.list > 0 then
		local aa = my_to.mob.list[1]
		for i=1,#me.lobby.list do
			local bb = me.lobby.list[i]
			if aa.type==bb.type and aa.level==bb.level then
				bb.num_used = 0
				break
			end
		end
		my_to.mob.list = newArray()
	end
	
	
	-- lobby里的减掉
	boss.num_used = boss.num
	
	-- 放到王座
	table_insert(my_to.mob.list,deepCloneTable(boss))
	
	
	return 0
end

