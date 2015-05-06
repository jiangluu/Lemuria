
local lcf = ffi.C

local o = {}

ui = o

o.cmds = {{'reload handles','reload handles'},
	{'reload all','reload all'},
	{'onlinenum','onlinenum'},
	{'league start','league start'},
	{'league end','league end'},
	{'broadcast','broadcast'},
	{'smail','smail'},
	{'smail_all_online','smail_all_online'},
	{'save all','save all'},
}


function o.post_init()
	o.text1 = iup.multiline{READONLY='yes',VISIBLELINES=40,VISIBLECOLUMNS=80}
	
	local function send_cmd(cmd)
		lcf.cur_write_stream_cleanup()
		lcf.cur_stream_push_int32(-1)
		lcf.cur_stream_push_string(cmd,0)
		
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
		
		if 'smail'==cmd then
			iup.SetGlobal('UTF8MODE','yes')
			local ok,usersn,type2,icon,title,text = iup.GetParam('input system-mail',nil,'to usersn%i\ntype%l|1|2|\nicon%s\ntitle%s\ntext%s\n',1,0,'1','','')
			print(ok,usersn,type2,icon,title,text)
			
			if true==ok then
				lcf.cur_stream_push_string(tostring(usersn),0)
				lcf.cur_stream_push_int32(type2)
				lcf.cur_stream_push_string(icon,0)
				lcf.cur_stream_push_string(title,0)
				lcf.cur_stream_push_string(text,0)
				
				lcf.cur_stream_write_2_link(g_link_id,1101,0)
			end
			
			return
		end
		
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
		
		if string.match(cmd,'league') then
			lcf.cur_stream_write_2_link(g_link_id,1101,0)
			return
		end
		
		for i=1,50 do
			lcf.cur_stream_write_2_link(g_link_id,1101,i-1)
		end
	end
	
	
	local btns = {}
	
	local function preprocess_btns()
		for i,v in pairs(o.cmds) do
			table.insert(btns,iup.button{active="yes",title=v[1],action=function() send_cmd(v[2]) end})
		end
		
		table.insert(btns,iup.button{active="yes",title='re-configs',action=function()
			lcf.cur_write_stream_cleanup()
			lcf.cur_stream_push_int32(-1)
			lcf.cur_stream_write_2_link(g_link_id,1103,0)
		end})
	end
	
	preprocess_btns()
	
	
	o.main_dlg = iup.dialog{title="ControlPanel",size="HALFxHALF",iup.hbox{iup.vbox{unpack(btns)},o.text1}}
	o.main_dlg:showxy (iup.CENTER,iup.CENTER)
end

function o.on_ack(box_id,cmd,ack)
	o.text1.append = string.format('BOX:[%d]  CMD:[%s]  ACK:[%s]',box_id,cmd,ack)
end

