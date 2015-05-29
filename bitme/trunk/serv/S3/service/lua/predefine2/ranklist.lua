
-- ranklist在山寨王游戏中是积分天梯的意思
local o = {}

ranklist = o






local phb_num = 200
local phb_internal_num = phb_num * 1.2
local phb_redis_name = 'phb'


local get_rank_key = function(aa)
	--local rank_lv = math.floor(aa/100)	-- 内部分级算法，暂时就最简单的
	-- 因为预料会有大量的新玩家堆积，写一个分段函数
	local rank_lv = 0
	if aa>0 then
		if aa<=70 then
			rank_lv = 1
		else
			rank_lv = math.floor((aa+29)/100)+1
		end
	end
	return string.format('l%d',rank_lv)
end

o.rank_to_key = get_rank_key

function o.add(usersn,rank,old_rank)
	local key = get_rank_key(rank)
	redis.command_and_wait(1,'SADD %s %s',key,tostring(usersn))
	
	if nil~=old_rank then
		local old_key = get_rank_key(old_rank)
		if key~=old_key then
			redis.command_and_wait(1,'SREM %s %s',old_key,tostring(usersn))
		end
	end
	
	-- @NOTE: 游戏初期是这样，每次更新积分天梯的同时，也更新排行榜。
	-- 运营一段时间后可以改成，只有积分天梯最后一段的玩家，才更新排行榜。因为这时整体人数够多，可以肯定 只有积分天梯最后一段的玩家，才有入榜的可能性
	
	-- 先不论如何都往排行榜里更新
	redis.command_and_wait(1,'ZADD %s %s %s',phb_redis_name,tostring(rank),tostring(usersn))
	
	-- 每更新N次（概率上），做一次截断操作，确保个数在 phb_internal_num 之内
	local N = 100
	local rr = math.random(0,N)
	if N-1 == rr then
		redis.command_and_wait(1,'ZREMRANGEBYRANK %s %s %s',phb_redis_name,tostring(-phb_internal_num-1000),tostring(-phb_internal_num))
	end
	
	--[[
	-- 看看是否要更新排行榜
	local aa = {redis.command_and_wait(1,'ZREVRANGE %s %s %s WITHSCORES',phb_redis_name,tostring(phb_internal_num-1),tostring(phb_internal_num-1))}
	local need_update = false
	if #aa>=2 then
		local the_last_in_phb = tonumber(aa[2])
		if nil~=the_last_in_phb and rank>the_last_in_phb then
			need_update = true
		end
	else
		-- 排行榜还没有满
		need_update = true
	end
	
	if need_update then
		-- 更新新的值
		redis.command_and_wait(1,'ZADD %s %s %s',phb_redis_name,tostring(rank),tostring(usersn))
		-- 确保个数在 phb_internal_num 之内
		redis.command_and_wait(1,'ZREMRANGEBYRANK %s %s %s',phb_redis_name,tostring(-phb_internal_num),tostring(-phb_internal_num-100))
	end
	--]]
end

function o.del(usersn,rank)
	local key = get_rank_key(rank)
	redis.command_and_wait(1,'SREM %s %s',key,tostring(usersn))
end

function o.random(rank)
	local key = get_rank_key(rank)
	return redis.command_and_wait(1,'SRANDMEMBER %s',key)
end


local global_phb_redis = 5
local need_inform_s = {'S0','S10',}

-- 根据积分天梯生成排行榜
function o.gen_phb(from_rank,to_rank,is_global)
--[[
			local phb_total = 210
			local ret = {}
			
			for i=999,1,-1 do
				local key = string.format('l%d',i)
				local nums = redis.command_and_wait(1,'SCARD %s',key)
				
				if nums>0 then
					local aa = math.min(phb_total,nums)
					local tt = {redis.command_and_wait(1,'SRANDMEMBER %s %d',key,aa)}
					if #tt==aa then
						for jj=1,#tt do
							local usersn = tostring(tt[i])
							local basic = db.hget(usersn,'basic')
							if nil~=basic then
								local dd = box.unSerialize(basic)
								
								table.insert(ret,{name=dd.name,flag=dd.flag,exp=dd.exp})
								
								phb_total = phb_total - 1
							end
						end
					end
					
					if phb_total<=0 then
						break
					end
				end
			end
			
			return ret
--]]
	local ret = {}
	
	if to_rank>(phb_num+1) then
		return ret
	end
	
	local phb_redis = 1
	if true==is_global then
		phb_redis = global_phb_redis
	end
	
	local redis_data = {redis.command_and_wait(phb_redis,'ZREVRANGE %s %s %s WITHSCORES',phb_redis_name,tostring(from_rank-1),tostring(to_rank-2))}
	--print('ZREVRANGE GET NUM',#redis_data)
	if #redis_data>=2 then
		for ii=1,(#redis_data)/2 do
			local usersn = tostring(redis_data[ii*2-1])
			local score = tonumber(redis_data[ii*2])
			--print(usersn)
			local basic_bin = db.hget(usersn,'basic')
			if nil~=basic_bin then
				local basic = box.unSerialize(basic_bin)
				
				local guild_name = nil
				local guild_mark=nil
				local guild_id=nil
				if nil~=basic.guild then
					guild_id = basic.guild.id
					guild_name=basic.guild.name
					guild_mark=basic.guild.mark
				end
				table.insert(ret,{usersn=usersn,name=basic.name,flag=score,exp=basic.exp,guild_id=guild_id,guild_name=guild_name,guild_mark=guild_mark})
				--print('add',basic.lkey)
			end
		end
	end
	
	return ret
end

function o.query_my_rank(usersn)
	local aa = redis.command_and_wait(1,'ZREVRANK %s %s',phb_redis_name,tostring(usersn))
	return tonumber(aa)
end


local lcf = ffi.C

function o.global_phb_fill()
	local redis_data = {redis.command_and_wait(1,'ZREVRANGE %s 0 99 WITHSCORES',phb_redis_name)}
	if #redis_data>=2 then
		for ii=1,(#redis_data)/2 do
			local usersn = tostring(redis_data[ii*2-1])
			local score = tonumber(redis_data[ii*2])
			
			local basic_bin = db.hget(usersn,'basic')
			local map_bin = db.hget(usersn,'map')
			if nil~=basic_bin then
				-- 把此人放入世界排行榜
				lcf.cur_write_stream_cleanup()
				l_gx_cur_writestream_put_slice('phb')
				local gusersn = string.format('%sU%s',g_app_id,usersn)
				l_gx_cur_writestream_put_slice(gusersn)
				l_gx_cur_writestream_put_slice(basic_bin)
				l_gx_cur_writestream_put_slice(map_bin)
				
				for i=1,#need_inform_s do
					local r = lcf.gx_cur_writestream_route_to(need_inform_s[i],2223)
				end
		
				redis.command_and_wait(global_phb_redis,'ZADD %s %s %s',phb_redis_name,tostring(score),gusersn)
			end
		end
	end
end


