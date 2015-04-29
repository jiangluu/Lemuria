
function onEvent(me)
	local shop_hash = getUEParams()	-- UE Param means User Event Param
	
	
	if nil==shop_hash then
		error('invalid input param')
	end
	
	me.cache.shop = util.generateShop(me)
	
	-- logic part, some code here
	local shop_item = nil
	for i=1,#me.cache.shop do
		if shop_hash==me.cache.shop[i].hash then
			shop_item = me.cache.shop[i]
			break
		end
	end
	
	if nil==shop_item then
		error('invalid shop_hash')
	end
	
	if 5~=shop_item.catagory then
		error('invalid catagory')
	end
	
	if 3~=shop_item.cost_type then
		print('buybuybuy',shop_item.type)
		
		if util.dec(me,'elixir',shop_item.cost,'precious') then
			
			if 9==shop_item.get_type then
				util.add(me,'diamond',1000,'buy_mc')
				
				local old = me.addition.daily.mc_time or l_cur_game_time()
				me.addition.daily.mc_time = old + (sd.misc.default.mc_day*24*3600)
				
				-- update daily
				for i=1,#me.addition.daily.list do
					local aa = me.addition.daily.list[i]
					if aa.mc then
						aa.stat = math.max(1,aa.stat)
						if aa.mc<=0 then
							aa.mc = sd.misc.default.mc_day
						else
							aa.mc = aa.mc+sd.misc.default.mc_day
						end
						
						break
					end
				end
				
			end
		end
	end
	
	
	util.resPeipin(me)
	
	-- output part
	return 0
end

