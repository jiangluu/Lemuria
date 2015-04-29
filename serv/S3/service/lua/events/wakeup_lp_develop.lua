function onEvent(me)
		--获取药剂三脸信息
	local tb = nil
	
	util.travalPlayerMob(me,function(mob,map)
		if 'tb' == mob.type then
			tb = mob			
			return true
		end
	end)
	
	if nil == tb then
		return 1
	end
	
		--获取时间差，计算与之等值的钻石数
	if nil == tb.next_develop_time then
		tb.next_develop_time = 0
	end
	
	local leftTime = nil
	local stat=nil	
	for i = 1,#me.var.drug.list do
		if me.var.drug.list[i].finish_time> l_cur_game_time() then
			stat=0
			
			leftTime = me.var.drug.list[i].finish_time-l_cur_game_time()
			break
		end
	end
		
	if nil==leftTime then
		for i = 1,#me.var.drug.list do
			if me.var.drug.list[i].finish_time+me.var.drug.list[i].rest_time> l_cur_game_time() then
				leftTime = me.var.drug.list[i].finish_time+me.var.drug.list[i].rest_time-l_cur_game_time()
				stat=1
				
				break
			end
		end
	end
	
	
	if nil == leftTime then
		leftTime = tb.next_develop_time - l_cur_game_time()
	end
	
	local needNum = util.getDiamondExchangeTime(leftTime)
	
	if needNum <= 0 then
		error('time error')
	end
		
		--判断钻石是否足够
	if me.basic['diamond'] < needNum then
		return 1
	end
	
		--条件满足，减去钻石，设置时间
	util.dec(me,'diamond',needNum,'wakeup_drug')
	tb.next_develop_time = tb.next_develop_time - leftTime
	
		for i = 1,#me.var.drug.list do
			if me.var.drug.list[i].finish_time+me.var.drug.list[i].rest_time  > l_cur_game_time() then
				me.var.drug.list[i].finish_time = me.var.drug.list[i].finish_time - leftTime
				if me.var.drug.list[i].finish_time == l_cur_game_time() then	
					if isServ() then
						ach.key_inc3(me,'drug')
					end
				end	
				
			end
		end
		
		

	me.var.drug.a.finish_time=me.var.drug.a.finish_time-leftTime
		--刷新数据
	util.fillCacheData(me)
	
	return 0
end