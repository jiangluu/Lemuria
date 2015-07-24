
local lcf = ffi.C

local o = {}

ui = o

o.cmds = {{'PING',{2221,1}},
	{'BOX',{8019}},
	{'reload handle',{8017,'handle'}},
	{'reload data',{8017,'data'}},
	{'reload all',{8017,'all'}},
	{'global_phb_fill',{2225}},
	
	{'league start',{1101,'league start'} },
	{'league end',{1101,'league end'} },
	{'broadcast',{1101,'league end'} },
	{'smail',{1101,'smail'} },
	{'retty',{1101,'retty'} },
}


function o.post_init()
	o.text1 = iup.multiline{READONLY='yes',VISIBLELINES=40,VISIBLECOLUMNS=80}
	
	o.magic = ffi.new('char[?]',16)
	--o.magic[0] = 1
	
	local function make_sure_target()
		if nil==o.target_app then
			local aa = iup.GetText('Set services which you want to send msg to','')
			
			local t = {}
			for dd in string.gmatch(aa,'(%w+)') do
				table.insert(t,dd)
			end
			
			if #t>0 then
				o.target_app = t
			end
		end
		
		return nil~=o.target_app
	end
	
	local function send_cmd(cmd,btn_title)
		if not make_sure_target() then
			error('NO target set')
		end
		
		if 'table'==type(cmd) and #cmd>=1 and nil~=tonumber(cmd[1]) then
			ssh.update_all_file(getRouterPort())
			
			l_gx_cur_writestream_cleanup()
			
			local msg_id = tonumber(cmd[1])
			if not (msg_id>=8000 and msg_id<8100) then
				lcf.gx_cur_stream_push_bin(o.magic,16)
			end
			
			for i=2,#cmd do
				local aa = cmd[i]
				if aa then
					if 'number'==type(aa) then
						lcf.gx_cur_stream_push_int32(aa)
					elseif 'string'==type(aa) then
						l_gx_cur_writestream_put_slice(aa)
					end
				end
			end
			
			-- 有更多参数的
			if 'smail'==cmd[2] then
				iup.SetGlobal('UTF8MODE','yes')
				local ok,usersn,type2,icon,title,text = iup.GetParam('input system-mail',nil,'to usersn%i\ntype%l|1|2|\nicon%s\ntitle%s\ntext%s\n',1,0,'1','','')
				print(ok,usersn,type2,icon,title,text)
				
				if true==ok then
					l_gx_cur_writestream_put_slice(tostring(usersn))
					lcf.gx_cur_stream_push_int32(type2)
					l_gx_cur_writestream_put_slice(icon,0)
					l_gx_cur_writestream_put_slice(title,0)
					l_gx_cur_writestream_put_slice(text,0)
				end
			elseif 'retty'==cmd[2] then
				local ok,tty = iup.GetParam('input tty',nil,'tty:%s\n','/dev/pts/0')
				
				if true==ok then
					l_gx_cur_writestream_put_slice(tty)
				end
			end
			
			for i=1,#o.target_app do
				local aa = o.target_app[i]
				lcf.gx_cur_writestream_route_to(aa,msg_id)
			end
			
			return
		end
		
		
		
		
		
		if 'broadcast'==cmd then
			iup.SetGlobal('UTF8MODE','yes')
			local msg = iup.GetText('input broadcast text','')
			if nil~=msg then
				print('broadcast',msg)
				lcf.cur_stream_push_string(msg,0)
				lcf.cur_stream_write_2_link(g_link_id,1101,0)
			end
			return
		end
		
		-- if 'smail'==cmd then
			-- iup.SetGlobal('UTF8MODE','yes')
			-- local ok,usersn,type2,icon,title,text = iup.GetParam('input system-mail',nil,'to usersn%i\ntype%l|1|2|\nicon%s\ntitle%s\ntext%s\n',1,0,'1','','')
			-- print(ok,usersn,type2,icon,title,text)
			
			-- if true==ok then
				-- lcf.cur_stream_push_string(tostring(usersn),0)
				-- lcf.cur_stream_push_int32(type2)
				-- lcf.cur_stream_push_string(icon,0)
				-- lcf.cur_stream_push_string(title,0)
				-- lcf.cur_stream_push_string(text,0)
				
				-- lcf.cur_stream_write_2_link(g_link_id,1101,0)
			-- end
			
			-- return
		-- end
		
		if 'smail_all_online'==cmd then
			iup.SetGlobal('UTF8MODE','yes')
			local ok,type2,icon,title,text = iup.GetParam('input system-mail',nil,'type%l|1|2|\nicon%s\ntitle%s\ntext%s\n',0,'1','','')
			print(ok,type2,icon,title,text)
			
			if true==ok then
				lcf.cur_stream_push_int32(type2)
				lcf.cur_stream_push_string(icon,0)
				lcf.cur_stream_push_string(title,0)
				lcf.cur_stream_push_string(text,0)
				
				for i=1,50 do
					lcf.cur_stream_write_2_link(g_link_id,1101,i-1)
				end
			end
			
			return
		end
		
	end
	
	
	local btns = {}
	
	local function preprocess_btns()
		for i,v in pairs(o.cmds) do
			table.insert(btns,iup.button{active="yes",title=v[1],action=function() jlpcall(send_cmd,v[2],v[1]) end})
		end
	end
	
	preprocess_btns()
	
	
	o.main_dlg = iup.dialog{title="ControlPanel",size="HALFxHALF",iup.hbox{iup.vbox{unpack(btns)},o.text1}}
	o.main_dlg:showxy (iup.CENTER,iup.CENTER)
end

function o.on_ack(s)
	o.text1.append = s
end

