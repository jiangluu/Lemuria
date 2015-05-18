
local o = {}

ssh = o

local cmd = 'ls -l'


function o.update_all_file(remote_addr)
	local ip = string.match(remote_addr,'([^:]+)')
	print(ip)
	
	local aa = string.format('plink.exe jl@%s -pw Nana9151 %s',ip,cmd)
	os.execute(aa)
end
