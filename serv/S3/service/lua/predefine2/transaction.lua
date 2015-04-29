
-- 事务。一个事务是一个不能被打断的过程，并且他的中间状态不应该被看到。
-- BOX里的事务跟Actor关系紧密。一个Actor同时只能有一个事务。想开始新的事务，必须等待上一个事务结束。所以事务可以作为Actor的一个属性存在。
-- Actor每有一个请求，都会有一个事务来处理它。
-- BOX里的事务是简单的，不支持回滚功能。只强调不能被打断。




local o = {}

transaction = o

local err_transaction_hung_up = -10010		-- 事务挂起时的返回值
local err_transaction_lua_error = -10012	-- 事务发生程序错误时的返回值


function o.new(actor,f)
	actor.co = coroutine.create(f)
end

function o.wakeup(actor,...)
	actor.transaction = 8
	local err,ret = coroutine.resume(actor.co,actor,...)
	actor.transaction = 1
	
	if false==err then
		print(ret)
		actor.co = nil
		actor.transaction = nil
		
		return err_transaction_lua_error
	else
		if 'dead'==coroutine.status(actor.co) then
			actor.co = nil
			actor.transaction = nil
			
			if ret == err_transaction_hung_up then
				-- 不允许用户在事务结束时返回这个值
				ret = 1
			end
		end
		
		return ret
	end
end

function o.wait()
	return coroutine.yield(err_transaction_hung_up)
end

function o.is_in_transaction(actor)
	return nil~=actor.transaction
end


function o.force_abort_transaction(actor)
	actor.co = nil
	actor.transaction = nil
end

