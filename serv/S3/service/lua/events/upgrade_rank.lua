
function onEvent(me)
	local creatureType = getUEParams()	-- UE Param means User Event Param
	if  nil==creatureType then
		return 1
	end
	
	local ranktype=sd.creature[creatureType].rank_up_item
	local currRankLevel=1	
	local function findRankLevel(types)
		for i=1,#me.hero.list do
			if me.hero.list[i].type==creatureType then
				if nil==me.hero.list[i].rank then
					return 1
				else
					return me.hero.list[i].rank
				end
			end
		end
	end
	
	if sd.creature[creatureType].type=='hero' then
		currRankLevel=findRankLevel(creatureType)
	else
		if nil==me.var.research[creatureType .. 'rank'] then
			currRankLevel=1
		else
			currRankLevel=me.var.research[creatureType .. 'rank']
		end
	end
	
	
	----------------------是否已是最高等级
	local array=sd.creature[creatureType].rank
	if currRankLevel>=table.getn(array) then
		return 1
	end
	
	
	--升级花费资源
	local nextneedRes=array[currRankLevel+1].cost_count
	--升级花费碎片
	local nextneedchip=array[currRankLevel+1].item_count
	--升级花费类型
	local nextspendtype=array[currRankLevel+1].cost_type
	--升级所需建筑等级
	local nextmaplevel=array[currRankLevel+1].build_lvl
	
	----------------------是否有足够的碎片来升级
	
	local currentchip=0
	if nil==me.depot.list then
		currentchip=0
	else
		for i=1,#me.depot.list do
			if ranktype==me.depot.list[i].type then
				currentchip=me.depot.list[i].num
				break
			end
		end
	end
	
	if nextneedchip>currentchip then
		return 1
	end
	
	-----------------------资源是否足够	
	local spendtype='meat'
	local function checkResouce()
		if 0==nextspendtype then
			spendtype='meat'
			return me.cache.meat>=nextneedRes
		elseif 1==nextspendtype then
			spendtype='elixir'
			return me.cache.elixir>=nextneedRes
		elseif 2==nextspendtype then
			spendtype='diamond'
			return me.basic.diamond>=nextneedRes
		end
		return false
	end
	if false==checkResouce() then
		return 1
	end
	-----------------------当前建筑等级是否可以升下一集军衔
	local function checkbuildlevel()
		for i=1,#me.map.list do
			if 'wa'==me.map.list[i].type then
				return me.map.list[i].level>=nextmaplevel
			end
		end
		return false
	end
	
	if false==checkbuildlevel() then
		return 1
	end	
	
	---------------减资源
	util.dec(me,spendtype,nextspendtype,'upg_rank')
	---------------减碎片
	for i=1,#me.depot.list do
		if ranktype==me.depot.list[i].type then
				me.depot.list[i].num=me.depot.list[i].num-nextneedchip
				if me.depot.list[i].num<=0 then
					table_remove(me.depot.list,i)
				end
			break
		end
	end
	-------------等级上升
	if sd.creature[creatureType].type=='hero' then
		for i=1,#me.hero.list do
			if me.hero.list[i].type==creatureType then
				if nil==me.hero.list[i].rank then
					me.hero.list[i].rank=2
				else
					 me.hero.list[i].rank= me.hero.list[i].rank+1
				end
				break
			end
		end
	else
		if nil==me.var.research[creatureType .. 'rank'] then
			me.var.research[creatureType .. 'rank']=2
		else
			me.var.research[creatureType .. 'rank']= me.var.research[creatureType .. 'rank']+1
		end		
	end

	return 0
end

