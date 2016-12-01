
function getMaxConn()
	return 2048
end

function getReadBufLen()
	return 1024*8
end

function getWriteBufLen()
	return 1024*16
end



local o = {}

config = o

function o.get_box_num()
	return 5
end

function o.get_actor_per_box()
	return 2000
end
