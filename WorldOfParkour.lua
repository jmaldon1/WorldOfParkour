local activeParkourCourseWaypoints = {}

-- Add standard addon support.
WorldOfParkour = LibStub("AceAddon-3.0"):NewAddon("WorldOfParkour")

function WorldOfParkour:OnInitialize()
    self.activeCourseDefaults = {profile = {activecourse = {}}}

    self.activeParkourCourseDB = LibStub("AceDB-3.0"):New(
                                     "WoPActiveParkourCourseDB",
                                     self.activeCourseDefaults)

    self.activeParkourCourseDB.RegisterCallback(self, "OnProfileChanged",
                                                "ReloadActiveCourse")
    self.activeParkourCourseDB.RegisterCallback(self, "OnProfileCopied",
                                                "ReloadActiveCourse")
    self.activeParkourCourseDB.RegisterCallback(self, "OnProfileReset",
                                                "ReloadActiveCourse")

    -- Change some defaults on TomTom
    TomTom.profile.minimap.default_iconsize = 10
    TomTom.profile.worldmap.default_iconsize = 10
end

function WorldOfParkour:OnEnable()
    -- Reload last active parkour course on load.
    self:ReloadActiveCourse()
    -- This is the place to reload the persisted waypoints
end

-- Wow error handler
seterrorhandler(print);

--[[-------------------------------------------------------------------
--  Dropdown menu code
-------------------------------------------------------------------]] --
local dropdown = CreateFrame("Frame", "TomTomDropdown", nil,
                             "UIDropDownMenuTemplate")

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
end

local Parkour_callbacks_tomtom = {minimap = {onclick = Parkour_minimap_onclick}}

function SetWaypointAtIndexOnCurrentPosition(idx)
    -- Slash commands are passed in empty strings if not specified by user.
    -- Default pos to the length of the waypoints array.
    if idx == "" then idx = #activeParkourCourseWaypoints + 1 end

    -- Check if input is a number
    if not (tonumber(idx)) then
        error("Input to /setpoint must be a number. " .. "'" .. idx .. "'" ..
                  " is not not a number.")
    end

    -- Check if user is trying to set a point that already exists
    local keys = TableKeys(activeParkourCourseWaypoints)
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

    local coursePoint = {uid = uid, hint = "This is a hint"}
    table.insert(activeParkourCourseWaypoints, idx, coursePoint)

    -- Save course state
    WorldOfParkour.activeParkourCourseDB.profile.activecourse =
        activeParkourCourseWaypoints
end

function RemoveWaypoint(uid)
    if type(uid) ~= "table" then
        error("RemoveWaypoint(uid) UID is not a table.");
    end
    local idx = GetWaypointCourseIndex(uid)
    table.remove(activeParkourCourseWaypoints, idx)
    TomTom:RemoveWaypoint(uid)

    -- Save course state
    WorldOfParkour.activeParkourCourseDB.profile.activecourse =
        activeParkourCourseWaypoints

end

function SetWaypointAfterIndexOnCurrentPosition(afterIdx)
    print("FAIL")
    -- print(parkourCourseWaypoints[1].hint)
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

function ResetMemory()
    activeParkourCourseWaypoints = {}
    WorldOfParkour.activeParkourCourseDB:ResetProfile()
    -- WorldOfParkour.activeParkourCourseDB.profile.activecourse = emptyCourse

    TomTom.waydb:ResetProfile()
    TomTom:ReloadWaypoints()
end

function WorldOfParkour:ReloadActiveCourse()
    print("RELOAD")
    -- Recover our last active parkour course.
    activeParkourCourseWaypoints = WorldOfParkour.activeParkourCourseDB.profile
                                       .activecourse

    -- We need to clear the TomTom waypoints because
    -- by default on reload they will override our callbacks
    TomTom.waydb:ResetProfile()

    -- Recreate the TomTom waypoints with our callbacks
    for _, coursePoint in pairs(activeParkourCourseWaypoints) do
        local uid = coursePoint.uid
        local m, x, y = unpack(uid)

        -- Set up default options
        local options = {callbacks = Parkour_callbacks_tomtom}

        -- Recover details from saved waypoints
        for k, v in pairs(uid) do
            if type(k) == "string" then
                if k ~= "callbacks" then
                    -- we can never import callbacks, so ditch them
                    options[k] = v
                end
            end
        end
        TomTom:AddWaypoint(m, x, y, options)

    end
end

--[[-------------------------------------------------------------------
--  Define utility functions
-------------------------------------------------------------------]] --

function GetWaypointCourseIndex(uid) return string.split("_", uid.title)[0] end

function PrintArray(arr)
    print("table: ")
    for i = 1, #arr do print(arr[i]) end
    print("\n")
end

function Dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. Dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
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

function SetContains(set, key) return set[key] ~= nil end

--[[-------------------------------------------------------------------
--  Define Slash commands
-------------------------------------------------------------------]] --
SLASH_SETPOINT1 = "/setpoint"
SlashCmdList["SETPOINT"] = SetWaypointAtIndexOnCurrentPosition

SLASH_SETPOINTAFTER1 = "/setpointafter"
SlashCmdList["SETPOINTAFTER"] = SetWaypointAfterIndexOnCurrentPosition

SLASH_RESET1 = "/reset"
SlashCmdList["RESET"] = ResetMemory
