
function isServ()
	return true
end


local function scan_sort_then_do(this_dir)
	this_dir = g_lua_dir..this_dir
	
	local t = {}
	for file in lfs.dir(this_dir) do
		if 'init.lua'~=file and string.match(file,'%.lua') then
			table.insert(t,file)
		end
	end
	
	table.sort(t,function(a,b)
		local lenth = math.min(#a,#b)
		for i=1,lenth do
			local c1 = string.sub(a,i,i)
			local c2 = string.sub(b,i,i)
			if c1~=c2 then
				return c1<c2
			end
		end
		
		return true
	end)
	
	for i=1,#t do
		local file = t[i]
		print('loading ',file)
		jlpcall(dofile,this_dir..file)
	end
end

scan_sort_then_do('predefine/')
scan_sort_then_do('predefine2/')

-- for file in lfs.dir(this_dir) do
	-- if 'init.lua'~=file and string.match(file,'%.lua') then
		-- print('loading ',file)
		-- jlpcall(dofile,this_dir..file)
	-- end
-- end

-- this_dir = g_lua_dir..'predefine2/'

-- for file in lfs.dir(this_dir) do
	-- if 'init.lua'~=file and string.match(file,'%.lua') then
		-- print('loading ',file)
		-- jlpcall(dofile,this_dir..file)
	-- end
-- end
