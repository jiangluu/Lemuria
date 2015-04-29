
function onEvent(me)
	local bossType,skillOne,skillTwo,skillThree = getUEParams()
	if nil == bossType then
		error('invalid input param')
	end
	
		--判断boss是否存在
	local isHave = false
	
	util.travalPlayerLobby(me,function(lobby)
		if bossType == lobby.type then
			isHave = true
			
			return true
		end
	end)

	if false == isHave then
		return 1
	end
	
		--装备技能
	util.travalPlayerLobby(me,function(lobby)
		if bossType == lobby.type then
			lobby.skill = {}
			lobby.skill.list = newArray()
			table_insert(lobby.skill.list,{type = skillOne})
			table_insert(lobby.skill.list,{type = skillTwo})
			table_insert(lobby.skill.list,{type = skillThree})
			
			return true
		end
	end)
	
		--刷新数据
	util.fillCacheData(me)
	
	return 0
end