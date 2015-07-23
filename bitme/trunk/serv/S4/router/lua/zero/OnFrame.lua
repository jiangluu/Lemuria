
local lcf = ffi.C
local counter1 = 0

function OnFrame()
	local now = lcf.cur_game_time()
	counter1 = counter1 + 1
	
	-- GC self
	if 0==(counter1 % 100) then
		collectgarbage('step',10)
	end
end
