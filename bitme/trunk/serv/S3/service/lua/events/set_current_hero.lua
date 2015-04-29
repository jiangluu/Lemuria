
function onEvent(me)
	local index = getUEParams()	-- UE Param means User Event Param
	if index>#me.hero.list or index<1 then
		return 1
	end
	for i=1,#me.hero.list do
		me.hero.list[i].inuse = nil
	end
	me.hero.list[index].inuse = true
	
	
	-- output part
	return 0
end

