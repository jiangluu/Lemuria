
local this_dir = g_lua_dir..'predefine/'

for file in lfs.dir(this_dir) do
	if 'init.lua'~=file and string.match(file,'%.lua') then
		print('loading ',file)
		jlpcall(dofile,this_dir..file)
	end
end

