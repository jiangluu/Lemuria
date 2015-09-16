
function getMaxConn()
	return 8
end

function getReadBufLen()
	return 1024*1024*8
end

function getWriteBufLen()
	return 1024*1024*8
end



local o = {}

config = o

function o.get_box_num()
	return 50
end

function o.get_actor_per_box()
	return 200
end
