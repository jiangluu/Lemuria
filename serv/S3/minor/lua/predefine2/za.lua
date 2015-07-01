
local pre_time = 0

function onFrame()
	pipeline.process_all_pipeline()
	
	local now = os.time()
	if 0==pre_time then
		pre_time = now
	else
		if now >= pre_time+20 then
			mysql.ping_all()
			
			pre_time = now
		end
	end
end


local function run_startup_things()
	for file in lfs.dir(g_lua_dir..'startup/') do
		if string.match(file,'%.lua') then
			print('going to run',file,'......')
			jlpcall(dofile,g_lua_dir..'startup/'..file)
		end
	end
end

run_startup_things()
