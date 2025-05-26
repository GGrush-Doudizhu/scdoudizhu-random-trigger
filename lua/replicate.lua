function concatTables(t1, t2)
    local result = {}
    
    -- Insert all elements from the first table
    for i = 1, #t1 do
        table.insert(result, t1[i])
    end
    
    -- Insert all elements from the second table
    for i = 1, #t2 do
        table.insert(result, t2[i])
    end
    
    return result
end

function replicateTable(inputTable, N)
    local result = {}
    
    -- Iterate N times to replicate the elements
    for i = 1, N do
        for j = 1, #inputTable do
            table.insert(result, inputTable[j])
        end
    end
    
    return result
end

function segmentTable(inputTable, n)
    local result = {}
    local temp = {}

    -- Iterate through the input table
    for i = 1, #inputTable do
        -- Insert elements into temp sub-table
        table.insert(temp, inputTable[i])

        -- Once the temp table reaches the desired length `n`, insert it into result
        if #temp == n then
            table.insert(result, temp)
            temp = {} -- Reset temp for the next segment
        end
    end

    -- Insert any remaining elements (if temp isn't empty)
    if #temp > 0 then
        table.insert(result, temp)
    end

    return result
end

-- 把一组actions重复N次，返回一个table of actions，每个元素都是一个长度小于等于maxActionPerTrigger的table
function GenerateActionGroups(totalNumber, actionUnit, maxActionPerTrigger)
    return segmentTable(replicateTable(actionUnit, totalNumber), maxActionPerTrigger)
end

--[[
使用例:
acts = GenerateActionGroups(
    24,
    {
        MoveLocation("loc", "Terran Medic", P12, "Anywhere");
        RemoveUnitAt(1, "Terran Medic", "loc", P12),
        CreateUnit(1, "Vespene Geyser", "loc", P1)
    },
    63
)

for i, a in ipairs(acts) do
    Trigger {
        players = {P1},
        actions = a
    }
end


]]