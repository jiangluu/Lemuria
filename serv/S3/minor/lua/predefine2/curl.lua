
local lc = ffi.load("libcurl")

local o = {}

curl = o


function o.init()
	lc.curl_global_init(3)		-- #define CURL_GLOBAL_ALL (CURL_GLOBAL_SSL|CURL_GLOBAL_WIN32)
	
	o.buf_len = 2048
	o.buf = ffi.new('char[?]',o.buf_len)
	o.offset = 0
end

function o.new()
	return lc.curl_easy_init()
end

function o.reset(hd)
	lc.curl_easy_reset(hd)
end

local function cb(ptr,size1,num,__)
	ffi.copy(o.buf+o.offset,ptr,size1*num)
	o.offset = o.offset + size1*num
	
	return size1*num
end

function o.http_get(hd,url)
		lc.curl_easy_reset(hd)
		lc.curl_easy_setopt(hd,10002,url)
		lc.curl_easy_setopt(hd,20011,ffi.cast('CURL_WRITE_CB',cb))	-- WRITEFUNCTION
		lc.curl_easy_setopt(hd,64,0)	-- CA off
		lc.curl_easy_setopt(hd,41,1)	-- verbose
		
		o.offset = 0
		ffi.fill(o.buf,o.buf_len)
		
		lc.curl_easy_perform(hd)
		lc.curl_easy_cleanup(hd)
		
		return ffi.string(o.buf)
end


o.init()
