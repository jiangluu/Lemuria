
ffi.cdef [[
struct phr_header {
    const char *name;
    size_t name_len;
    const char *value;
    size_t value_len;
};

struct _phr_parse_data{
	char *method, *path;
	int minor_version;
	struct phr_header headers[8];
	size_t method_len, path_len, num_headers;
	const char* src;
	size_t src_len;
};
]]

local lcf = ffi.C
local ls = require('luastate')


function OnHttpReq(pa)
	local aa = ffi.cast('struct _phr_parse_data*', pa)
	local s = ffi.string(aa.src, aa.src_len)
	print("LUA HTTP:", s)
	print("HHHH" ,aa.num_headers, "\n")
	for i=0, tonumber(aa.num_headers)-1,1 do
		local h = aa.headers[i]
		print("HEADER",i, ffi.string(h.name, h.name_len), '-->', ffi.string(h.value, h.value_len))
	end

	l_gx_cur_stream_push_text("HTTP/1.0 200 OK\r\n\r\n")
	lcf.cur_stream_write_back()

	return 0
end
