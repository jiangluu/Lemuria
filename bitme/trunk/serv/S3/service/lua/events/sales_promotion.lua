
local aa = {
	'shouchong',
	'newbee_7sign',
	'sign25'
}

function onEvent(me)	
	if isServ() then		
		local salesList={ list=aa }			
		daily.push_data_to_c('cache.sales',box.serialize(salesList))		
	end
	return 0		
end
