
function jlpcall(func,...)
	local ok,msg = pcall(func,...)
	if ok == false then
		print(ok,msg)
		return false
	end
	return msg
end


function eval(str)
    if type(str) == "string" then
        return loadstring("return " .. str)()
    else
        error("is not a string")
    end
end


g_lua_dir = "lua/"
g_data_dir = "data/"

package.path = './lua/mod/?.lua;' .. package.path
--print('package.path',package.path)

jlpcall(dofile,g_lua_dir.."predefine/init.lua")

if 1==g_tag then
	jlpcall(dofile,g_lua_dir.."zero/init.lua")
elseif 2==g_tag then
	jlpcall(dofile,g_lua_dir.."dataread/init.lua")
elseif 3==g_tag then
	jlpcall(dofile,g_lua_dir.."box/init.lua")
end

