
local o = {}

ctb_strategy = o


function o.get(i)
	-- 最简单但是稳定可靠的策略，无状态，平均hash
	return (i % boxraid.box_num) + 1
end

function o.check_detach(i,msg_id)
	-- Nothing to do
end
