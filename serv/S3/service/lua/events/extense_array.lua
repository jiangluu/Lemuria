function onEvent(me)
	local key = getUEParams()
	
	if nil == key then
		error('invalid input param')
	end
	
	if nil == me.var.jin[key] then
		return 1
	end
	
	util.use_update_array(me)
		--ȡ����һ������ʱ���Լ����ܴ�������
	local ai = 0	--���ܹܼҿ�����������
	local onceTime = sd.jin[key]['charge_time']
	local limit = sd.jin[key]['count'] + ai
	
		--�ж��Ƿ�ﵽ�����Լ���ʯ�Ƿ���
	if me.var.jin[key].count >= limit then
		return 1
	end
	
	local leftTime = onceTime - (l_cur_game_time() - me.var.jin[key].starttime)
	local needNum = util.getDiamondExchangeTime(leftTime)
	
	if needNum < 0 then
		error('time error')
	end
	
	if needNum > me.basic.diamond then
		return 1
	end
	
		--���������㣬����ʯ���Ӳ���������ʱ��
	util.dec(me,'diamond',needNum,'jin')
	me.var.jin[key].count = me.var.jin[key].count + 1
	me.var.jin[key].starttime = l_cur_game_time()
	
		--ˢ������
	util.fillCacheData(me)
	
	return 0
	
end