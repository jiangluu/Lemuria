
local lcf = ffi.C
local counter1 = 0

local ls = require('luastate')

function OnFrame()
	local now = lcf.cur_game_time()
	counter1 = counter1 + 1
	
	-- for test
	local ad = boxraid.ad
	local td = box.get_transdata(ad,ad.next_offset_transdata)
	if 1==td.is_active then
		local r = ls.C.lua_resume(td.co,0)
		print('lua_resume',td.trans_id,r)
		
		if 0==r then
			ls.pushnil(ad.L)
			ls.rawseti(ad.L, ad.stack_at_box_co, td.trans_id)
			
			box.release_transdata(ad,td)
			print('release_transdata')
		end
	end
	
	-- GC self
	if 0==(counter1 % 100) then
		collectgarbage('step',10)
	end
end
