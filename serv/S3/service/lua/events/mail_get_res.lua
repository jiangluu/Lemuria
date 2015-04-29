
function onEvent(me)
	
	local mail_aid = getUEParams()
	
	if isServ() then
	
		local the_mail = nil
		
		for i=1,#me.addition.smail.list do
			if mail_aid==me.addition.smail.list[i].aid then
				the_mail = me.addition.smail.list[i]
				break
			end
		end
		
		if nil==the_mail then
			error('invalid param')
		end
		
		if nil==the_mail.list then
			return 1
		end
		
		local function add_waste(key,amount)
			local to_add = amount
			if 'diamond'~=key then
				local limit = me.basic[key..'_limit']
				to_add = math.min(to_add,limit-me.basic[key])
			end
			
			if to_add>0 then
				util.add(me,key,to_add,'mail_get')
			elseif to_add<0 then
				util.dec(me,key,-to_add,'mail_get')
			end
		end
		
		local maybe_has = {'meat','elixir','diamond'}
		for i=1,#the_mail.list do
			local res_type = the_mail.list[i].type+1
			local res_key = maybe_has[res_type]
			
			if res_key and the_mail.list[i].num>0 then
				add_waste(res_key,tonumber(the_mail.list[i].num))
			end
		end
		
		
		util.fillCacheData(me)
		
		local aa = { diamond=me.basic.diamond,meat=me.basic.meat,elixir=me.basic.elixir }
		daily.push_data_to_c('cache.mail_res',box.serialize(aa))
		
		-- 领了奖励后就删除
		for i=1,#me.addition.smail.list do
			if mail_aid==me.addition.smail.list[i].aid then
				table.remove(me.addition.smail.list,i)
				break
			end
		end
		
	end
	
	return 0		
end
