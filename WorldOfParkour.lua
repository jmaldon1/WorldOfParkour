-- Add standard addon support.
AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
WorldOfParkour = LibStub("AceAddon-3.0"):NewAddon("WorldOfParkour",
                                                  "AceConsole-3.0",
                                                  "AceTimer-3.0")

function WorldOfParkour:OnInitialize()
    self.activeCourseDefaults = {
        profile = {
            isInEditMode = false,
            isActiveCourse = false,
            activecourse = {
                -- course = {}
            },
            backupActivecourse = {}
        }
    }
    self.savedcoursesDefaults = {global = {savedcourses = {}}}

    self.activeCourseDB = LibStub("AceDB-3.0"):New("WoPActiveParkourCourseDB",
                                                   self.activeCourseDefaults)
    self.savedCoursesDB = LibStub("AceDB-3.0"):New("WoPSavedParkourCoursesDB",
                                                   self.savedcoursesDefaults)

    -- self.activeCourseDB.RegisterCallback(self, "OnProfileChanged",
    --                                      "ReloadActiveCourse")
    -- self.activeCourseDB.RegisterCallback(self, "OnProfileCopied",
    --                                      "ReloadActiveCourse")
    -- self.activeCourseDB.RegisterCallback(self, "OnProfileReset",
    --                                      "ReloadActiveCourse")

    self.activeCourseStore = self.activeCourseDB.profile
    self.savedCoursesStore = self.savedCoursesDB.global

    self.GUIoptionsDefaults = {profile = {options = self:GenerateOptions()}}
    self.GUIoptionsDB = LibStub("AceDB-3.0"):New("WoPGUIDB",
                                                 self.GUIoptionsDefaults)
    self.GUIoptionsStore = self.GUIoptionsDB.profile

    self.courseSearch = ""

    self:CreateGUI()
end

function WorldOfParkour:OnEnable()
    -- Blizzard Addon interface menu.
    self:CreateConfig()

    -- Reload last active parkour course on load.
    if self:isActiveCourse() then self:ReloadActiveCourse() end
end

-- Wow error handler
seterrorhandler(print);

local function WoPMessage(msg)
    -- Create string with addon name appended.
    return string.format("|cff33ff99WorldOfParkour|r: %s", msg)
end

--[[-------------------------------------------------------------------
--  WorldOfParkour
-------------------------------------------------------------------]] --
function NotInActiveModeError()
    error("You must have an Active Course to perform this action.")
end

function NotInEditModeError()
    error("You must be in edit mode to perform this action.")
end

function WorldOfParkour:isActiveCourse()
    return self.activeCourseStore.isActiveCourse
end

function WorldOfParkour:isNotActiveCourse() return not self:isActiveCourse() end

function WorldOfParkour:isInEditMode() return
    self.activeCourseStore.isInEditMode end

function WorldOfParkour:isNotInEditMode() return not self:isInEditMode() end

function WorldOfParkour:SyncWithTomTomDB()
    -- This will remove any points that exist in our store but not TomTom's,
    -- thus syncing us with TomTom.
    if self:isNotActiveCourse() then NotInActiveModeError() end

    local newActiveCourse = {}
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        if TomTom:IsValidWaypoint(coursePoint.uid) then
            -- We are not synced with TomTom's waypoint DB.
            -- Make a new course that matches TomTom.
            table.insert(newActiveCourse, coursePoint)
        end
    end
    self.activeCourseStore.activecourse.course = newActiveCourse
    -- Sanity check to make sure we are now synced.
    if #self.activeCourseStore.activecourse.course ~= 0 then
        assert(self:IsSyncedWithTomTomDB(),
               WoPMessage("We aren't synced? Report this bug."))
    end
    -- Reorder the course to deal with the missing values.
    self:ReorderCourseWaypoints()
end

function WorldOfParkour:IsSyncedWithTomTomDB()
    if self:isNotActiveCourse() then NotInActiveModeError() end

    if #self.activeCourseStore.activecourse.course == 0 then
        -- If there are 0 points in the our course, it is not possible to determine
        -- if we are synced with TomTom's DB or not. So we throw.
        error("Unable to determine if we are synced with TomTomDB...")
    end
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        if not TomTom:IsValidWaypoint(coursePoint.uid) then
            -- We are not synced with TomTom's waypoint DB
            return false
        end
    end
    return true
end

function WorldOfParkour:CheckIfPointExists(uid)
    -- This can prevent duplicates from entering our system.
    local key = TomTom:GetKey(uid)
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        if TomTom:GetKey(coursePoint.uid) == key then return true end
    end
    return false
end

function WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(idx)
    if self:isNotActiveCourse() then NotInActiveModeError() end
    if self:isNotInEditMode() then NotInEditModeError() end

    local nextAvailablePointIdxBeforeSync =
        #self.activeCourseStore.activecourse.course + 1
    if #self.activeCourseStore.activecourse.course ~= 0 then
        if not self:IsSyncedWithTomTomDB() then
            self:SyncWithTomTomDB()
            -- After syncing we need to deal with the new waypoint the user wants added...
            if idx == nextAvailablePointIdxBeforeSync then
                -- If we know the user was trying to add
                -- a point onto the end, we can do that for them.
                idx = #self.activeCourseStore.activecourse.course + 1
            end
        end
    end

    local nextAvailablePointIdxAfterSync =
        #self.activeCourseStore.activecourse.course + 1

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

    -- Do nothing if the point already exists in our Store.
    if self:CheckIfPointExists(uid) then return end

    -- Save to active course state
    local coursePoint = {uid = uid, hint = "No hint", completed = false}
    table.insert(self.activeCourseStore.activecourse.course, idx, coursePoint)

    if idx ~= #self.activeCourseStore.activecourse.course then
        -- Reorder if the user inserted a point anywhere but the end of the course.
        self:ReorderCourseWaypoints()
    end
end

function WorldOfParkour:RemoveWaypointAndReorder(uid)
    if type(uid) ~= "table" then
        error("RemoveWaypoint(uid) UID is not a table.");
    end
    local idx = GetCourseIndex(uid)
    self:RemoveWaypoint(uid)

    -- Do not reorder if user removed last point.
    if idx - 1 ~= #self.activeCourseStore.activecourse.course then
        self:ReorderCourseWaypoints()
    end

    if #self.activeCourseStore.activecourse.course ~= 0 then
        if not self:IsSyncedWithTomTomDB() then self:SyncWithTomTomDB() end
    end

    -- -- Add point to GUI
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    local activeCourseGUI = WorldOfParkour.GUIoptionsStore.options.args
                                .activecourse.args
    for k, _ in pairs(activeCourseGUI) do
        -- Find the active course, there will only be 1.
        if string.match(k, uuidPattern) then ReloadPointsToGUI(k) end
    end
end

function WorldOfParkour:RemoveWaypoint(uid)
    if self:isNotActiveCourse() then NotInActiveModeError() end
    if self:isNotInEditMode() then NotInEditModeError() end

    local idx = GetCourseIndex(uid)
    table.remove(self.activeCourseStore.activecourse.course, idx)
    TomTom:RemoveWaypoint(uid)
end

function WorldOfParkour:ReorderCourseWaypoints()
    self:RemoveAllTomTomWaypoints()

    local updatedActiveCourseStore = {}

    for idx, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        local oldIdx = GetCourseIndex(uid)
        if idx ~= oldIdx then
            -- Rename the waypoint
            uid.title = "Point " .. idx
        end
        table.insert(updatedActiveCourseStore, coursePoint)
    end

    self.activeCourseStore.activecourse.course = updatedActiveCourseStore

    self:ReloadActiveCourse()
end

function WorldOfParkour:CreateWaypointDetails(idx)
    local mapID, x, y = TomTom:GetCurrentPlayerPosition()
    local opts = {
        title = "Point " .. idx,
        from = "World of Parkour",
        -- We will handle the persistence on our end.
        persistent = false,
        callbacks = self:CreateTomTomCallbacks(),
        minimap_icon_size = 10,
        worldmap_icon_size = 10,
        arrivaldistance = 5
        -- cleardistance = 2
    }
    return {mapID, x, y, opts}
end

function WorldOfParkour:ReloadActiveCourse()
    if self:isNotActiveCourse() then NotInActiveModeError() end
    -- Recover our last active parkour course.
    -- We need to recreate our active course store
    -- because the recovered uid's are now invalid.
    local updatedActiveCourseStore = {}

    self:Printf("num points: %s", #self.activeCourseStore.activecourse.course)

    -- Recreate the TomTom waypoints with our callbacks
    for _, coursePoint in pairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        local m, x, y = unpack(uid)

        -- Set up default options
        local options = {callbacks = self:CreateTomTomCallbacks()}

        -- Recover details from saved waypoints
        for k, v in pairs(uid) do
            if type(k) == "string" then
                if k ~= "callbacks" then
                    -- we can never import callbacks, so ditch them
                    options[k] = v
                end
            end
        end

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

    self.activeCourseStore.activecourse.course = updatedActiveCourseStore
end

function WorldOfParkour:NewCourseDefaults()
    local title = "New Parkour Course"
    -- TODO: MAYBE add identifier at the end of title.
    -- local count = 0
    -- for k, v in pairs(self.savedCoursesStore.savedcourses) do
    --     if StartsWith(v.title, title) then
    --         local number = tonumber(string.match(v.title, "%d+"))
    --         count = math.max(count, number)
    --     end
    -- end

    -- -- title = title ..
    -- if count ~= 0 then
    --     title = title .. count
    -- end

    return {
        title = title,
        description = "Describe me",
        id = UUID(),
        course = {}
    }
end

function WorldOfParkour:RemoveAllTomTomWaypoints()
    if self:isNotActiveCourse() then NotInActiveModeError() end
    if #self.activeCourseStore.activecourse.course == 0 then return end
    -- NOTE: This will ONLY remove WorldOfParkour TomTom waypoints.
    for _, coursePoint in pairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        TomTom:RemoveWaypoint(uid)
    end
end

function WorldOfParkour:ResetMemory()
    if self:isActiveCourse() then self:RemoveAllTomTomWaypoints() end
    self.activeCourseStore.activecourse.course = {}
    self.activeCourseDB:ResetProfile()
    self.activeCourseDB:ResetDB()
    self.savedCoursesDB:ResetDB()
end

function WorldOfParkour:ClearSavedCourses()
    self.savedCoursesStore.savedcourses = {}
    self.GUIoptionsDB:ResetDB()
end

--[[-------------------------------------------------------------------
--  Define utility functions
-------------------------------------------------------------------]] --

function GetCourseIndex(uid) return tonumber(Split(uid.title, " ")[2]) end

function UUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function Map(t, f)
    local t1 = {}
    local t_len = #t
    for i = 1, t_len do t1[i] = f(t[i]) end
    return t1
end

function Difference(a, b)
    if #b > #a then
        error(
            "You must flip the inputs OR ensure that the table lengths are equal.")
    end
    local aa = {}
    for k, v in pairs(a) do aa[v] = true end
    for k, v in pairs(b) do aa[v] = nil end
    local ret = {}
    local n = 0
    for k, v in pairs(a) do
        if aa[v] then
            n = n + 1
            ret[n] = v
        end
    end
    return ret
end

function Range(low, high)
    local fullRange = {}
    -- Since the keys are numbered, we can find the missing number and make that our ID.
    for var = low, high do table.insert(fullRange, var) end
    return fullRange
end

function Split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function Bind(t, k)
    -- Allows me to pass an objects function as a paremeter to another functions
    -- https://stackoverflow.com/questions/20022379/lua-how-to-pass-objects-function-as-parameter-to-another-function
    return function(...) return t[k](t, ...) end
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

function StartsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

function Tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function SetContains(set, key) return set[key] ~= nil end

function ReplaceTable(fromTable, toTable)
    -- erase all old keys
    for k, _ in pairs(toTable) do toTable[k] = nil end

    -- copy the new ones over
    for k, v in pairs(fromTable) do toTable[k] = v end
end
