
local curl = ffi.load("libcurl")
print('curl',curl)

local lcf = ffi.C

local buf = ffi.new('unsigned char[2048]')
local offset = 0


local function cb(ptr,size1,num,__)
	ffi.copy(buf+offset,ptr,size1*num)
	offset = offset + size1*num
	
	return size1*num
end


local function foo()
		
		local url = 'https://game-api.immomo.com/game/2/server/rank/reset?appid=ex_fakeking_LjLpW8&app_secret=DDFD877D-3FB3-552D-DEDA-A46F8204CF64&score_type=1'
		
		curl.curl_global_init(3)		-- #define CURL_GLOBAL_ALL (CURL_GLOBAL_SSL|CURL_GLOBAL_WIN32)
		local hd = curl.curl_easy_init()
		
		curl.curl_easy_setopt(hd,10002,url)
		
		curl.curl_easy_setopt(hd,20011,ffi.cast('CURL_WRITE_CB',cb))	-- WRITEFUNCTION
		
		curl.curl_easy_setopt(hd,64,0)	-- CA off
		curl.curl_easy_setopt(hd,41,1)	-- verbose
		
		offset = 0
		ffi.fill(buf,2048)
		
		curl.curl_easy_perform(hd)
		
		curl.curl_easy_cleanup(hd)
		
		print('get result')
		local google_ret = ffi.string(buf)
		print(google_ret)
	
	os.exit(-3)		-- 做完就退出
end

foo()
