
local o = {}

ssh = o

local cmd = 'ls -l'


local nn = {
	'192.168.133.56',
	'192.168.178.205',
	'192.168.131.15',
	'192.168.134.241',
	'192.168.158.98',
	'192.168.143.77',
	'192.168.210.153',
	'192.168.216.170',
}

local nnp = {
	'192.81.134.110',
	'50.116.0.116',
	'192.155.83.15',
	'173.230.152.157',
	'192.81.131.150',
	'45.79.106.87',
	'45.79.93.84',
	'45.33.62.134',
}


function o.update_all_file(remote_addr)
	-- local ip = string.match(remote_addr,'([^:]+)')
	-- print(ip)
	local nbegin = 4
	
	for i=2,#nnp do
		local ip = nnp[i]
		
		-- local cmd = 'cd aaa;svn update;cd ssdb;chmod 755 ssdb-server;./ssdb-server -d '
		-- cmd = cmd..string.format('ssdb_%d.conf',i)
		
		--local cmd = 'cd aaa;svn update;cd ssdb;chmod 755 ssdb-server;./ssdb-server -d ssdb_98.conf'
		
		--local cmd = string.format('killall -9 gate;killall -9 service;cd aaa;svn update;cd b;chmod 755 service;nohup ./service S%d',i)
		local cmd = string.format('killall -9 gate;cd aaa;svn update;cd c;chmod 755 gate;nohup ./gate G%d',i)
		
		local aa = string.format('plink.exe jl@%s -pw Nana9151 %s',ip,cmd)
		os.execute(aa)
		
		break
		
	end
	
end
