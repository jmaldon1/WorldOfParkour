local _, addon = ...
addon.utils = {}
local utils = addon.utils

--[[-------------------------------------------------------------------
--  Utility functions
-------------------------------------------------------------------]] --

utils.UUID = function()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

utils.convertValsToTableKeys = function(arr)
    local t = {}
    for k, v in pairs(arr) do t[v] = k end
    return t
end

utils.map = function(tbl, f)
    local t = {}
    for k, v in pairs(tbl) do t[k] = f(v) end
    return t
end

utils.filter = function(tbl, func)
    local newtbl = {}
    for i, v in pairs(tbl) do if func(v) then newtbl[i] = v end end
    return newtbl
end

utils.difference = function(a, b)
    if #b > #a then WorldOfParkour:Error("You must flip the inputs OR ensure that the table lengths are equal.") end
    local aa = {}
    for _, v in pairs(a) do aa[v] = true end
    for _, v in pairs(b) do aa[v] = nil end
    local ret = {}
    local n = 0
    for _, v in pairs(a) do
        if aa[v] then
            n = n + 1
            ret[n] = v
        end
    end
    return ret
end

utils.range = function(low, high)
    local fullRange = {}
    -- Since the keys are numbered, we can find the missing number and make that our ID.
    for var = low, high do table.insert(fullRange, var) end
    return fullRange
end

utils.split = function(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do table.insert(t, str) end
    return t
end

utils.getCoursePointIndex = function(uid) return tonumber(utils.split(uid.title, " ")[2]) end

utils.bind = function(t, k)
    -- Allows me to pass an objects function as a paremeter to another functions
    -- https://stackoverflow.com/questions/20022379/lua-how-to-pass-objects-function-as-parameter-to-another-function
    return function(...) return t[k](t, ...) end
end

utils.printArray = function(arr)
    print("table: ")
    for i = 1, #arr do print(arr[i]) end
    print("\n")
end

utils.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.deepcopy(orig_key)] = utils.deepcopy(orig_value)
        end
        setmetatable(copy, utils.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

utils.tableKeys = function(t)
    local keys = {}
    local n = 0

    for k, _ in pairs(t) do
        n = n + 1
        keys[n] = k
    end
    return keys
end

utils.tableKeysToTable = function(t)
    local keys = {}
    for k, _ in pairs(t) do keys[k] = true end
    return keys
end

utils.tableLength = function(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

utils.startsWith = function(str, start) return string.sub(str, 1, string.len(start)) == start end

utils.setContains = function(set, key) return set[key] ~= nil end

utils.replaceTable = function(fromTable, toTable)
    -- erase all old keys
    for k, _ in pairs(toTable) do toTable[k] = nil end

    -- copy the new ones over
    for k, v in pairs(fromTable) do toTable[k] = v end
end
