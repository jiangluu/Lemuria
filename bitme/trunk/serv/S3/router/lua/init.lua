
function jlpcall(func,...)
	local err,msg = pcall(func,...)
	if err == false then
		print(err,msg)
	end
end


function eval(str)
    if type(str) == "string" then
        return loadstring("return " .. str)()
    else
        error("is not a string")
    end
end


g_lua_dir = "lua/"


jlpcall(dofile,g_lua_dir.."predefine/init.lua")


