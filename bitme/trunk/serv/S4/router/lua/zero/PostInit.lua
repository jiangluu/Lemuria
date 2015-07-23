
function PostInit()
	print('zero PostInit')
	local ls = require('luastate')
	
	for i=1,boxraid.box_num do
		local box = boxraid.a_box[i-1]
		ls.getglobal(box.L,'postinit')
		local ok,err = ls.pcall(box.L)
		if not ok then
			print(err)
		end
	end
end
