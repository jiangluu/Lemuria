
function onEvent(me)
	local key,v,v2 = getUEParams()
	if nil==key or nil==v then
		error('invalid param')
	end
	
	if isServ() then
		if nil==me.cache.pvp_copy then
			return 1
		end
	
		if nil==me.inbattle then
			me.inbattle = { score=6 , record='' }
		end
		local bb = me.inbattle
		
		local now = l_cur_game_time()
		
		-- Ŀǰֻ����1,2
		if 2==key then
			if nil~=tonumber(v) then
				local he = me.cache.pvp_copy
				
				if tonumber(v)<1 or tonumber(v)>#he.map.list then
					bb.score = bb.score - 2
					error('move to invalid block index')
				end
				
				-- �򵥵ļ�⣬����һ���ؿ�����N�룬�����ǻص���һ���ؿ飨��Ϊ�������ڱ߽����ߣ�
				local N = 1
				if nil~=bb.time_at and now-bb.time_at<=N and tonumber(v)~=bb.prev_at then
					bb.score = bb.score - 1
					error('move to fast')
				end
			
				bb.prev_at = bb.at	-- ��һ���ڵĵؿ�
				bb.at = tonumber(v)
				bb.time_at = now
				
				return 0
			end
		elseif 1==key then
			--local block_index,mob_index = string.match(tostring(v),'(%d+),(%d+)')
			local block_index,mob_index = v,v2
			if block_index and mob_index then
				if tonumber(block_index)~=bb.at then
					bb.score = bb.score - 2
					--error('try kill across block')
				end
				
				local ss = string.format('%d,%d',v,v2)
				
				if nil==bb.kills then
					bb.kills = {}
				end
				
				for jj=1,#bb.kills do
					if ss==bb.kills[jj] then
						bb.score = bb.score - 2
						error('try kill deadbody')
					end
				end
				
				table.insert(bb.kills,ss)
				
				return 0
			end
			
		elseif 100==key then
			-- ��¼��
			bb.record = bb.record .. v
		end
		
		
		return 1
		
	end
	
	return 0
end