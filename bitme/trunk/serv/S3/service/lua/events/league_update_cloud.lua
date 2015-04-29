
function onEvent(me)
	local index = getUEParams()
	
	if nil==index or nil==me.basic.arena_cloud then
		return 1
	end		
	local z=''	
	for i=1,#me.basic.arena_cloud do
		local aa = string.sub(me.basic.arena_cloud,i,i)		
		if tonumber(aa)==0 and i<=index then
			aa='1'			
		end		
		z=z..aa
	end
	if ''==z then
		return 1
	end	
	me.basic.arena_cloud=z	
	
	return 0
end

