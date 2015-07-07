
local ap = require('atabletopointer')


local function travel_table(t)
	for k,v in pairs(t) do
		if 'table'==type(v) then
			travel_table(v)
		else
			print(k,'==>',v)
		end
	end
end

-- test
if 0==g_box_id then
	local sub1 = { 1,2,3,4 }
	a = { true, false, nil,2,3, a= sub1, b= "hello" }

	assert(ap.topointer(1,a))
	
else
	local t = ap.restoretable(1)
	print('restore',t)
	travel_table(t)
end
