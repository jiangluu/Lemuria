
function onEvent(me)
	
	--减去钻石 设置时间
	util.dec(me,'diamond',me.basic.diamond,'test')
	
	util.fillCacheData(me)
	
	
	return 0
end
