bson = require("BSon")

local o = {}
local o2 = {}


local lcf = ffi.C


function g_reload_sd()
	o2 = {}
	o.init()
	o.init2()
end



function o.travel_table(t)
	for k,v in pairs(t) do
		if type(v)=='table' then
			io.write(string.format('array [%s] begin  ',k))
			o.travel_table(v)
			io.write(string.format('array [%s] end  ',k))
		else
			io.write(string.format('%s=%s,%s  ',k, bson.type(v)))
		end
	end
	io.write("\n")
end


function o.read_int2(aa,offset)
	return aa[offset] + aa[offset+1]*256
end

function o.read_int4(aa,offset)
	return aa[offset] + aa[offset+1]*256 + aa[offset+2]*256*256 + aa[offset+3]*256*256*256
end

function o.read_from_file(fname)
	local f = io.open(fname,'rb')
	if nil==f then
		error(string.format('can NOT open file %s',fname))
	end
	
	local text = f:read('*a')
	f:close()
	
	local total_len = #text
	--print(total_len)
	
	--local arr_byte = ffi.new("uint8_t[?]",total_len+1)
	local arr_byte = ffi.cast("uint8_t*",text)
	--print(arr_byte)
	--print(ffi.sizeof(arr_byte))
	--print(arr_byte[0])
	--print(arr_byte[4])
	
	--print('=========================')
	local p_index_len = ffi.cast('int32_t*',arr_byte)
	--print(p_index_len[0])
	
	local index_len = p_index_len[0]
	local offset = 4
	local res_t = {}
	
	for safer=1,99999 do
		if index_len-offset <= 4 then
			break
		end
		
		local key_len = o.read_int2(arr_byte,offset)
		--print(key_len)
		offset = offset+2
		
		local key = ffi.string(arr_byte+offset,key_len)
		--print(key)
		offset = offset+key_len
		
		local v_offset = o.read_int4(arr_byte,offset)
		offset = offset+4
		--print(v_offset)
		
		local offset3 = v_offset+index_len
		local bson_len = o.read_int4(arr_byte,offset3)
		offset3 = offset3+4
		local bson_str = ffi.string(arr_byte+offset3,bson_len)
		--print(bson_str)
		
		local bson_t = - (bson.decode2(bson_str))
		--res_t[key] = o.make_table_readonly(bson_t)
		res_t[key] = bson_t
		
		--print('---------------------')
	end
	
	return res_t
end


function o.read_and_set(key_level_1,filename)
	local tt = o.read_from_file(filename)
	--tt = o.make_table_readonly(tt)
	if nil~=tt then
		io.write(string.format('travel  file %s\n\n\n',filename))
		o.travel_table(tt)
		o2[key_level_1] = tt
		return true
	end
	return false
end

function o.finddata(key_level_1,key_level_2)
	local v1 = o[key_level_1]
	
	if nil~=v1 then
		return v1[key_level_2]
	end
	
	return nil
end

-- 注：下面这个函数使一个table变得只读。但是注意：一、他不是修改t而是返回新值；二、有一个副作用，使表变得不可遍历。
function o.make_table_readonly(t)
	if type(t)~='table' then
		return
	end
	
	for k,v in pairs(t) do
		if type(v)=='table' then
			t[k] = o.make_table_readonly(v)
		end
	end
	
	local proxy = {}
	local meta = {__index = function(tab,k) return rawget(t,k) end,
	__newindex=function() error('can NOT set a readonly table') end,
	}
	return setmetatable(proxy,meta)
end

function o.init()
	if 0==g_box_id then
	
	io.output('../aaa.txt')
	o.read_and_set('scene',g_data_dir..'scene.bytes')
	o.read_and_set('creature',g_data_dir..'creature.bytes')
	o.read_and_set('shop',g_data_dir..'shop.bytes')
	o.read_and_set('equip',g_data_dir..'equip.bytes')
	o.read_and_set('achieve',g_data_dir..'achieve.bytes')
	o.read_and_set('daily',g_data_dir..'daily.bytes')
	o.read_and_set('drug',g_data_dir..'drug.bytes')
	o.read_and_set('jin',g_data_dir..'jin.bytes')
	o.read_and_set('default',g_data_dir..'default.bytes')
	o.read_and_set('battle',g_data_dir..'battle.bytes')
	o.read_and_set('guild',g_data_dir..'guild.bytes')
	o.read_and_set('buff',g_data_dir..'buff.bytes')
	o.read_and_set('league',g_data_dir..'league.bytes')
	o.read_and_set('force',g_data_dir..'force.bytes')
	o.read_and_set('trap',g_data_dir..'trap.bytes')
	o.read_and_set('reward',g_data_dir..'reward.bytes')
	o.read_and_set('dungeon',g_data_dir..'dungeon.bytes')
	o.read_and_set('sign',g_data_dir..'sign.bytes')
	o.read_and_set('raid',g_data_dir..'raid.bytes')
	o.read_and_set('wizard',g_data_dir..'wizard.bytes')
	o.read_and_set('event',g_data_dir..'event.bytes')
	o.read_and_set('misc',g_data_dir..'misc.bytes')
	o.read_and_set('lottery',g_data_dir..'lottery.bytes')
	o.read_and_set('lotterycount',g_data_dir..'lotterycount.bytes')
	o.read_and_set('rank',g_data_dir..'rank.bytes')
	o.read_and_set('quality',g_data_dir..'quality.bytes')
	o.read_and_set('item',g_data_dir..'item.bytes')
	o.read_and_set('craft',g_data_dir..'craft.bytes')
	io.close()
	
	end
end

o.init()

function o.init2()
	local pointer_index = 10
	local ap = require('atabletopointer')
	
	if 0==g_box_id then
		-- master
		sd = table.deepclone(o2)
		
		assert(ap.topointer(pointer_index,sd))
		
		print('master OK')
	elseif nil~=g_box_id then
		-- slave
		sd = ap.restoretable(pointer_index)
		assert(sd)
		
		print('slave OK',sd)
		-- for k,v in pairs(sd) do
			-- print(k,'==>',v)
		-- end
	end
end

o.init2()


function o.test3()
	if 1==g_box_id then
		local turns = 500000
		local aa = 0
		
		local t1 = os.clock()
		for i=1,turns do
			for k,v in pairs(sd.equip) do
				aa = aa+1
			end
		end
		local t2 = os.clock()
		print('pairs(sd.equip)',t2-t1,aa)
		
		aa = 0
		t1 = os.clock()
		for i=1,turns do
			local ee = sd.equip.index.enum
			for k,v in pairs(ee) do
				aa = aa+1
			end
		end
		t2 = os.clock()
		print('pairs(sd.equip.index.enum)',t2-t1,aa)
		
		aa = 0
		t1 = os.clock()
		for i=1,turns do
			for jj,v in ipairs(sd.equip.index.enum) do
				aa = aa+1
			end
		end
		t2 = os.clock()
		print('ipairs(sd.equip.index.enum)',t2-t1,aa)
		
		aa = 0
		t1 = os.clock()
		for i=1,turns do
			local lenth = table.getn(sd.equip.index.enum)
			local ee = sd.equip.index.enum
			for jj=1,lenth do
				local k = ee[jj]
				aa = aa+1
			end
		end
		t2 = os.clock()
		print('for jj=1,lenth',t2-t1,aa)
		
		os.exit(-2)
	end
end

--o.test3()
