
function onEvent(me)
	local begin,endd = getUEParams()
	
	if nil == begin or nil == endd then
		error('invaild params')
	end
	
	if isServ() then
		local function get_version(key)
			daily.ensure_version(me,key)
			
			return tonumber(me.basic.ver[key].a),tonumber(me.basic.ver[key].b)
		end
		
		if nil~=me.addition.smail.list and #me.addition.smail.list>0 then
			local ver_c,ver_serv = get_version('smail')
			
			local new_mail_count = 0
			local has_res_count = 0
			for i=1,#me.addition.smail.list do
				local a = me.addition.smail.list[i]
				if a.aid>ver_c then
					new_mail_count = new_mail_count+1
				end
				
				if a.list and #a.list>0 then
					has_res_count = has_res_count+1
				end
			end
			
			local to_be_send = {}
			
			-- 客户端希望第一封是最新的
			local s_begin = #me.addition.smail.list +1 - begin
			local s_end = #me.addition.smail.list +2 - endd
			
			for i=s_begin,s_end,-1 do
				local mm = me.addition.smail.list[i]
				if mm then
					table.insert(to_be_send,mm)
				else
					break
				end
			end
			
			if #to_be_send>0 then
				local ss1 = box.serialize({ n=new_mail_count,m=has_res_count,list=to_be_send })
				daily.push_data_to_c('cache.smail',ss1)
			end
			
			-- 最后更新客户端版本号
			daily.set_version(me,'smail','a',ver_serv)
			
		end
	end
	
	return 0
end
