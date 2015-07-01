
local o = {}

pipeline = o



o.array = {}
o.map = {}

local lcf = ffi.C

function o.add_pipeline(name,ip,port)
	table.insert(o.array,{ name=name,ip=ip,port=port,filter={} })
	o.map[name] = #o.array
end

function o.reg_filter(pipeline_name,f)
	local index = o.map[pipeline_name]
	if index then
		local p = o.array[index]
		if p then
			table.insert(p.filter,f)
		end
	end
end

function o.ready_to_run()
	-- 目前思路：每个pipeline一个redis连接
	for i=1,#o.array do
		local pipeline = o.array[i]
		local connection = lcf.redisConnectWithTimeout2(pipeline.ip,pipeline.port,2000)
		connection = ffi.cast('redisContext*',connection)
		
		table.insert(redis.conn,connection)
	end
end

function o.process_all_pipeline()
	for jj=1,#o.array do
		local pipeline = o.array[jj]
		
		local limiter = 100000
		for i=1,limiter do
			local ok,re = redis.exec_and_reply(i,'RPOP %s',pipeline.name)
			if false==ok or nil==re then
				break
			end
			
			-- process it
			local date_and_time,other = string.match(re,'([^,]+),(.+)')
			if date_and_time and other then
				local counter = 0
				local suc_counter = 0
				local err_counter = 0
				
				for jj=1,#pipeline.filter do
					local filter = pipeline.filter[jj]
					-- 防止一个filter改了日志的值，影响之后的filter
					local aa = other
					local bb = date_and_time
					
					local err,ret = pcall(filter,aa,bb)
					if false==err then
						err_counter = err_counter+1
						print(ret)
					else
						if 200==ret then
							suc_counter = suc_counter+1
						else
							-- nothing
						end
					end
					
					counter = counter+1
				end
				
				local surfix = 0
				if 0==counter then
					surfix = '_nodeal'
				else
					if err_counter>0 then
						surfix = '_err'
					elseif 0==suc_counter then
						surfix = '_fail'
					else
						surfix = '_suc'
					end
				end
				
				redis.exec_and_reply(i,'LPUSH %s %s',pipeline.name..surfix,re)
			else
				print('log error >>>>',re)
			end
		end
	end
end


local function reg_all_pipeline_filter()
	for file in lfs.dir(g_lua_dir..'filter/') do
		if string.match(file,'%.lua') then
			local aa = string.gsub(file,'%.lua','')
			local bb = string.match(aa,'(%w+)')
			jlpcall(dofile,g_lua_dir..'filter/'..file)
			o.reg_filter(bb,onEvent)
			onEvent = nil
		end
	end
end


jlpcall(dofile,g_lua_dir.."pipeline_define.lua")

reg_all_pipeline_filter()


o.ready_to_run()
