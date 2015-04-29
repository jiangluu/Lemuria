
function onEvent(me)
	local is_global,idx_1,idx_2 = getUEParams()
	
	
	local num = idx_2 - idx_1
	
	if isServ() then
		local lcf = ffi.C
		
		local phb = ranklist.gen_phb(idx_1,idx_2)
		
		local bbb = {}
		local usersn = me.basic.usersn

		bbb.list = phb
		
		
		bbb.my_rank = ranklist.query_my_rank(usersn)
		if nil==bbb.my_rank then
			bbb.my_rank = 874
		else
			bbb.my_rank = bbb.my_rank+1
		end
		
		
		-- for i=1,num do
			-- table.insert(bbb.list,{name=string.format('yangyang%d',i),flag=10000-i,exp=1000-i})
		-- end
		
					local str = box.serialize(bbb)
					
					daily.push_data_to_c('phb',str)
	end
	
	return 0		
end

