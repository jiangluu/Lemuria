
local lcf = ffi.C

local prefix_google_bind = 'google_bind_'
local prefix_apple_bind = 'gamecenter_bind_'
local prefix_fb_bind = 'fb_bind_'
local prefix_google_nick = 'google_nick_'
local prefix_apple_nick = 'gamecenter_nick_'
local prefix_fb_nick = 'fb_nick_'


-- bindID 	27 	<<(WORD)type<<(string)id 	绑定苹果或者谷歌ID type:gamecenter=1,google+=2
box.reg_handle(27,function(me)
	local typee = lcf.cur_stream_get_int16()
	local strid = l_cur_stream_get_slice()
	local s_mail = l_cur_stream_get_slice()
	
	local function err_ack(err)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int16(err)
		lcf.cur_stream_push_int16(typee)
		lcf.cur_stream_write_back()
	end
	
	print('msg27',typee,strid,s_mail,me.basic.usersn)
	
	local prefix = 0
	if 1==typee then
		prefix = 'gamecenter%s'
	elseif 2==typee then
		prefix = 'google+%s'
	elseif 3==typee then
		prefix = 'facebook%s'
	else
		err_ack(7)
		return 0
	end
	
	local db_key = string.format(prefix,strid)
	
	local key2 = 0
	if 1==typee then
		key2 = prefix_apple_bind..me.basic.usersn
	elseif 2==typee then
		key2 = prefix_google_bind..me.basic.usersn
	elseif 3==typee then
		key2 = prefix_fb_bind..me.basic.usersn
	else
		err_ack(7)
		return 0
	end
	local already_bind_id = db.get(key2)
	local usersn = db.get(db_key)
	
	if already_bind_id and usersn then
		-- 已经绑好了
		if tonumber(usersn)==tonumber(me.basic.usersn) then
			err_ack(0)
		else
			-- 给她提示
			local bin = db.command_and_wait(db.hash(tonumber(usersn)),'HGET %s basic',tostring(usersn))
			if bin then
				local bb = box.unSerialize(bin)
				if bb then
					local tt = {to=bb.tol,name=bb.name}
					
					daily.push_data_to_c('cache.bind_hint',box.serialize(tt))
				end
			end
			
			err_ack(3)
		end
	elseif nil==already_bind_id and nil==usersn then
		-- 没有绑过，给她绑
		
		box.do_save_player(me)		-- 不是一定必要的，为了安全性
		
		-- 下面两条数据照道理应该都有OR都没有
		db.set(key2,strid)
		db.set(db_key,me.basic.usersn)
		
		if nil~=s_mail then
			local aa = 0
			if 1==typee then
				aa = prefix_apple_nick..s_mail
			elseif 2==typee then
				aa = prefix_google_nick..s_mail
			elseif 3==typee then
				aa = prefix_fb_nick..s_mail
			end
			
			db.set(aa,me.basic.usersn)
		end
		
		err_ack(0)
	elseif nil~=usersn then
		-- 给她提示
		local bin = db.command_and_wait(db.hash(tonumber(usersn)),'HGET %s basic',tostring(usersn))
		if bin then
			local bb = box.unSerialize(bin)
			if bb then
				local tt = {to=bb.tol,name=bb.name}
				
				daily.push_data_to_c('cache.bind_hint',box.serialize(tt))
			end
		end
		
		err_ack(1)
	else
		err_ack(2)
	end
	
	return 0
end)

