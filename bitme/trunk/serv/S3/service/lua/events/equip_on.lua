
function onEvent(me)

  local index,slot,heroIndex = getUEParams()  -- UE Param means User Event Param
	-- local index,heroIndex = getUEParams()  -- UE Param means User Event Param
	
    if nil==index or nil==slot or nil==heroIndex then
        error('invalid input param')
    end

    local valid_slot = {'weapon','armor','glove','ring1','ring2'}

    local found = false
    for __,v in pairs(valid_slot) do
        if slot==v then
            found = true
            break
        end
    end

    if not found then
        error('invalid param slot')
    end

    local cur_hero
    if heroIndex > #me.hero.list then
        error('hero index out of range')
    else
        cur_hero = me.hero.list[heroIndex]
    end

    --for i,v in pairs(me.hero.list) do
    --  if v.inuse then
    --      cur_hero = v
    --      break
    --  end
    --end
	
    if nil==cur_hero then
        error('no current hero')
    end

    if index<=0 or index > #cur_hero.equip.list then
        error('invalid index')
    end


    -- 先把以前的装备卸下（如果有装备的话）	
	for i=1,#cur_hero.equip.list do
		cur_hero.equip.list[i][slot] = nil
	end

    -- 再装备上要求的装备
    cur_hero.equip.list[index][slot] = true


    -- output part
    return 0
end

