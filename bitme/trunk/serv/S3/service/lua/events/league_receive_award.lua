
function onEvent(me)
	local last_flag=me.basic.arena_last_flag
	local myrank=me.basic.arena_r
	local min_number=0
	local max_number=0
	local types=nil
	if nil==last_flag or nil==myrank then
		return 1
	end
	
	table.travel_sd(sd.league,function(t,v)
		 min_number=t[v].min_cup
		 max_number=999999
		if nil~=sd.league[v].max_cup then
			max_number=sd.league[v].max_cup
		end
		if last_flag>=min_number and last_flag<=max_number then
			types=v			
			return
		end
	end)
	
	if nil==types then
		return 1
	end
	local array=sd.league[types]['reward']
	local  sz={}	
	
	for i=1,#array do
		if myrank>=array[i].reward_min and myrank<=array[i].reward_max then
			local obj={types=array[i].reward_type,num=array[i].reward_cost}
			table.insert(sz,obj)
		end
	end
	
	if #sz>0 then
		for i=1,#sz do
			if sz[i].types==0 then				
				util.add(me,'meat',sz[i].num,'league')
			elseif sz[i].types==1 then				
				util.add(me,'elixir',sz[i].num,'league')
			elseif sz[i].types==2 then				
				util.add(me,'diamond',sz[i].num,'league')
			end
		end		
	end
	
	me.basic.arena_r=nil	
	me.basic.arena_last_flag=nil	
	me.basic.arena_last_id=nil
	
	return 0
end

