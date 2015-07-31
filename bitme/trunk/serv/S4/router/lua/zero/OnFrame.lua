
local lcf = ffi.C
local counter1 = 0

local ls = require('luastate')

function OnFrame()
	local now = lcf.cur_game_time()
	counter1 = counter1 + 1
	
	
	-- GC self
	if 0==(counter1 % 100) then
		collectgarbage('step',10)
		
		for i=1,boxraid.box_num+1 do
			local box = boxraid.getboxc(i)
			ls.gc(box.L, ls.C.LUA_GCSTEP ,10)
		end
		
	end
end
