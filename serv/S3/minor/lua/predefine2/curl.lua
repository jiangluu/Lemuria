
local lc = ffi.load("libcurl")

curl = lc


local function init()
	lc.curl_global_init(3)		-- #define CURL_GLOBAL_ALL (CURL_GLOBAL_SSL|CURL_GLOBAL_WIN32)
end

init()
