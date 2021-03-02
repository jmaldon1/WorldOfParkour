local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--[[-------------------------------------------------------------------
--  Logic
-------------------------------------------------------------------]] --

local function findCourseIdRecursive(info, level)
    level = level or 0
    local levelName = info[#info - level]
    if not levelName then error("Couldn't find ID") end
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    if string.match(levelName, uuidPattern) then return levelName end
    return findCourseIdRecursive(info, level + 1)
end

function SetCrazyArrowToFirstOrLastPoint(option)
    local course = WorldOfParkour.activeCourseStore.activecourse.course
    if #course == 0 then return end

    if option == "first" then
        TomTom:SetCrazyArrow(course[1].uid, WorldOfParkour.arrivalDistance, course[1].uid.title)
    elseif option == "last" then
        TomTom:SetCrazyArrow(course[#course].uid, WorldOfParkour.arrivalDistance, course[#course].uid.title)
    else
        error("Input must be either {'first', 'last'}")
    end
end

local function isCoursePointsDifferent(courseAPointsDetails, courseBPointsDetails)
    if #courseAPointsDetails ~= #courseBPointsDetails then return true end

    local courseAPointIds = {}
    local courseBPointIds = {}

    for _, coursePoint in pairs(courseAPointsDetails) do
        table.insert(courseAPointIds, TomTom:GetKey(coursePoint.uid))
    end
    for _, coursePoint in pairs(courseBPointsDetails) do
        table.insert(courseBPointIds, TomTom:GetKey(coursePoint.uid))
    end

    if #Difference(courseAPointIds, courseBPointIds) == 0 then return false end
    return true
end

local function isCourseDetailsDifferent(courseA, courseB, detailsToSkip)
    for detailName, detail in pairs(courseA) do
        -- Skip irrelevant details.
        if not SetContains(detailsToSkip, detailName) then
            if courseB[detailName] ~= detail then return true end
        end
    end
    return false
end

local function isCoursePointDetailsDifferent(courseAPointsDetails, courseBPointsDetails)
    if #courseAPointsDetails ~= #courseBPointsDetails then return true end

    local detailsToSkip = {uid = true, completed = true}

    for i = 1, #courseAPointsDetails do
        local isCoursePointDetailsDiff = isCourseDetailsDifferent(courseAPointsDetails[i],
                                                                  courseBPointsDetails[i], detailsToSkip)
        if isCoursePointDetailsDiff then return true end
    end
    return false
end

local function isCourseDifferent(courseA, courseB)
    local isCoursePointsDiff = isCoursePointsDifferent(courseA.course, courseB.course)
    local detailsToSkip = {course = true, metadata = true}
    local isCourseDetailsDiff = isCourseDetailsDifferent(courseA, courseB, detailsToSkip)
    local isCoursePointDetailsDiff = isCoursePointDetailsDifferent(courseA.course, courseB.course)
    return isCoursePointsDiff or isCourseDetailsDiff or isCoursePointDetailsDiff
end

local function enableEditMode(info)
    local courseId = findCourseIdRecursive(info)
    local savedCourseMetadata = WorldOfParkour.savedCoursesStore.savedcourses[courseId].metadata
    local characterEditingCourse = savedCourseMetadata.characterEditingCourse
    if characterEditingCourse ~= "" then
        local coloredCharacterName = string.format("\124cFFFFF468%s\124r", characterEditingCourse)
        local errMsg = string.format(
                           "This course is already editing by '%s', you must exit editing mode on that character to edit this course.",
                           coloredCharacterName)
        error(errMsg)
    end
    savedCourseMetadata.characterEditingCourse = string.format("%s-%s", UnitFullName("player"))

    -- Reset the course completion before editing.
    WorldOfParkour:ResetCourseCompletion(WorldOfParkour.activeCourseStore.activecourse, true)
    WorldOfParkour.activeCourseStore.isInEditMode = true
    SetCrazyArrowToFirstOrLastPoint("last")
end

local function disableEditMode(courseId)
    local savedCourseMetadata = WorldOfParkour.savedCoursesStore.savedcourses[courseId].metadata
    savedCourseMetadata.characterEditingCourse = ""
    WorldOfParkour.activeCourseStore.isInEditMode = false
    SetCrazyArrowToFirstOrLastPoint("first")
end

local function enableActiveCourse(courseId)
    local savedCourseMetadata = WorldOfParkour.savedCoursesStore.savedcourses[courseId].metadata
    local charactersWithCourseAsActive = savedCourseMetadata.charactersWithCourseAsActive
    local playerFullName = string.format("%s-%s", UnitFullName("player"))
    charactersWithCourseAsActive[playerFullName] = true

    WorldOfParkour.activeCourseStore.isActiveCourse = true
end

local function disableActiveCourse(courseId)
    local savedCourseMetadata = WorldOfParkour.savedCoursesStore.savedcourses[courseId].metadata
    local charactersWithCourseAsActive = savedCourseMetadata.charactersWithCourseAsActive
    local playerFullName = string.format("%s-%s", UnitFullName("player"))
    charactersWithCourseAsActive[playerFullName] = nil

    WorldOfParkour.activeCourseStore.isActiveCourse = false
end

local function removeCourse(info, action)
    local courseId = findCourseIdRecursive(info)

    local savedCourseMetadata = WorldOfParkour.savedCoursesStore.savedcourses[courseId].metadata
    local charactersWithCourseAsActive = TableKeys(savedCourseMetadata.charactersWithCourseAsActive)
    if #charactersWithCourseAsActive > 0 then
        local charactersWithCourseAsActiveList = table.concat(charactersWithCourseAsActive, ", ")
        local coloredCharacterNames = string.format("\124cFFFFF468%s\124r", charactersWithCourseAsActiveList)
        error("Unset this course as active from the following characters before removing: " ..
                  coloredCharacterNames)
    end

    WorldOfParkour.savedCoursesStore.savedcourses[courseId] = nil
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[courseId] = nil
end

local function selectActiveCourse(courseId)
    AceConfigDialog:SelectGroup("WorldOfParkour", "activecourse", courseId)
end

local function selectPoint(ids)
    local courseId = ids.courseId
    local pointId = ids.pointId
    AceConfigDialog:SelectGroup("WorldOfParkour", "activecourse", courseId, "tabedit", "pointslist", pointId)
end

local function selectCourse(courseId) AceConfigDialog:SelectGroup("WorldOfParkour", "courselist", courseId) end

local function isCourseActive(courseId)
    local activeCourse = WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId]
    if activeCourse then return true end
    return false
end

local function addCompletedTitleColor(title)
    -- Show green text for completed courses.
    return string.format("\124cFF34AA05%s\124r", title)
end

local function getEditableCourseTitle()
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local title = activeCourse.title
    if activeCourse.metadata.isComplete then return addCompletedTitleColor(title) end
    return title
end

local function setEditableCourseTitle(info, title) WorldOfParkour.activeCourseStore.activecourse.title = title end

local function getEditableCourseDescription() return WorldOfParkour.activeCourseStore.activecourse.description end

local function setEditableCourseDescription(info, description)
    WorldOfParkour.activeCourseStore.activecourse.description = description
end

local function setEditableCourseDifficulty(info, difficulty)
    WorldOfParkour.activeCourseStore.activecourse.difficulty = difficulty
end

local function getEditableCourseDifficulty() return WorldOfParkour.activeCourseStore.activecourse.difficulty end

local function disableActiveCourseFromAllCourses(info)
    local courseId = findCourseIdRecursive(info)
    return isCourseActive(courseId)
end

local function updateCourse()
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    -- Update the active course if things changed.
    activeCourse.lastmodifieddate = date("%m/%d/%y %H:%M:%S")
    activeCourse.compressedcoursedata = WorldOfParkour:CompressCourseData(activeCourse)
end

local function unsetActiveCourse(info)
    local courseId = findCourseIdRecursive(info)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local backupActiveCourse = WorldOfParkour.activeCourseStore.backupActivecourse
    -- Remove waypoints from screen.
    WorldOfParkour:RemoveAllTomTomWaypoints()

    disableEditMode(courseId)
    disableActiveCourse(courseId)

    local isCourseDiff = isCourseDifferent(activeCourse, backupActiveCourse)
    if isCourseDiff then updateCourse() end
    -- Replace the old course with the active course.
    WorldOfParkour:ReplaceSavedCourse(activeCourse)

    -- Clear some state
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] = nil
    WorldOfParkour.activeCourseStore.activecourse = {}
    WorldOfParkour.activeCourseStore.backupActivecourse = {}

    -- Select the unset course from the course list.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, courseId)
end

local function getCourseTitle(info)
    local courseId = findCourseIdRecursive(info)
    local course = WorldOfParkour.savedCoursesStore.savedcourses[courseId]
    local title = course.title
    if course.metadata.isComplete and not isCourseActive(courseId) then
        return addCompletedTitleColor(title)
    end
    return title
end

local function getCourseDescription(info)
    local courseId = findCourseIdRecursive(info)
    return WorldOfParkour.savedCoursesStore.savedcourses[courseId].description
end

local function validateCourseTitle(info, val)
    if string.len(val) == 0 then return "Course Name: Course name is too short" end
    return true
end

local function setHint(info, hint)
    local pointKey = tonumber(info[#info - 1])
    WorldOfParkour.activeCourseStore.activecourse.course[pointKey].hint = hint
end

local function getHint(info)
    local pointKey = tonumber(info[#info - 1])
    local coursePoint = WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return coursePoint.hint
end

local function getPointName(info)
    local pointKey = tonumber(info[#info])
    local coursePoint = WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return coursePoint.uid.title
end

local function getPointOrder(info) return tonumber(info[#info]) end

local function getCourseSearch() return WorldOfParkour.courseSearch end

local function displayMatchingCourses(courseStartsWith)
    -- This is a simple search, it will just find courses that begin with
    -- the characters the user has typed into the input box.
    -- Hide courses that do not match the search criteria
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    local courseList = WorldOfParkour.GUIoptionsStore.options.args.courselist.args
    for id, v in pairs(courseList) do
        -- Only check courses (We know its a course by the pattern of their table key)
        if string.match(id, uuidPattern) then
            local savedCourses = WorldOfParkour.savedCoursesStore.savedcourses
            local courseName = savedCourses[id].title
            local lowerCourseName = string.lower(courseName)
            local lowerCourseStartsWith = string.lower(courseStartsWith)
            v.hidden = false
            if not StartsWith(lowerCourseName, lowerCourseStartsWith) then
                -- Courses that don't fit the search will be hidden.
                v.hidden = true
            end
        end
    end
end

local function setCourseSearch(info, startsWith)
    WorldOfParkour.courseSearch = startsWith
    displayMatchingCourses(startsWith)
end

local function clearCourseSearch()
    local emptySearch = ""
    WorldOfParkour.courseSearch = emptySearch
    displayMatchingCourses(emptySearch)
end

--[[-------------------------------------------------------------------
--  GUI Options
-------------------------------------------------------------------]] --
local function removePoint(info)
    local pointKey = tonumber(info[#info - 1])
    local coursePoint = WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    local uid = coursePoint.uid
    -- Remove point
    WorldOfParkour:RemoveWaypointAndReorder(uid)
end

local function addPointAfter(info)
    local pointKey = tonumber(info[#info - 1])
    local nextPointKey = pointKey + 1
    SetPoint(nextPointKey)
    local courseId = findCourseIdRecursive(info)
    local pointId = nextPointKey
    local Ids = {courseId = courseId, pointId = pointId}
    -- Select the newly created point.
    WorldOfParkour:ScheduleTimer(selectPoint, 0, Ids)
end

local function createPointGUI()
    return {
        name = getPointName,
        type = "group",
        order = getPointOrder,
        args = {
            hint = {
                name = "Hint",
                type = "input",
                multiline = true,
                width = "full",
                order = 1,
                get = getHint,
                set = setHint
            },
            blank = {order = 2, type = "description", name = "\n"},
            addpointafter = {
                name = "Add point after",
                desc = "Adds a point after this one.",
                type = "execute",
                width = 0.85,
                order = 2,
                func = addPointAfter
            },
            blank_ = {order = 3, type = "description", name = "\n\n"},
            removepoint = {
                name = "Remove Point",
                desc = "Removes this point from the course.",
                type = "execute",
                width = 0.85,
                order = 4,
                func = removePoint
            }
        }
    }
end

function ReloadPointsToGUI(courseId)
    -- Clear all points on the GUI
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId].args.tabedit.args.pointslist.args =
        CreatePointsListGUI()

    -- Regenerate all points again on the GUI
    -- This is done because the points are always being reordered.
    for k, _ in pairs(WorldOfParkour.activeCourseStore.activecourse.course) do
        WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId].args.tabedit.args.pointslist
            .args[tostring(k)] = createPointGUI()
    end
end

local function addNewPoint(info)
    SetPoint()
    local courseId = findCourseIdRecursive(info)
    local pointId = #WorldOfParkour.activeCourseStore.activecourse.course
    local Ids = {courseId = courseId, pointId = pointId}
    -- Select the newly created point.
    WorldOfParkour:ScheduleTimer(selectPoint, 0, Ids)
end

local function addPointToBeginning(info)
    SetPoint(1)
    local courseId = findCourseIdRecursive(info)
    local Ids = {courseId = courseId, pointId = 1}
    -- Select the newly created point.
    WorldOfParkour:ScheduleTimer(selectPoint, 0, Ids)
end

function CreatePointsListGUI()
    return {
        addpoint = {
            name = "Add point",
            desc = "Add a point to the end of the course",
            type = "execute",
            width = 1.2,
            order = 1,
            func = addNewPoint
        },
        blank = {order = 2, type = "description", name = "\n"},
        addpointToBeginning = {
            name = "Add point to beginning",
            desc = "Add a point to the start of the course.",
            type = "execute",
            width = 1.2,
            order = 3,
            func = addPointToBeginning
        }
        -- All points go here
    }
end

local function disableUndo()
    -- If we are not in editing mode, disable button.
    if WorldOfParkour:isNotInEditMode() then return true end
    local backupActiveCourse = WorldOfParkour.activeCourseStore.backupActivecourse
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    -- Disable if courses aren't different
    return not isCourseDifferent(activeCourse, backupActiveCourse)
end

local function getCourseDifficultyDisplay(info)
    local courseId = findCourseIdRecursive(info)
    local difficulty = WorldOfParkour.savedCoursesStore.savedcourses[courseId].difficulty
    local colorMap = {Easy = "\124cFF00FF00", Medium = "\124cFFFFFF00", Hard = "\124cFFFF0000"}

    return "Difficulty: " .. string.format("%s%s\124r", colorMap[difficulty], difficulty)
end

local function getActiveCourseCompletion()
    if WorldOfParkour:isNotActiveCourse() then NotInActiveModeError() end
    local course = WorldOfParkour.activeCourseStore.activecourse.course
    return WorldOfParkour:GetCourseCompletion(course)
end

local function getSavedCourseCompletion(info)
    local courseId = findCourseIdRecursive(info)
    local course = WorldOfParkour.savedCoursesStore.savedcourses[courseId].course
    return WorldOfParkour:GetCourseCompletion(course)
end

local function isCourseCompletionResetDisabled()
    local course = WorldOfParkour.activeCourseStore.activecourse.course
    -- Disable if they aren't running the course.
    return WorldOfParkour:IsCourseNotBeingRun(course)
end

local function getWoWPatch(info)
    local courseId = findCourseIdRecursive(info)
    local lastModifiedDate = WorldOfParkour.savedCoursesStore.savedcourses[courseId].lastmodifieddate
    return string.format("\124cFFFFFF00Last modified date: %s\124r", lastModifiedDate)
end

local function courseResetButtonFn()
    local courseDetails = WorldOfParkour.activeCourseStore.activecourse
    WorldOfParkour:ResetCourseCompletion(courseDetails, true)
end

local function editCourseConfirm()
    local course = WorldOfParkour.activeCourseStore.activecourse.course
    return WorldOfParkour:IsCourseBeingRun(course)
end

local function createActiveCourseGUI()
    local activeCourse = {
        name = getEditableCourseTitle,
        desc = getCourseDescription,
        type = "group",
        childGroups = "tab",
        args = {
            tabinfo = {
                name = "info",
                type = "group",
                order = 1,
                args = {
                    header = {order = 1, type = "header", name = getCourseTitle},
                    difficulty = {order = 2, name = getCourseDifficultyDisplay, type = "description"},
                    blank = {order = 3, type = "description", name = "\n"},
                    description = {order = 4, type = "description", name = getCourseDescription},
                    wowpatch = {order = 5, type = "description", name = getWoWPatch},
                    blank_ = {order = 6, type = "description", name = "\n\n"},
                    range = {
                        name = "Course Completion",
                        desc = "complete",
                        type = "range",
                        width = "full",
                        min = 0,
                        max = 1,
                        disabled = true,
                        isPercent = true,
                        order = 7,
                        get = getActiveCourseCompletion
                    },
                    blank__ = {order = 8, type = "description", name = "\n"},
                    unsetactivecourse = {
                        name = "Unset Active Course",
                        desc = "Remove this course from Active Course." ..
                            "\n\nIf you edited this course, this will save your changes.",
                        type = "execute",
                        width = "full",
                        order = 9,
                        func = unsetActiveCourse
                    }
                }
            },
            tabedit = {
                name = "edit",
                type = "group",
                order = 2,
                args = {
                    editcourse = {
                        name = "Edit Course",
                        desc = "Edit the course",
                        confirm = editCourseConfirm,
                        confirmText = "Editing the course now will reset your completion progress. Are you sure?\n\n" ..
                            "If you would like to edit this course without losing your progress, make a copy and edit that.",
                        type = "execute",
                        disabled = Bind(WorldOfParkour, "isInEditMode"),
                        width = "full",
                        order = 1,
                        func = enableEditMode
                    },
                    blank = {order = 2, type = "description", name = ""},
                    title = {
                        name = "Course Name",
                        validate = validateCourseTitle,
                        desc = "Set the title of the course",
                        type = "input",
                        order = 3,
                        width = "double",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        set = setEditableCourseTitle,
                        get = getEditableCourseTitle
                    },
                    blank_ = {order = 4, type = "description", name = ""},
                    description = {
                        name = "Description",
                        desc = "Set the description of the course.",
                        type = "input",
                        multiline = true,
                        width = "double",
                        order = 5,
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        set = setEditableCourseDescription,
                        get = getEditableCourseDescription
                    },
                    difficulty = {
                        name = "Difficulty",
                        values = {Easy = "Easy", Medium = "Medium", Hard = "Hard"},
                        sorting = {"Easy", "Medium", "Hard"},
                        desc = "Set the course difficulty level.",
                        type = "select",
                        order = 6,
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        set = setEditableCourseDifficulty,
                        get = getEditableCourseDifficulty
                    },
                    pointslist = {
                        name = "Course Points",
                        type = "group",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        order = 7,
                        args = CreatePointsListGUI()
                    }
                }
            },
            taboptions = {
                name = "options",
                type = "group",
                order = 3,
                args = {
                    save = {
                        name = "Save changes",
                        desc = "Save all changes made while editing the course.\n\n" ..
                            "If no changes were made, this will just exit out of editing mode.",
                        type = "execute",
                        width = "double",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        order = 1,
                        func = ExitWithSave
                    },
                    blank = {order = 2, type = "description", name = "\n"},
                    undo = {
                        name = "Undo changes",
                        desc = "Undo all changes made while editing this course.",
                        type = "execute",
                        confirm = true,
                        confirmText = "Are you sure you want to undo these changes?\n\n" ..
                            "You cannot recover them.",
                        width = "double",
                        disabled = disableUndo,
                        order = 3,
                        func = ExitWithoutSaving
                    },
                    blank_ = {order = 4, type = "description", name = "\n\n\n"},
                    resetcoursecompletion = {
                        name = "Reset course completion",
                        desc = "Reset the course, allowing you to run the coures again.",
                        type = "execute",
                        width = "double",
                        confirm = true,
                        confirmText = "Are you sure you want to reset the course completion?",
                        disabled = isCourseCompletionResetDisabled,
                        order = 5,
                        func = courseResetButtonFn
                    }
                }
            }
        }
    }

    -- Load already set points
    for k, _ in pairs(WorldOfParkour.activeCourseStore.activecourse.course) do
        activeCourse.args.tabedit.args.pointslist.args[tostring(k)] = createPointGUI()
    end

    return activeCourse
end

function ExitWithoutSaving()
    local backupActiveCourse = WorldOfParkour.activeCourseStore.backupActivecourse
    local courseId = WorldOfParkour.activeCourseStore.activecourse.id
    local backupActiveCourseCopy = Deepcopy(backupActiveCourse)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local isCoursePointsDiff = isCoursePointsDifferent(activeCourse.course, backupActiveCourse.course)
    if isCoursePointsDiff then WorldOfParkour:RemoveAllTomTomWaypoints() end

    ReplaceTable(backupActiveCourseCopy, WorldOfParkour.activeCourseStore.activecourse)
    -- Reset ActiveCourse GUI
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] = createActiveCourseGUI()

    if isCoursePointsDiff and not #backupActiveCourse.course == 0 then
        -- Only sync if the user made changes to the course points
        -- and the backup actually has points.
        WorldOfParkour:SyncWithTomTomDB()
    end
    -- Reload the TomTom waypoints.
    WorldOfParkour:ReloadActiveCourse()

    -- Turn off editing mode.
    disableEditMode(courseId)
end

function ExitWithSave(info)
    local courseId = findCourseIdRecursive(info)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local backupActiveCourse = WorldOfParkour.activeCourseStore.backupActivecourse
    local isCourseDiff = isCourseDifferent(activeCourse, backupActiveCourse)
    if isCourseDiff then updateCourse() end

    local activeCourseCopyOne = Deepcopy(activeCourse)
    local activeCourseCopyTwo = Deepcopy(activeCourse)

    -- Replace the old course with the active course.
    WorldOfParkour:ReplaceSavedCourse(activeCourseCopyOne)
    -- Update the backup
    ReplaceTable(activeCourseCopyTwo, backupActiveCourse)

    disableEditMode(courseId)
end

local function setActiveCourse(info, action)
    local courseId = findCourseIdRecursive(info)
    local savedCourse = WorldOfParkour.savedCoursesStore.savedcourses[courseId]

    -- We need to make copies here because Lua passes around tables as reference.
    -- We do not want to edit the original table.
    local savedCourseCopy = Deepcopy(savedCourse)
    local savedCourseBackupCopy = Deepcopy(savedCourse)
    ReplaceTable(savedCourseCopy, WorldOfParkour.activeCourseStore.activecourse)
    ReplaceTable(savedCourseBackupCopy, WorldOfParkour.activeCourseStore.backupActivecourse)

    enableActiveCourse(courseId)

    -- Add TomTom waypoints to screen.
    if #savedCourse.course ~= 0 then
        local isSuccess, err = pcall(Bind(WorldOfParkour, "ReloadActiveCourse"))
        if not isSuccess then
            -- User tried to load a bad course, we stop them here.
            disableActiveCourse(courseId)
            WorldOfParkour.activeCourseStore.activecourse = {}
            WorldOfParkour.activeCourseStore.backupActivecourse = {}
            error(err)
        end
    end

    -- Add to GUI
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] = createActiveCourseGUI()

    SetCrazyArrowToFirstOrLastPoint("first")

    WorldOfParkour:ScheduleTimer(selectActiveCourse, 0, courseId)
end

local function getSharableString(info)
    local courseId = findCourseIdRecursive(info)
    local savedCourse = WorldOfParkour.savedCoursesStore.savedcourses[courseId]
    return WorldOfParkour:CreateSharableString(savedCourse.compressedcoursedata)
end

local function setToggleCourseString(info, action)
    local courseId = findCourseIdRecursive(info)
    WorldOfParkour.showCourseString[courseId] = action
end

local function getToggleCourseString(info)
    local courseId = findCourseIdRecursive(info)
    if not WorldOfParkour.showCourseString[courseId] then
        WorldOfParkour.showCourseString[courseId] = false
        return false
    end
    return WorldOfParkour.showCourseString[courseId]
end

local function displayCourseString(info)
    local courseId = findCourseIdRecursive(info)
    return not WorldOfParkour.showCourseString[courseId]
end

local function createSavedCourseGUI()
    return {
        name = getCourseTitle,
        desc = getCourseDescription,
        type = "group",
        hidden = false,
        disabled = disableActiveCourseFromAllCourses,
        args = {
            titleheader = {name = getCourseTitle, type = "header", order = 1},
            difficulty = {order = 2, name = getCourseDifficultyDisplay, type = "description"},
            blank = {order = 3, type = "description", name = "\n"},
            description = {name = getCourseDescription, type = "description", order = 4},
            wowpatch = {order = 5, type = "description", name = getWoWPatch},
            blank_ = {order = 6, type = "description", name = "\n\n"},
            range = {
                name = "Course Completion",
                desc = "complete",
                type = "range",
                width = "full",
                min = 0,
                max = 1,
                disabled = true,
                isPercent = true,
                order = 7,
                get = getSavedCourseCompletion
            },
            blank__ = {order = 8, type = "description", name = "\n\n"},
            options = {name = "Options", type = "header", order = 9},
            setactivecourse = {
                name = "Set As Active Course",
                desc = "Set this course as active to run or edit the course.",
                type = "execute",
                width = "full",
                disabled = Bind(WorldOfParkour, "isActiveCourse"),
                func = setActiveCourse,
                order = 10
            },
            blank___ = {order = 11, type = "description", name = "\n"},
            copycourse = {
                name = "Copy Course",
                desc = "Create a copy of this course",
                type = "execute",
                func = CopyCourse,
                width = "full",
                order = 12
            },
            blank____ = {order = 13, type = "description", name = "\n\n"},
            removecourse = {
                name = "Remove Course",
                desc = "Permanently delete this course",
                confirm = true,
                confirmText = "Are you sure you want to delete this course?",
                type = "execute",
                func = removeCourse,
                width = "full",
                order = 14
            },
            blank_____ = {order = 15, type = "description", name = "\n\n"},
            showcoursestring = {
                name = "Show sharable course string",
                desc = "Show a string that can be used to share your course with friends.",
                type = "toggle",
                set = setToggleCourseString,
                get = getToggleCourseString,
                width = "double",
                order = 16
            },
            createcoursestring = {
                name = "Sharable Course String",
                desc = "Send this string to your friends so they can try your course.",
                type = "input",
                hidden = displayCourseString,
                multiline = true,
                width = "full",
                order = 17,
                get = getSharableString
            }
        }
    }
end

function CopyCourse(info)
    local courseId = findCourseIdRecursive(info)
    local savedCourse = WorldOfParkour.savedCoursesStore.savedcourses[courseId]
    local savedCourseCopy = Deepcopy(savedCourse)
    -- New UUID because we just made a copy of an existing course.
    local uuid = UUID()
    savedCourseCopy.id = uuid
    savedCourseCopy.title = savedCourseCopy.title .. " Copy"
    savedCourseCopy.lastmodifieddate = date("%m/%d/%y %H:%M:%S")
    -- Reset metadata
    savedCourseCopy.metadata = WorldOfParkour:CreateNewCourseMetadata()
    WorldOfParkour:ResetCourseCompletion(savedCourseCopy)
    -- Insert
    WorldOfParkour:InsertToSavedCourses(savedCourseCopy)
    -- Add course to GUI
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[uuid] = createSavedCourseGUI()
    -- Select the new course once its been created.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, uuid)
end

local function addNewCourse()
    local newCourseDefaults = WorldOfParkour:NewCourseDefaults()
    WorldOfParkour:InsertToSavedCourses(newCourseDefaults)
    local newCourseGUI = createSavedCourseGUI()

    -- Add course to GUI
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[newCourseDefaults.id] = newCourseGUI
    -- Select the new course once its been created.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, newCourseDefaults.id)
end

function ImportAndAddToGUI(courseString)
    local courseId = WorldOfParkour:ImportSharableString(courseString)
    -- Add course to GUI
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[courseId] = createSavedCourseGUI()
    return courseId
end

local function getImportCourseString() return WorldOfParkour.importCourseString end

local function setImportCourseString(info, courseString)
    WorldOfParkour.importCourseString = courseString
    local courseId = ImportAndAddToGUI(courseString)
    -- Select the imported course once its been created.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, courseId)
end

function WorldOfParkour:GenerateOptions()
    local options = {
        name = "World Of Parkour",
        type = "group",
        args = {
            newcourse = {
                name = "New Course",
                desc = "Create a new parkour course",
                type = "execute",
                func = addNewCourse
            },
            activecourse = {
                name = "Active Course",
                type = "group",
                desc = "Can only have 1 active course at a time." ..
                    "\n\nChoose an active course from the All Courses list.",
                args = {
                    noactive = {
                        name = "No Active Course Selected",
                        type = "group",
                        hidden = Bind(WorldOfParkour, "isActiveCourse"),
                        disabled = true,
                        args = {}
                    }
                    -- Active course will go here.
                }
            },
            courselist = {
                name = "All Courses",
                type = "group",
                desc = "Selection of parkour courses to set as active.",
                args = {
                    search = {
                        name = "Search for Course",
                        type = "input",
                        get = getCourseSearch,
                        set = setCourseSearch,
                        order = 1
                    },
                    clearsearch = {
                        name = "Clear",
                        desc = "Clear the search box",
                        type = "execute",
                        width = "half",
                        order = 2,
                        func = clearCourseSearch
                    },
                    blank_ = {order = 3, type = "description", name = "\n\n"},
                    importcourse = {
                        name = "Import course",
                        desc = "Paste a course string into the input box below to import it.",
                        type = "input",
                        multiline = true,
                        width = "full",
                        get = getImportCourseString,
                        set = setImportCourseString,
                        order = 4
                    }
                    -- All courses go here
                }
            }
        }
    }

    -- Load stored courses.
    for id, _ in pairs(self.savedCoursesStore.savedcourses) do
        options.args.courselist.args[id] = createSavedCourseGUI()
    end

    return options
end

function WorldOfParkour:CreateGUI()
    -- Reset the GUI options back to defaults, because we need to recreate it on reload.
    self.GUIoptionsDB:ResetDB()
    -- self.activeCourseDB:ResetDB()
    -- self.savedCoursesDB:ResetDB()
    AceConfig:RegisterOptionsTable("WorldOfParkour", self.GUIoptionsStore.options)
    AceConfigDialog:SetDefaultSize("WorldOfParkour", 800, 600)
    local f = function() AceConfigDialog:Open("WorldOfParkour") end

    -- Load last active course
    if WorldOfParkour:isActiveCourse() then
        local lastActiveCourseId = WorldOfParkour.activeCourseStore.activecourse.id
        WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[lastActiveCourseId] =
            createActiveCourseGUI()
    end

    self:RegisterChatCommand("parkour", f)
    self:RegisterChatCommand("wop", f)
end
