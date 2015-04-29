
-- ����

local o = {}

league = o

local lcf = ffi.C


local league_redis_index = 4

local arena_size = 16	-- 16����һ������
local highest_key = 100
local min_flag = 200	-- ����200���²���������
--local min_ranklist = 6	-- ����200�������Ӧ����6��
local min_ranklist = 0		-- ���Խ׶�
local star_time_len = 10


local arena_list_name = 'arenalist'

-- ˼·�����ڷ������������÷�����һ��16x16�ľ��󡣵�һά�ǽ������������ÿ��Ԫ���Ƿ���������Ϊ�� 0-û�д�� ����0��������õ�����+1
local function id_to_score_matrix(id)
	return string.format('lsc%d',tonumber(id))
end

local function matrix_2D_xy_2_pos(x,y,line_size)
	return (x-1)*line_size + y
end

local function matrix_2D_get(m,x,y,line_size)		-- x,y here begin with 1
	local pos = matrix_2D_xy_2_pos(x,y,line_size)
	if string.len(m)<pos then
		return
	end
	
	return string.sub(m,pos,pos)
end


-- ����2��������ȫ��ֻҪ��һ��BOX���þ͹���
function o.league_start()
	--for i=highest_key,0,-1 do
	print('o.league_start()')
	
	local league_start_time = lcf.cur_game_time()
	
	local local_pool = {}
	local recently_used_pool = {}
	local cur_key = highest_key
	
	
	local function fill_local_pool()
		local filled = 0
		local cursor = 0	-- cursor�����ʼ��Ϊ0
		
		for limiter=1,99999 do
			local key = string.format('l%d',cur_key)
			local t = { redis.command_and_wait(1,'SSCAN %s %s count 100',key,tostring(cursor)) }
			cursor = tonumber(t[1])
			
			for i=2,#t do
				table.insert(local_pool,tonumber(t[i]))
			end
			
			filled = filled + (#t-1)
			
			if 0==cursor then	-- redis done an full iteration
				break
			end
		end
		
		return filled
	end
	
	o.arena_id = 1
	
	local string_all_zero = string.rep('0',arena_size*arena_size + arena_size*star_time_len)
	
	local function gen_an_arena(is_last_arena)
		local arena = { id=o.arena_id,tm=league_start_time,list={} }
		
		local function get_an_sn()
			for limiter=1,999 do
				local aa = table.remove(recently_used_pool)
				if nil==aa then
					return nil
				end
				
				local found = false
				for i=1,#arena.list do
					if aa == arena.list[i] then
						found = true
						break
					end
				end
				
				if false==found then
					return aa
				end
			end
		end
		
		for i=1,arena_size do
			local usersn = table.remove(local_pool)	-- take the last one
			local is_member = true
			if nil==usersn and true==is_last_arena then
				is_member = false
				usersn = get_an_sn()
			end
			
			if nil~=usersn then
				table.insert(arena.list,usersn)
				
				if is_member then
					box.send_todo(usersn,{type='setarena',id=o.arena_id})
				end
			end
			
			if nil~=usersn and is_member then
				table.insert(recently_used_pool,usersn)
				if #recently_used_pool>arena_size*2 then
					table.remove(recently_used_pool,1)		-- FIFO
				end
			end
			
		end
		
		o.arena_id = o.arena_id+1
		local bin = box.serialize(arena)
		
		redis.set(league_redis_index,id_to_score_matrix(o.arena_id-1),string_all_zero)	-- �������һ�̵ķ���
		redis.command_and_wait(league_redis_index,'HSET %s %s %b',arena_list_name,tostring(o.arena_id-1),bin,ffi.cast('size_t',#bin))
		
		return true
	end
	
	for limiter=1,9999 do
		-- �ȴ�redis����������
		local num_get = fill_local_pool()
		cur_key = cur_key-1
		if num_get>0 then
		end
		
		table.shuffle_array(local_pool)
		
		-- �������������һ����������do
		while #local_pool >= arena_size do
			gen_an_arena()
		end
		
		-- �����Ѿ��������ˣ�ֻ�ܽ���
		if cur_key<min_ranklist then
			if #local_pool>0 then
				gen_an_arena(true)
			end
			
			break
		end
	end
	
	-- ���⹤��������min_ranklist���µ���Ҫ�������������Ϊ�п�������һ�ֵ�������
	
	-- for i=0,1 do
		-- local key = string.format('l%d',i)
		-- local t = { redis.command_and_wait(1,'SSCAN %s %s count 100',key,tostring(0)) }
		-- local cursor = t[1]
	-- end
	
end

function o.league_stop()
	print('o.league_stop()')
	
end

function o.matrix_get_my_score(matrix,my_index)
	if my_index<0 or my_index>arena_size or nil==matrix then
		return 0
	end
	
	local sum = 0
	local hit = false
	for i=1,arena_size do
		local aa = o.get_raw_score(matrix,my_index,i)
		if aa>0 then
			hit = true
			sum = sum + (aa-1)
		end
	end
	
	if false==hit then
		return -1
	end
	
	return sum
end

function o.league_end()
	print('o.league_end()')
	
	local now = tonumber(lcf.cur_game_time())
	
	-- ע�����������һ������16���˵�����; û�д������û������
	local function calc_rank(arena,matrix)
		local t = {}
		
		for i=1,arena_size do
			local att_score = o.matrix_get_my_score(matrix,i)
			
			if att_score>=0 then	-- û�д���ģ�û������
				local o = {index=i,att_score=att_score,usersn=arena.list[i]}
				table.insert(t,o)
			end
		end
		
		-- TODO: ��������
		for i=1,#t do
			local a = t[i]
			for jj=1,#t do
				local b = t[jj]
				
				if a.att_score == b.att_score then
					local d = matrix_2D_xy_2_pos(i,jj,arena_size)
					if '1'==d then
						b.def = (b.def or 0) + 1
					end
				end
			end
		end
		
		-- TODO: ����ǵ�ʱ��
		
		-- ����
		table.sort(t,function(a,b)
			if a.att_score~=b.att_score then
				return a.att_score>b.att_score
			else
				if a.def~=b.def then
					return a.def>b.def
				else
					local pos_a = matrix_2D_xy_2_pos(a.index,1,star_time_len) + arena_size*arena_size
					local s_a = string.sub(matrix,pos_a,pos_a+star_time_len)
					
					local pos_b = matrix_2D_xy_2_pos(b.index,1,star_time_len) + arena_size*arena_size
					local s_b = string.sub(matrix,pos_b,pos_b+star_time_len)
					
					return tonumber(s_a)<tonumber(s_b)
				end
			end
			
		end)
		
		for i=1,#t do
			t[i].rank = i
		end
		
		return t
	end
	
	local function deal_one_arena(arena_id)
		local matrix = redis.get(league_redis_index,id_to_score_matrix(arena_id))
		local bin = redis.command_and_wait(league_redis_index,'HGET %s %s',arena_list_name,tostring(arena_id))
		if nil==bin or nil==matrix then
			return false
		end
		
		local data = box.unSerialize(bin)
		
		local a_rank = calc_rank(data,matrix)
		
		-- �������������todo
		for i=1,#a_rank do
			local usersn = a_rank[i].usersn
			local rank = a_rank[i].rank
			
			if rank>0 then
				box.send_todo(usersn,{type='league_award',rank=rank,tm=now})
			end
		end
		
		
		return true
	end
	
	local begin_id = 1
	for limiter=1,9999999 do
		local r = deal_one_arena(begin_id)
		begin_id = begin_id+1
		
		if false==r then
			break
		end
	end
	
end



function o.get_arena_data_app(me)
	local id = me.basic.arena_id
	if nil==id then
		return
	end
	
	local matrix = redis.get(league_redis_index,id_to_score_matrix(id))
	-- cache����
	if nil~=me.cache.league then
		return me.cache.league,matrix
	end
	local bin = redis.command_and_wait(league_redis_index,'HGET %s %s',arena_list_name,tostring(id))
	if nil==bin then
		return
	end
	local data = box.unSerialize(bin)
	
	-- ������Ӧ�ò����Ȥ�Ĵ���
	for i=1,#data.list do
		local usersn = data.list[i]
		
		local is_fake = false
		for jj=1,i-1 do
			local uu = -1
			if 'table'==type(data.list[jj]) then
				uu = data.list[jj].usersn
			else
				uu = data.list[jj]
			end
			if usersn == uu then
				is_fake = true
				break
			end
		end
		
		local basic = db.hget(usersn,'basic')
		basic = box.unSerialize(basic)
		if basic then
			local bb = is_fake or nil
			data.list[i] = {usersn=usersn,name=basic.name,flag=basic.flag,fake=bb}
		end
	end
	-- cache����
	me.cache.league = data
	
	return data,matrix
end


function o.get_raw_score(matrix,attacker_index,defender_index)
	local aa = matrix_2D_get(matrix,attacker_index,defender_index,arena_size)
	return (tonumber(aa) or 0)
end

function o.on_fight_over(me,defender_sn,star)
	if nil==me.cache.league then
		return false
	end
	
	local list = me.cache.league.list
	local index = -1
	for i=1,#list do
		if tonumber(defender_sn)==tonumber(list[i].usersn) then
			index = i
			break
		end
	end
	
	if index<0 then
		return false
	end
	
	local my_index = -1
	for i=1,#list do
		if tonumber(me.basic.usersn)==tonumber(list[i].usersn) then
			my_index = i
			break
		end
	end
	
	if my_index<0 then
		return false
	end
	
	local now = lcf.cur_game_time()
	
	local matrix = redis.get(league_redis_index,id_to_score_matrix(me.cache.league.id))
	if nil==matrix then
		return false
	end
	
	local score = o.get_raw_score(matrix,my_index,index)
	if score>0 then
		-- ��������ԣ�һ����ֻ�ܱ���һ��
		return false
	end
	
	local pos = matrix_2D_xy_2_pos(my_index,index,arena_size)
	redis.command_and_wait(league_redis_index,'SETRANGE %s %s %s',id_to_score_matrix(me.cache.league.id),tostring(pos-1),tostring(star+1))
	
	if star>0 then
		pos = matrix_2D_xy_2_pos(my_index,1,star_time_len)
		pos = pos + arena_size*arena_size
		redis.command_and_wait(league_redis_index,'SETRANGE %s %s %s',id_to_score_matrix(me.cache.league.id),tostring(pos-1),string.format('%010d',now))
	end
	
	return 0
end


-- �����ǻص�����

function o.post_init()
	box.reg_todo_handle('setarena',function(me,dd)
		me.basic.arena_id = dd.id
		me.basic.arena_cloud = '0000'
		me.basic.arena_f = me.basic.flag
		return 0
	end)

	box.reg_todo_handle('league_award',function(me,dd)
		me.basic.arena_r = dd.rank
		me.basic.arena_last_id = me.basic.arena_id
		me.basic.arena_last_flag = me.basic.arena_f
		return 0
	end)
end

