
local o = {}

lz = o


local lcf = ffi.C


local zlib = 0
if "Windows"==ffi.os then
	zlib = ffi.load("zlib1")
else
	zlib = ffi.load("z")
end

if nil==zlib then
	print('zlib init failed!!!')
end


function o.init()
	o.buf_max_len = 1024*64		-- 64K的buf大小，应该足够了。任何解压后的数据也不能超过这个大小
	o.buf = ffi.new("uint8_t[?]", o.buf_max_len)
	o.buflen = ffi.new("unsigned long[2]",0)
end


function o.compress(txt)
	assert(#txt < o.buf_max_len)
	local n = zlib.compressBound(#txt)
	o.buflen[0] = n
	local res = zlib.compress2(o.buf, o.buflen, txt, #txt, 5)
	assert(res == 0)
	return ffi.string(o.buf, o.buflen[0])
end


function o.uncompress(comp)
	o.buflen[0] = o.buf_max_len
	local res = zlib.uncompress(o.buf, o.buflen, comp, #comp)
	assert(res == 0)
	return ffi.string(o.buf, o.buflen[0])
end



o.init()


-- Simple test code.
--[[
local txt = string.rep("abcd", 1000)
print("Uncompressed size: ", #txt)
local c = o.compress(txt)
print("Compressed size: ", #c)
local txt2 = o.uncompress(c, #txt)
print("Uncompressed sizeAAA: ", #txt2)
assert(txt2 == txt)
--]]
