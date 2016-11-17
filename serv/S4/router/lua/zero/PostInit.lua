
function PostInit()
	print('zero PostInit')
	local ls = require('luastate')
	
	for i=1,boxraid.box_num do
		local box = boxraid.getboxc(i)
		if nil~=box then
			jlpcall(gRemoteCall,box,'postinit',8000)
		end
	end
	
	-- ===================================
	
	return 0
	
end
