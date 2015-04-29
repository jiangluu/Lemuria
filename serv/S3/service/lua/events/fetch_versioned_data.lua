
function onEvent(me)
	local key,is_get_all = getUEParams()
	
	if isServ() then
		
		local function get_version(key)
			daily.ensure_version(me,key)
			
			return tonumber(me.basic.ver[key].a),tonumber(me.basic.ver[key].b)
		end
	
		if 'pvpreport1'==key then
			if 0~=is_get_all then
				local ss1 = box.serialize(me.pvpreport1)
				daily.push_data_to_c('pvpreport1',ss1)
			else
				local ver_c,ver_serv = get_version(key)
				if ver_serv>ver_c then
					local offset = ver_serv - ver_c
					
					local aa = #me.pvpreport1.list - offset + 1
					aa = math.max(aa,1)
					local t = { list={} }
					for i=aa,#me.pvpreport1.list do
						table.insert(t.list,me.pvpreport1.list[i])
					end
					
					local ss1 = box.serialize(t)
					daily.push_data_to_c('pvpreport1',ss1)
					
					
					-- 最后更新客户端版本号
					daily.set_version(me,'pvpreport1','a',ver_serv)
				else
					return 1
				end
			end
		elseif 'smail'==key then
			local ver_c,ver_serv = get_version(key)
			
			if nil~=me.addition.smail.list and #me.addition.smail.list>0 then
				local to_be_send = {}
				for i=1,#me.addition.smail.list do
					local mm = me.addition.smail.list[i]
					if mm.aid > ver_c then
						table.insert(to_be_send,mm)
					end
				end
				
				if #to_be_send>0 then
					local ss1 = box.serialize({ list=to_be_send })
					daily.push_data_to_c('cache.smail',ss1)
				end
				
			end
			
			-- 暂时先不删除邮件了。以后可能删除没有附件的邮件
			
			-- 最后更新客户端版本号
			daily.set_version(me,key,'a',ver_serv)
			
		end
		
	end
	
	return 0		
end
