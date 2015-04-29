
function onEvent(me)
	local amount,res_type = getUEParams()	-- UE Param means User Event Param
	
	if nil==amount or nil==res_type then
		error('invalid input param')
	end
	
	if amount<=0 then
		error('invalid amount')
	end
	
	if not (0==res_type or 1==res_type) then
		error('invalid res_type')
	end
	
	local cost = util.getDiamondExchange(amount,res_type)
	
	if cost<=0 then
		error('calc error')
	end
	
	if not util.check(me,'diamond',cost) then
		return 1
	end
	
	util.dec(me,'diamond',cost,'exchange')
	if 0==res_type then
		util.add(me,'meat',amount,'exchange')
	else
		util.add(me,'elixir',amount,'exchange')
	end
	
	util.resPeipin(me)
	
	-- output part
	return 0
end

