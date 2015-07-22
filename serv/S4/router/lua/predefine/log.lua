
-- artme的日志系统。具体实现在C里。
-- 用法： alog.verbose(xx)  alog.debug(xx) 等。xx必须是个字符串或者能转化成字符串。

local o = {}

alog = o


local lcf = ffi.C
function o.verbose(s)
	return lcf.log_write(0,tostring(s),#s)
end

function o.debug(s)
	print(s)
end

function o.info(s)
	return lcf.log_write(2,tostring(s),#s)
end

function o.warning(s)
	return lcf.log_write(3,tostring(s),#s)
end

function o.error(s)
	print(s)
end

function o.final(s)
	return lcf.log_write(5,tostring(s),#s)
end

function o.force_flush()
end

