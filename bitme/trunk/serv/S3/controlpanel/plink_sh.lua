
print("AAAAAAAAAAAAAAAAA")

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


local function foo()
	for i=1,8 do
	-- ./service S%d -d
		--local cmd = string.format('killall -9 service;cd aaa;svn update;cd b;chmod 755 service;./service S%d -d',i)
		local cmd = string.format('killall -9 gate;cd aaa;svn update;cd c;chmod 755 gate;./gate G%d -d',i)
		
		local ip = nnp[i]
		local aa = string.format('plink.exe jl@%s -v -pw Nana9151 %s',ip,cmd)
		os.execute(aa)
		
	end
end

foo()
