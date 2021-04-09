-- Add standard addon support.
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
WorldOfParkour = LibStub("AceAddon-3.0"):NewAddon("WorldOfParkour", "AceConsole-3.0", "AceTimer-3.0",
                                                  "AceEvent-3.0")
local _, addon = ...
local utils = addon.utils
local errors = addon.errors

function WorldOfParkour:OnInitialize()
    self.activeCourseDefaults = {
        profile = {isInEditMode = false, isActiveCourse = false, activecourse = {}, backupActivecourse = {}}
    }
    self.savedcoursesDefaults = {global = {savedcourses = {}}}
    self.firstLoadDefaults = {global = {officialcoursesfirstload = {}, officialcourseids = {}}}
    self.backupDefaults = {global = {backup = {}}}

    self.activeCourseDB = LibStub("AceDB-3.0"):New("WoPActiveParkourCourseDB", self.activeCourseDefaults)
    self.savedCoursesDB = LibStub("AceDB-3.0"):New("WoPSavedParkourCoursesDB", self.savedcoursesDefaults)
    self.firstLoadDB = LibStub("AceDB-3.0"):New("WoPFirstLoadDB", self.firstLoadDefaults)
    self.backupDB = LibStub("AceDB-3.0"):New("WoPBackupDB", self.backupDefaults)

    self.activeCourseDB.RegisterCallback(self, "OnProfileChanged", "RefreshAddon")
    self.activeCourseDB.RegisterCallback(self, "OnProfileCopied", "RefreshAddon")
    self.activeCourseDB.RegisterCallback(self, "OnProfileReset", "RefreshAddon")

    self.activeCourseStore = self.activeCourseDB.profile
    self.savedCoursesStore = self.savedCoursesDB.global
    self.firstLoadStore = self.firstLoadDB.global
    self.backupStore = self.backupDB.global

    self.GUIoptionsDefaults = {profile = {options = self:GenerateOptions()}}
    self.GUIoptionsDB = LibStub("AceDB-3.0"):New("WoPGUIDB", self.GUIoptionsDefaults)
    self.GUIoptionsStore = self.GUIoptionsDB.profile

    self.arrivalDistance = 2
    self.clearDistance = 3
    self.courseSearch = ""
    self.showCourseString = {}
    self.importCourseString = ""
    self.github = "https://github.com/jmaldon1/WorldOfParkour"
    self.githubIssues = "https://github.com/jmaldon1/WorldOfParkour/issues"

    -- Register when a player is logging out.
    -- https://wow.gamepedia.com/PLAYER_LEAVING_WORLD
    self:RegisterEvent("PLAYER_LEAVING_WORLD", "BackupCourseStrings")

    self:CreateGUI()
end

function WorldOfParkour:OnEnable()
    -- Blizzard Addon interface menu.
    self:CreateConfig()

    -- Load all default courses the first time the addon is opened.
    -- These will not be added again unless the user resets the addon.
    for k, courseImportString in pairs(addon.officialCourses) do
        if self.firstLoadStore.officialcoursesfirstload[k] == nil then
            local courseId = ImportAndAddToOfficialCoursesGUI(courseImportString)
            -- Add the official course Ids to a set
            self.firstLoadStore.officialcourseids[courseId] = true
            -- Mark down that this course should not be loaded again.
            self.firstLoadStore.officialcoursesfirstload[k] = true
        end
    end

    -- Reload last active parkour course on load.
    if self:isActiveCourse() then self:ReloadActiveCourse() end
end

-- Get the current error handler
local origHandler = geterrorhandler()

local function OnErrorHandler(msg)
    -- print(msg)
    return origHandler(msg)
end
seterrorhandler(OnErrorHandler)

local function WoPMessage(msg)
    -- Create string with addon name appended.
    return string.format("|cff33ff99WorldOfParkour|r: %s", msg)
end

--[[-------------------------------------------------------------------
--  WorldOfParkour
-------------------------------------------------------------------]] --
function WorldOfParkour:RefreshAddon()
    -- TODO: Possibly do this without closing the window and just update the GUI.
    AceConfigDialog:Close("WorldOfParkour")
    WorldOfParkour:OnInitialize()
end

function WorldOfParkour:Error(msg)
    local err = "\124cFFFF0000Error: \124r"
    WorldOfParkour:Print(err .. msg)
    error(msg)
end

function WorldOfParkour:isActiveCourse() return self.activeCourseStore.isActiveCourse end

function WorldOfParkour:isNotActiveCourse() return not self:isActiveCourse() end

function WorldOfParkour:isInEditMode() return self.activeCourseStore.isInEditMode end

function WorldOfParkour:isNotInEditMode() return not self:isInEditMode() end

function WorldOfParkour:isOfficialCourse(courseId)
    if self.firstLoadStore.officialcourseids[courseId] then
        return true
    end
    return false
end

function WorldOfParkour:SyncWithTomTomDB()
    -- This will remove any points that exist in our store but not TomTom's,
    -- thus syncing us with TomTom.
    if self:isNotActiveCourse() then errors.notInActiveModeError() end

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
        assert(self:IsSyncedWithTomTomDB(), WoPMessage("We aren't synced? Report this bug."))
    end
    -- Reorder the course to deal with the missing values.
    self:ReorderCourseWaypoints()
end

function WorldOfParkour:IsSyncedWithTomTomDB()
    if self:isNotActiveCourse() then errors.notInActiveModeError() end

    if #self.activeCourseStore.activecourse.course == 0 then
        -- If there are 0 points in the our course, it is not possible to determine
        -- if we are synced with TomTom's DB or not. So we throw.
        WorldOfParkour:Error("Unable to determine if we are synced with TomTomDB...")
    end
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        if not TomTom:IsValidWaypoint(coursePoint.uid) then
            -- We are not synced with TomTom's waypoint DB
            return false
        end
    end
    return true
end

function WorldOfParkour:IsExistingPoint(uid)
    -- This can prevent duplicates from entering our system.
    local key = TomTom:GetKey(uid)
    for _, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        if TomTom:GetKey(coursePoint.uid) == key then return true end
    end
    return false
end

function WorldOfParkour:IsCourseBeingRun(course) return self:GetCourseCompletion(course) ~= 0 end

function WorldOfParkour:IsCourseNotBeingRun(course) return not self:IsCourseBeingRun(course) end

function WorldOfParkour:ResetCourseCompletion(courseDetails, isActiveCourse)
    courseDetails.metadata.isComplete = false
    for _, coursePoint in pairs(courseDetails.course) do coursePoint.completed = false end

    if isActiveCourse then self:ReloadActiveCourse() end
end

function WorldOfParkour:GetCourseCompletion(course)
    -- Returns a value between 0 and 1.
    -- 0 being unstarted and 1 being complete.
    if #course == 0 then return 0 end

    local isCompleted = function(coursePoint) return coursePoint.completed == true end
    local completePoints = utils.filter(course, isCompleted)
    return #completePoints / #course
end

function WorldOfParkour:GetNextUncompletedPoint()
    -- Find the next uncompleted course point, return nil if all points are completed
    local course = self.activeCourseStore.activecourse.course
    for _, v in pairs(course) do if v.completed == false then return v.uid end end
    return nil
end

function WorldOfParkour:CreateCoursePoint(uid) return {uid = uid, hint = "No hint", completed = false} end

function WorldOfParkour:BackupCourseStrings()
    -- Backup saved courses
    local savedCourses = WorldOfParkour.savedCoursesStore.savedcourses
    local backup = self.backupStore.backup
    for id, v in pairs(savedCourses) do
        if not backup[id] then
            -- If the course doesnt exist in our backup, add it.
            backup[id] = {title = "", lastmodifieddate = "", coursestring = ""}
        end
        local lastModifiedDate = v.lastmodifieddate
        local lastModifiedDateBackup = backup[id].lastmodifieddate

        if lastModifiedDate ~= lastModifiedDateBackup then
            -- If the modified date has changed, update the course string.
            backup[id].title = v.title
            backup[id].lastmodifieddate = lastModifiedDate
            backup[id].coursestring = self:CreateSharableString(v.compressedcoursedata)
        end
    end

    -- Clean up deleted courses from the backup.
    for id, _ in pairs(backup) do if not savedCourses[id] then backup[id] = nil end end
end

function WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(idx)
    if self:isNotActiveCourse() then errors.notInActiveModeError() end
    if self:isNotInEditMode() then errors.notInEditModeError() end
    if #self.activeCourseStore.activecourse.course >= 1000 then
        -- Hard limit on course points, just in case.
        WorldOfParkour:Error("Max point limit reached.")
    end

    local nextAvailablePointIdxBeforeSync = #self.activeCourseStore.activecourse.course + 1
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

    local nextAvailablePointIdxAfterSync = #self.activeCourseStore.activecourse.course + 1

    if type(idx) ~= "number" then
        WorldOfParkour:Error("SetWaypointAtIndexOnCurrentPosition(idx): idx is not a number.");
    end

    if idx <= 0 or idx > nextAvailablePointIdxAfterSync then
        WorldOfParkour:Error("Point index out of range. " .. "The next point you can create is " .. "'" ..
                                 nextAvailablePointIdxAfterSync .. "'.");
    end

    -- Create the waypoint
    local mapID, x, y, opts = unpack(self:CreateWaypointDetails(idx))
    if TomTom:WaypointExists(mapID, x, y, opts.title) then
        WorldOfParkour:Error("This point already exists, try moving from this spot.")
    end

    local uid = TomTom:AddWaypoint(mapID, x, y, opts)

    -- Do nothing if the point already exists in our Store.
    if self:IsExistingPoint(uid) then return end

    -- Save to active course state
    local coursePoint = self:CreateCoursePoint(uid)
    table.insert(self.activeCourseStore.activecourse.course, idx, coursePoint)

    if idx ~= #self.activeCourseStore.activecourse.course then
        -- Reorder if the user inserted a point anywhere but the end of the course.
        self:ReorderCourseWaypoints()
    end
end

function WorldOfParkour:RemoveWaypointAndReorder(uid)
    if type(uid) ~= "table" then WorldOfParkour:Error("RemoveWaypoint(uid) UID is not a table."); end
    local idx = utils.getCoursePointIndex(uid)
    self:RemoveWaypoint(uid)

    -- Do not reorder if user removed last point.
    if idx - 1 ~= #self.activeCourseStore.activecourse.course then self:ReorderCourseWaypoints() end

    if #self.activeCourseStore.activecourse.course ~= 0 then
        if not self:IsSyncedWithTomTomDB() then self:SyncWithTomTomDB() end
    end

    -- -- Add point to GUI
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    local activeCourseGUI = WorldOfParkour.GUIoptionsStore.options.args.activecourse.args
    for k, _ in pairs(activeCourseGUI) do
        -- Find the active course, there will only be 1.
        if string.match(k, uuidPattern) then ReloadPointsToGUI(k) end
    end
end

function WorldOfParkour:RemoveWaypoint(uid)
    if self:isNotActiveCourse() then errors.notInActiveModeError() end
    if self:isNotInEditMode() then errors.notInEditModeError() end

    local idx = utils.getCoursePointIndex(uid)
    table.remove(self.activeCourseStore.activecourse.course, idx)
    TomTom:RemoveWaypoint(uid)
end

function WorldOfParkour:ReorderCourseWaypoints()
    self:RemoveAllTomTomWaypoints()

    local updatedActiveCourseStore = {}

    for idx, coursePoint in ipairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        local oldIdx = utils.getCoursePointIndex(uid)
        if idx ~= oldIdx then
            -- Rename the waypoint
            uid.title = "Point " .. idx
        end
        table.insert(updatedActiveCourseStore, coursePoint)
    end

    self.activeCourseStore.activecourse.course = updatedActiveCourseStore

    self:ReloadActiveCourse()
end

function WorldOfParkour:InsertToSavedCourses(course)
    course.compressedcoursedata = self:CompressCourseData(course)
    WorldOfParkour.savedCoursesStore.savedcourses[course.id] = course
end

function WorldOfParkour:ReplaceSavedCourse(course)
    utils.replaceTable(course, WorldOfParkour.savedCoursesStore.savedcourses[course.id])
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
        arrivaldistance = self.arrivalDistance
    }
    return {mapID, x, y, opts}
end

function WorldOfParkour:CreateTomTomWaypointArgs(uid)
    local m, x, y = unpack(uid)

    -- Set up default options
    local options = {callbacks = WorldOfParkour:CreateTomTomCallbacks()}

    -- Recover details from saved waypoints
    for k, v in pairs(uid) do
        if type(k) == "string" then
            if k ~= "callbacks" then
                -- callbacks cannot be recovered
                options[k] = v
            end
        end
    end
    return m, x, y, options
end

function WorldOfParkour:ReloadActiveCourse()
    if self:isNotActiveCourse() then errors.notInActiveModeError() end
    -- Recover our last active parkour course.
    -- We need to recreate our active course store
    -- because the recovered uid's are now invalid.
    local updatedActiveCourseStore = {}

    -- self:Printf("num points: %s", #self.activeCourseStore.activecourse.course)

    -- Recreate the TomTom waypoints with our callbacks
    for _, coursePoint in pairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        local m, x, y, options = self:CreateTomTomWaypointArgs(uid)

        local isSuccess, results = pcall(utils.bind(TomTom, "AddWaypoint"), m, x, y, options)
        if not isSuccess then WorldOfParkour:Error("This course is invalid, please delete it.") end

        local updatedUid = results
        if coursePoint.completed == true then
            -- Don't show waypoints that are already completed.
            TomTom:RemoveWaypoint(updatedUid)
        end
        local updatedCoursePoint = {uid = updatedUid}

        -- Move details from old coursePoint to new coursePoint
        for k, v in pairs(coursePoint) do
            if k ~= "uid" then
                -- We don't want the old Uid because we already recreated it.
                updatedCoursePoint[k] = v
            end
        end

        table.insert(updatedActiveCourseStore, updatedCoursePoint)
    end

    self.activeCourseStore.activecourse.course = updatedActiveCourseStore
    if self:isInEditMode() then
        SetCrazyArrowToFirstOrLastPoint("last")
    else
        local nextUncompletedUid = self:GetNextUncompletedPoint()
        if not nextUncompletedUid then return end
        TomTom:SetCrazyArrow(nextUncompletedUid, self.arrivalDistance, nextUncompletedUid.title)
    end
end

local function makeUniqueCourseTitle(defaultCourseTitle)
    local getCourseTitle = function(course) return course.title end
    local savedCourses = WorldOfParkour.savedCoursesStore.savedcourses
    local allCourseTitlesArray = utils.map(savedCourses, getCourseTitle)
    local allCourseTitles = utils.convertValsToTableKeys(allCourseTitlesArray)
    if not utils.setContains(allCourseTitles, defaultCourseTitle) then
        -- If the default name isn't used yet, use it.
        return defaultCourseTitle
    end

    local name = defaultCourseTitle .. " %s"
    local i = 1
    while utils.setContains(allCourseTitles, string.format(name, i)) do i = i + 1 end
    return string.format(name, i)
end

function WorldOfParkour:CreateNewCourseMetadata()
    return {
        isComplete = false,
        -- Only one character can edit a course at a time.
        characterEditingCourse = "",
        -- Multiple characters can have a course as active.
        charactersWithCourseAsActive = {}
    }
end

function WorldOfParkour:NewCourseDefaults()
    return {
        -- While unique course titles are not required, it makes readability easier.
        title = makeUniqueCourseTitle("New Parkour Course"),
        description = "Description of course",
        id = utils.UUID(),
        course = {},
        difficulty = "Easy",
        lastmodifieddate = date("%m/%d/%y %H:%M:%S"),
        creator = string.format("%s-%s", UnitFullName("player")),
        wowversion = (select(1, GetBuildInfo())),
        compressedcoursedata = "",
        -- We will clear this metadata on copy or import.
        metadata = self:CreateNewCourseMetadata()
    }
end

function WorldOfParkour:RemoveAllTomTomWaypoints()
    if self:isNotActiveCourse() then errors.notInActiveModeError() end
    if #self.activeCourseStore.activecourse.course == 0 then return end
    -- NOTE: This will ONLY remove WorldOfParkour TomTom waypoints.
    for _, coursePoint in pairs(self.activeCourseStore.activecourse.course) do
        local uid = coursePoint.uid
        TomTom:RemoveWaypoint(uid)
    end
end

-- function WorldOfParkour:ResetMemory()
--     if self:isActiveCourse() then self:RemoveAllTomTomWaypoints() end
--     self.activeCourseStore.activecourse.course = {}
--     self.activeCourseDB:ResetProfile()
--     self.activeCourseDB:ResetDB()
--     self.savedCoursesDB:ResetDB()
-- end
