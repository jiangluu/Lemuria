
local lcf = ffi.C


local gates = {'pd','od','ad','sd','hd','rd','dd','td',}

local function is_gate(t)
	for i=1,#gates do
		if t == gates[i] then
			return true
		end
	end
	
	return false
end

local function check_map(m,old)

	if #m.list ~= #old.list then
		return false
	end

	-- 先纠正八门位置，因为它们是不可移动的
	for i=1,#m.list do
		local mm = m.list[i]
		if is_gate(mm.type) then
			local olist = sd.default.map.list
			
			for jj=1,#olist do
				local nn = olist[jj]
				if mm.type == nn.type then
					mm.x = nn.x
					mm.y = nn.y
					mm.level = nn.level
					
					break
				end
			end
		end
	end
	
	-- 先用“目测法”，处理完所有“简单地块”。简单地块是指1x1 2x2且四面通气的。这部分代码容易写，不容易出bug
	-- 位置是左下原点
	-- 方向：上是0，然后顺时针是 1 2 3
	-- 2x2的建筑无论怎么转，左上角是坐标所在
	local blocks = {}
	
	for i=1,#m.list do
		local mm = m.list[i]
		
		local conf = sd.scene[mm.type]
		if conf then
			local is_simple = false
			if 2==conf.block_type then
				is_simple = true
			elseif 1==conf.block_type and 4==table.getn(conf.gates) then
				is_simple = true
			end
			
			if is_simple then
				table.insert(blocks,{simple=true,type=mm.type,x=mm.x,y=mm.y,size=conf.block_type})
			else
				table.insert(blocks,{type=mm.type,x=mm.x,y=mm.y,block_type=conf.block_type,dir=mm.direction,gates=conf.gates})
			end
		end
	end
	
	for i=1,#blocks do
		local m = blocks[i]
		if is_gate(m.type) then
			m.qi = true
		end
	end
	
	local function infect_neibor_simple(x,y)
		local count = 0
		
		local function cond(x,y,xa,ya)
			return (x==xa and 1==math.abs(y-ya)) or (y==ya and 1==math.abs(x-xa))
		end
		
		for i=1,#blocks do
			local m = blocks[i]
			
			if nil==m.qi and m.simple then
				if 1==m.size and cond(x,y,m.x,m.y) then
					count = count+1
					m.qi = true
				end
				
				if 2==m.size and (cond(x,y,m.x,m.y) or cond(x,y,m.x+1,m.y) or cond(x,y,m.x+1,m.y-1) or cond(x,y,m.x,m.y-1)) then
					count = count+1
					m.qi = true
				end
			end
		end
		
		return count
	end
	
	for limiter=1,10 do
		local count = 0
		
		for i=1,#blocks do
			local m = blocks[i]
			if true==m.qi and m.simple and 1==m.size then
				count = count + infect_neibor_simple(m.x,m.y)
				
			elseif true==m.qi and m.simple and 2==m.size then
				count = count + infect_neibor_simple(m.x,m.y)
				count = count + infect_neibor_simple(m.x+1,m.y)
				count = count + infect_neibor_simple(m.x+1,m.y-1)
				count = count + infect_neibor_simple(m.x,m.y-1)
			end
		end
		
		if 0==count then
			break
		end
	end
	
	local has_no_qi = 0
	for i=1,#blocks do
		if nil==blocks[i].qi then
			has_no_qi = has_no_qi+1
		end
	end
	
	if 0==has_no_qi then
		return true
	end
	
	-- 考虑方向等，处理非简单地块。
	local function rotate(m,index)
		m.g = {}
		for i=1,#m.gates do
			if index==m.gates[i].block_no then
				local dir = m.gates[i].direction
				dir = (dir+m.dir)%4
				m.g[dir] = true
			end
		end
	end
	
	local plain = {}
	for i=1,#blocks do
		local b = blocks[i]
		if b.simple then
			if 1==b.size then
				table.insert(plain,b)
			elseif 2==b.size then
				table.insert(plain,{simple=true,qi=b.qi,type=b.type,x=b.x,y=b.y,dir=b.dir,size=b.size,p=b})
				table.insert(plain,{simple=true,qi=b.qi,type=b.type,x=b.x+1,y=b.y,dir=b.dir,size=b.size,p=b})
				table.insert(plain,{simple=true,qi=b.qi,type=b.type,x=b.x+1,y=b.y-1,dir=b.dir,size=b.size,p=b})
				table.insert(plain,{simple=true,qi=b.qi,type=b.type,x=b.x,y=b.y-1,dir=b.dir,size=b.size,p=b})
			end
		else
			if 1==b.block_type then
				local d = deepCloneTable(b)
				d.p = b
				rotate(d,0)
				table.insert(plain,d)
			elseif 3==b.block_type then
				local d = deepCloneTable(b)
				d.p = b
				rotate(d,0)
				table.insert(plain,d)
				
				d = deepCloneTable(b)
				d.p = b
				rotate(d,1)
				if 0==d.dir then
					d.x = d.x+1
				elseif 1==d.dir then
					d.y = d.y-1
				elseif 2==d.dir then
					d.x = d.x-1
				elseif 3==d.dir then
					d.y = d.y+1
				end
				table.insert(plain,d)
			end
		end
	end
	
	local function be_qi(m)
		local count = 0
		
		local function cond(x,y,xa,ya)
			return (x==xa and 1==math.abs(y-ya)) or (y==ya and 1==math.abs(x-xa))
		end
		
		local function get_qi(m)
			if m.p then
				return m.p.qi
			else
				return m.qi
			end
		end
		
		local function has_gate(m,dir)
			if m.simple then
				return true
			else
				return m.g[tonumber(dir)]
			end
		end
		
		for i=1,#plain do
			local has_qi = plain[i]
			
			if get_qi(has_qi) and cond(m.x,m.y,has_qi.x,has_qi.y) then
				if (has_qi.x>m.x and has_gate(has_qi,3) and has_gate(m,1)) or
					(has_qi.x<m.x and has_gate(has_qi,1) and has_gate(m,3)) or
					(has_qi.y>m.y and has_gate(has_qi,2) and has_gate(m,0)) or
					(has_qi.y<m.y and has_gate(has_qi,0) and has_gate(m,2)) then
					
					count = count+1
					m.qi = true
					if m.p then
						m.p.qi = true
					end
				end
			end
		end
		
		return count
	end
	
	for limiter=1,10 do
		local count = 0
		
		for i=1,#plain do
			local m = plain[i]
			
			if nil==m.qi then
				count = count + be_qi(m)
			end
		end
		
		if 0==count then
			break
		end
	end
	
	
	has_no_qi = 0
	for i=1,#blocks do
		if nil==blocks[i].qi then
			has_no_qi = has_no_qi+1
		end
	end
	
	if has_no_qi<5 then
		return true
	else
		return false
	end
	
end


-- Trusted-push 	15 	<<(string)key<<(string)json_string 	可信任的直接修改数据，服务端不做验证的。具体数据由json串描述
box.reg_handle(15,function(me)
	
	local key = l_cur_stream_get_slice()
	local is_zip = lcf.cur_stream_get_int16()
	local bin = l_cur_stream_get_slice()
	
	local function err_ack()
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(1)
		lcf.cur_stream_write_back()
	end
	
	
	if 'map'~=key then
		err_ack()
		return 1
	end
	
	local aa = 0
	if 0==is_zip then
		aa = box.unSerialize(bin)
	else
		aa = lz.uncompress(bin)
		aa = box.unSerialize(aa)
	end
	
	if nil==aa then
		err_ack()
		return 1
	end
	
	if not check_map(aa,me[key]) then
		err_ack()
		return 1
	end
	
	me[key] = aa
	
	
	lcf.cur_write_stream_cleanup()
	lcf.cur_stream_push_int16(0)
	lcf.cur_stream_write_back()
	
	return 0
end)

