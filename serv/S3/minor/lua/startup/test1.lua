
local lcf = ffi.C

local hd = curl.new()

local function foo()
		
		local url = 'https://game-api.immomo.com/game/2/server/rank/reset?appid=ex_fakeking_LjLpW8&app_secret=DDFD877D-3FB3-552D-DEDA-A46F8204CF64&score_type=1'
		
		local r = curl.http_get(hd,url)
		print(r)
	
		os.exit(-3)		-- 做完就退出
end

foo()
