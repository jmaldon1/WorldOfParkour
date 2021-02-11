-- luacheck: globals TomTom

local parkourCourseWaypoints = {}

local addonName, addon = ...
local Parkour = addon

addon.CLASSIC = math.floor(select(4, GetBuildInfo() ) / 100) == 113

function Parkour:Initialize(event, addon)
end

function Parkour:Enable(addon)
    -- This is the place to reload the persisted waypoints
    print("enable")
    -- self:ReloadWaypoints()
end

local dropdown = CreateFrame("Frame", "TomTomDropdown", nil,
                             "UIDropDownMenuTemplate")

-- local callbacks = TomTom:DefaultCallbacks()

--[[-------------------------------------------------------------------
--  Dropdown menu code
-------------------------------------------------------------------]] --

local dropdown_info = {
    -- Define level one elements here
    [1] = {
        { -- Title
            text = "Waypoint Options",
            isTitle = 1
        }, {
            -- set as crazy arrow
            text = "Set as waypoint arrow",
            func = function()
                local uid = dropdown.uid
                local data = uid
                TomTom:SetCrazyArrow(uid, TomTom.profile.arrow.arrival,
                                     data.title or "TomTom waypoint")
            end
        }, { -- Remove waypoint
            text = "Remove waypoint",
            func = function()
                local uid = dropdown.uid
                local data = uid
                RemoveWaypoint(uid)
                -- TomTom:RemoveWaypoint(uid)

                -- TomTom:Printf("Removing waypoint %0.2f, %0.2f in %s", data.x, data.y, data.zone)
            end
        }
    }
}

local function init_dropdown(level)
    -- Make sure level is set to 1, if not supplied
    level = 1

    -- Get the current level from the info table
    local info = dropdown_info[level]

    -- If a value has been set, try to find it at the current level
    if level > 1 and UIDROPDOWNMENU_MENU_VALUE then
        if info[UIDROPDOWNMENU_MENU_VALUE] then
            info = info[UIDROPDOWNMENU_MENU_VALUE]
        end
    end

    -- Add the buttons to the menu
    for idx, entry in ipairs(info) do
        if type(entry.checkeda) == "function" then
            -- Make this button dynamic
            local new = {}
            for k, v in pairs(entry) do new[k] = v end
            new.checked = new.checked()
            entry = new
        else
            entry.checked = nil
        end

        UIDropDownMenu_AddButton(entry, level)
    end
end

function InitializeDropdown(uid)
    print("INIT")
    dropdown.uid = uid
    UIDropDownMenu_Initialize(dropdown, init_dropdown)
end

function Parkour_minimap_onclick(event, uid, self, button)
    print("CLICK")
    InitializeDropdown(uid)
    _G.ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
    print(event)
    print(uid)
    print(self)
    print(button)
end

local Parkour_callbacks_tomtom = {minimap = {onclick = Parkour_minimap_onclick}}

function SetWaypointAtIndexOnCurrentPosition(idx)
    -- Slash commands are passed in empty strings if not specified by user.
    -- Default pos to the length of the waypoints array.
    if idx == "" then idx = #parkourCourseWaypoints + 1 end

    -- Check if input is a number
    if not(tonumber(idx)) then
        error("Input to /setpoint must be a number. " .. "'" .. idx .. "'" .. " is not not a number.")
    end

    -- Check if user is trying to set a point that already exists
    local keys = TableKeys(parkourCourseWaypoints)
    local err_msg = "That point is already set, remove it first and try again."
    if SetContains(keys, tonumber(idx)) then error(err_msg); end

    -- Create the waypoint
    local mapID, x, y = TomTom:GetCurrentPlayerPosition()
    local opts = {
        title = "point_" .. idx,
        from = "Parkour Addon",
        callbacks = Parkour_callbacks_tomtom
        -- cleardistance =
        -- arrivaldistance =
    }
    local uid = TomTom:AddWaypoint(mapID, x, y, opts)

    table.insert(parkourCourseWaypoints, idx, uid)
end

function SetWaypointAfterIndexOnCurrentPosition(afterIdx)
    print("FAIL")
    -- -- This function with reorder the waypoints array
    -- if afterIdx == "" then return end

    -- -- Check if input is a number
    -- if not(tonumber(afterIdx)) then
    --     error("Input to /setpointafter must be a number. " .. "'" .. afterIdx .. "'" .. " is not not a number.")
    -- end
    -- local newParkourCourseWaypoints = {}
    -- local n = 0
    -- -- parkourCourseWaypoints[1].title = "BIG TEST"
    -- for idx, uid in ipairs(parkourCourseWaypoints) do
    --     n = n + 1
    --     local newUid = uid
    --     newUid.title = "point_" .. n,
    --     if idx == afterIdx then
    --         n = n + 1
    --         newParkourCourseWaypoints[n]
    --     end
    -- end
end

function RemoveWaypoint(uid)
    if type(uid) ~= "table" then error("RemoveWaypoint(uid) UID is not a table."); end
    local idx = Split(uid.title, "_")[0]
    table.remove(parkourCourseWaypoints, idx)
    TomTom:RemoveWaypoint(uid)
end

-- Wow error handler
seterrorhandler(print);


--[[-------------------------------------------------------------------
--  Define utility functions
-------------------------------------------------------------------]]--

function PrintArray(arr)
    print("table: ")
    for i = 1, #arr do print(arr[i]) end
    print("\n")
end

function TableKeys(t)
    local keys = {}
    local n = 0

    for k, v in pairs(t) do
        n = n + 1
        keys[n] = k
    end
    return keys
end

function Split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function SetContains(set, key) return set[key] ~= nil end


--[[-------------------------------------------------------------------
--  Define Slash commands
-------------------------------------------------------------------]]--
SLASH_SETPOINT1 = "/setpoint"
SlashCmdList["SETPOINT"] = SetWaypointAtIndexOnCurrentPosition

SLASH_SETPOINTAFTER1 = "/setpointafter"
SlashCmdList["SETPOINTAFTER"] = SetWaypointAfterIndexOnCurrentPosition
