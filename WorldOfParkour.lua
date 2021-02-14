-- Add standard addon support.
WorldOfParkour = LibStub("AceAddon-3.0"):NewAddon("WorldOfParkour", "AceConsole-3.0")

function WorldOfParkour:OnInitialize()
    self.activeCourseDefaults = {profile = {activecourse = {}}}
    self.savedcoursesDefaults = {global = {savedcourses = {}}}

    self.activeCourseDB = LibStub("AceDB-3.0"):New("WoPActiveParkourCourseDB",
                                                   self.activeCourseDefaults)
    self.savedCoursesDB = LibStub("AceDB-3.0"):New("WoPSavedParkourCoursesDB",
                                                   self.savedcoursesDefaults)

    self.activeCourseDB.RegisterCallback(self, "OnProfileChanged",
                                         "ReloadActiveCourse")
    self.activeCourseDB.RegisterCallback(self, "OnProfileCopied",
                                         "ReloadActiveCourse")
    self.activeCourseDB.RegisterCallback(self, "OnProfileReset",
                                         "ReloadActiveCourse")

    self.activeCourseStore = self.activeCourseDB.profile
    self.savedCoursesStore = self.savedCoursesDB.global

    -- self.courseCreationMode = true
end

function WorldOfParkour:OnEnable()
    -- Blizzard Addon interface menu.
    self:CreateConfig()

    -- Reload last active parkour course on load.
    self:ReloadActiveCourse()
end

-- Wow error handler
seterrorhandler(print);

local function WoPMessage(msg)
    -- Create string with addon name appended.
    return string.format("|cff33ff99WorldOfParkour|r: %s", msg)
end

--[[-------------------------------------------------------------------
--  Dropdown menu code
-------------------------------------------------------------------]] --
local dropdown = CreateFrame("Frame", "TomTomDropdown", nil,
                             "UIDropDownMenuTemplate")

local dropdown_info = {
    -- Define level one elements here
    [1] = {
        { -- Title
            text = "WorldOfParkour Point Options",
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
                WorldOfParkour:RemoveWaypoint(uid)

                -- TomTom:Printf("Removing waypoint %0.2f, %0.2f in %s", data.x, data.y, data.zone)
            end
        }, { -- Show hint
        text = "Show hint",
        func = function()
            local uid = dropdown.uid
            local idx = GetCourseIndex(uid)
            local coursePoint = WorldOfParkour.activeCourseStore.activecourse[idx]
            WorldOfParkour:Printf("Hint for point %s: %s", idx, coursePoint.hint)
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
    dropdown.uid = uid
    UIDropDownMenu_Initialize(dropdown, init_dropdown)
end

function Parkour_minimap_onclick(event, uid, self, button)
    InitializeDropdown(uid)
    _G.ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

local defaultCallbacks = TomTom:DefaultCallbacks()

local Parkour_callbacks_tomtom = {
    minimap = {
        onclick = Parkour_minimap_onclick,
        tooltip_show = defaultCallbacks.minimap.tooltip_show,
        tooltip_update = defaultCallbacks.minimap.tooltip_update
    },
    world = {
        onclick = Parkour_minimap_onclick,
        tooltip_show = defaultCallbacks.world.tooltip_show,
        tooltip_update = defaultCallbacks.world.tooltip_update
    }
}

--[[-------------------------------------------------------------------
--  WorldOfParkour
-------------------------------------------------------------------]] --

function WorldOfParkour:SyncWithTomTomDB()
    local newActiveCourse = {}
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse) do
        if TomTom:IsValidWaypoint(coursePoint.uid) then
            -- We are not synced with TomTom's waypoint DB.
            -- Make a new course that matches TomTom.
            table.insert(newActiveCourse, coursePoint)
        end
    end
    self.activeCourseStore.activecourse = newActiveCourse
    -- Sanity check to make sure we are now synced.
    assert(self:IsSyncedWithTomTomDB(), WoPMessage("We aren't synced? Report this bug."))
    -- Reorder the course to deal with the missing values.
    self:ReorderCourseWaypoints()
end

function WorldOfParkour:IsSyncedWithTomTomDB()
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse) do
        if not TomTom:IsValidWaypoint(coursePoint.uid) then
            -- We are not synced with TomTom's waypoint DB
            return false
        end
    end
    return true
end

function WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(idx)
    -- if not self.courseCreationMode then error("You must be in course creation mode to create a point.") end

    local nextAvailablePointIdxBeforeSync =
        #self.activeCourseStore.activecourse + 1
    if not self:IsSyncedWithTomTomDB() then
        self:SyncWithTomTomDB()
        -- After syncing we need to deal with the new waypoint the user wants added...
        if idx == nextAvailablePointIdxBeforeSync then
            -- If we know the user was trying to add
            -- a point onto the end, we can do that for them.
            idx = #self.activeCourseStore.activecourse + 1
        end
    end

    local nextAvailablePointIdxAfterSync =
        #self.activeCourseStore.activecourse + 1

    if type(idx) ~= "number" then
        error("SetWaypointAtIndexOnCurrentPosition(idx) idx is not a number.");
    end

    if idx <= 0 or idx > nextAvailablePointIdxAfterSync then
        error("Point index out of range. " ..
                  "The next point you can create is " .. "'" ..
                  nextAvailablePointIdxAfterSync .. "'.");
    end

    -- Create the waypoint
    local mapID, x, y, opts = unpack(self:CreateWaypointDetails(idx))
    local uid = TomTom:AddWaypoint(mapID, x, y, opts)

    -- Save to course state
    local coursePoint = {uid = uid, hint = "This is idx" .. idx}
    table.insert(self.activeCourseStore.activecourse, idx, coursePoint)

    -- Reorder course if needed.
    if idx ~= #self.activeCourseStore.activecourse then
        -- Reorder if the user inserted a point anywhere but the end of the course.
        self:ReorderCourseWaypoints()
    end
end

function WorldOfParkour:RemoveWaypoint(uid)
    -- if not self.courseCreationMode then error("You must be in course creation mode to remove a point.") end

    if type(uid) ~= "table" then
        error("RemoveWaypoint(uid) UID is not a table.");
    end
    local idx = GetCourseIndex(uid)
    table.remove(self.activeCourseStore.activecourse, idx)
    TomTom:RemoveWaypoint(uid)

    -- Do not reorder if user removed last point.
    if idx - 1 ~= #self.activeCourseStore.activecourse then
        self:ReorderCourseWaypoints()
    end

    if not self:IsSyncedWithTomTomDB() then
        self:SyncWithTomTomDB()
    end
end

function WorldOfParkour:ReorderCourseWaypoints()
    self:RemoveAllTomTomWaypoints()

    local updatedActiveCourseStore = {}

    for idx, coursePoint in ipairs(self.activeCourseStore.activecourse) do
        local uid = coursePoint.uid
        local oldIdx = GetCourseIndex(uid)
        if idx ~= oldIdx then
            -- Rename the waypoint
            uid.title = "Point " .. idx
        end
        table.insert(updatedActiveCourseStore, coursePoint)
    end

    self.activeCourseStore.activecourse = updatedActiveCourseStore

    self:ReloadActiveCourse()
end

function WorldOfParkour:CreateWaypointDetails(idx)
    local mapID, x, y = TomTom:GetCurrentPlayerPosition()
    local opts = {
        title = "Point " .. idx,
        from = "World of Parkour",
        -- We will handle the persistence on our end.
        persistent = false,
        callbacks = Parkour_callbacks_tomtom,
        minimap_icon_size = 10,
        worldmap_icon_size = 10
        -- cleardistance = 2
        -- arrivaldistance =
    }
    return {mapID, x, y, opts}
end

function WorldOfParkour:ReloadActiveCourse()
    -- local mapID, x, y = TomTom:GetCurrentPlayerPosition()
    -- local mapID, x, y, opts = unpack(self:CreateWaypointDetails(1))
    -- WorldOfParkour:Print(mapID, x, y)
    -- print(mapID)
    -- print(x)
    -- print(y)
    -- TomTom:AddWaypoint(mapID, x, y, opts)
    -- Recover our last active parkour course.
    -- We need to recreate our active course store
    -- because the recovered uid's are now invalid.
    local updatedActiveCourseStore = {}

    WorldOfParkour:Printf("num points: %s", #self.activeCourseStore.activecourse)

    -- Recreate the TomTom waypoints with our callbacks
    for _, coursePoint in pairs(self.activeCourseStore.activecourse) do
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

        -- WorldOfParkour:Printf("%s, %s, %s", m, x, y)
        local updatedUid = TomTom:AddWaypoint(m, x, y, options)
        local updatedCoursePoint = {uid = updatedUid}

        -- Move details from old coursePoint to new coursePoint
        for k, v in pairs(coursePoint) do
            if k ~= "uid" then
                -- We don't want the old Uid.
                updatedCoursePoint[k] = v
            end
        end

        table.insert(updatedActiveCourseStore, updatedCoursePoint)
    end

    self.activeCourseStore.activecourse = updatedActiveCourseStore
end

function WorldOfParkour:FinishedCourseCreation(title, description)
    -- TODO: Not done...
    if #self.activeCourseStore.activecourse == 0 then
        error("You need to add points to this course first.")
    end

    local savedCourse = {
        title = title,
        description = description,
        id = "someuid",
        course = self.activeCourseStore.activecourse
    }
end

function WorldOfParkour:RemoveAllTomTomWaypoints()
    -- NOTE: This will ONLY remove WorldOfParkour TomTom waypoints.
    for _, coursePoint in pairs(self.activeCourseStore.activecourse) do
        local uid = coursePoint.uid
        TomTom:RemoveWaypoint(uid)
    end
end

function WorldOfParkour:ResetMemory()
    self:RemoveAllTomTomWaypoints()
    self.activeCourseStore.activecourse = {}
    self.activeCourseDB:ResetProfile()
end

function WorldOfParkour:ClearSavedCourses()
    self.savedCoursesStore.savedcourses = {}
end

--[[-------------------------------------------------------------------
--  Define utility functions
-------------------------------------------------------------------]] --

function GetCourseIndex(uid) return tonumber(Split(uid.title, " ")[2]) end

function Split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function PrintArray(arr)
    print("table: ")
    for i = 1, #arr do print(arr[i]) end
    print("\n")
end

function Deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Deepcopy(orig_key)] = Deepcopy(orig_value)
        end
        setmetatable(copy, Deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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
SlashCmdList["SETPOINT"] = function(idx)
    -- Slash commands are passed in empty strings if not specified by user.
    -- Default idx to the length of the waypoints array.
    if idx == "" then
        idx = #WorldOfParkour.activeCourseStore.activecourse + 1
    end

    -- Check if input is a number
    if not (tonumber(idx)) then
        error("Input to /setpoint must be a number. " .. "'" .. idx .. "'" ..
                  " is not a number.")
    end

    -- Check if user is trying to set a point that already exists
    local keys = TableKeys(WorldOfParkour.activeCourseStore.activecourse)
    local err_msg = "That point is already set, remove it first and try again."
    if SetContains(keys, tonumber(idx)) then error(err_msg); end

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(tonumber(idx))
end

SLASH_SETPOINTAFTER1 = "/setpointafter"
SlashCmdList["SETPOINTAFTER"] = function(afterIdx)
    if afterIdx == "" then return end

    -- Check if input is a number
    if not tonumber(afterIdx) then
        error("Input to /setpointafter must be a number. " .. "'" .. afterIdx ..
                  "'" .. " is not a number.")
    end

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(tonumber(afterIdx) + 1)
end
-- WorldOfParkour.SetWaypointAfterIndexOnCurrentPosition

SLASH_RESET1 = "/reset"
SlashCmdList["RESET"] = function() WorldOfParkour:ResetMemory() end
SLASH_RESETC1 = "/resetc"
SlashCmdList["RESETC"] = function() WorldOfParkour:ClearSavedCourses() end
