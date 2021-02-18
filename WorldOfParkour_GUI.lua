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
        TomTom:SetCrazyArrow(course[1].uid, WorldOfParkour.arrivalDistance,
                             course[1].uid.title)
    elseif option == "last" then
        TomTom:SetCrazyArrow(course[#course].uid, WorldOfParkour.arrivalDistance,
                             course[#course].uid.title)
    else
        error("Input must be either {'first', 'last'}")
    end
end

local function findSavedCourseKeyById(savedCourses, id)
    for k, v in ipairs(savedCourses) do if v.id == id then return k end end
end

local function enableEditMode()
    -- Reset the course completion before editing.
    WorldOfParkour:ResetCourseCompletion()
    WorldOfParkour.activeCourseStore.isInEditMode = true
    SetCrazyArrowToFirstOrLastPoint("last")
end

local function disableEditMode()
    WorldOfParkour.activeCourseStore.isInEditMode = false
    SetCrazyArrowToFirstOrLastPoint("first")
end

local function enableActiveCourse()
    WorldOfParkour.activeCourseStore.isActiveCourse = true
end

local function disableActiveCourse()
    WorldOfParkour.activeCourseStore.isActiveCourse = false
end

local function removeCourse(info, action)
    local courseId = findCourseIdRecursive(info)
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    table.remove(WorldOfParkour.savedCoursesStore.savedcourses, courseKey)
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[courseId] = nil
end

local function selectActiveCourse(courseId)
    AceConfigDialog:SelectGroup("WorldOfParkour", "activecourse", courseId)
end

local function selectPoint(ids)
    local courseId = ids.courseId
    local pointId = ids.pointId
    AceConfigDialog:SelectGroup("WorldOfParkour", "activecourse", courseId,
                                "tabedit", "pointslist", pointId)
end

local function selectCourse(courseId)
    AceConfigDialog:SelectGroup("WorldOfParkour", "courselist", courseId)
end

local function getEditableCourseTitle()
    return WorldOfParkour.activeCourseStore.activecourse.title
end

local function setEditableCourseTitle(info, title)
    WorldOfParkour.activeCourseStore.activecourse.title = title
end

local function getEditableCourseDescription()
    return WorldOfParkour.activeCourseStore.activecourse.description
end

local function setEditableCourseDescription(info, description)
    WorldOfParkour.activeCourseStore.activecourse.description = description
end

local function disableActiveCourseFromAllCourses(info)
    local courseId = findCourseIdRecursive(info)
    local activeCourse = WorldOfParkour.GUIoptionsStore.options.args
                             .activecourse.args[courseId]
    if activeCourse then return true end
    return false
end

local function unsetActiveCourse(info)
    local courseId = findCourseIdRecursive(info)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    -- Remove waypoints from screen.
    WorldOfParkour:RemoveAllTomTomWaypoints()

    disableEditMode()
    disableActiveCourse()

    -- Replace the old course with the active course.
    ReplaceTable(activeCourse,
                 WorldOfParkour.savedCoursesStore.savedcourses[courseKey])

    -- Clear some state
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] =
        nil
    WorldOfParkour.activeCourseStore.activecourse = {}
    WorldOfParkour.activeCourseStore.backupActivecourse = {}

    -- Select the unset course from the course list.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, courseId)
end

local function getCourseTitle(info)
    local courseId = findCourseIdRecursive(info)
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    return WorldOfParkour.savedCoursesStore.savedcourses[courseKey].title
end

local function getCourseDescription(info)
    local courseId = findCourseIdRecursive(info)
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    return WorldOfParkour.savedCoursesStore.savedcourses[courseKey].description
end

local function validateCourseTitle(info, val)
    if string.len(val) == 0 then
        return "Course Name: Course name is too short"
    end
    return true
end

local function setHint(info, hint)
    local pointKey = tonumber(info[#info - 1])
    WorldOfParkour.activeCourseStore.activecourse.course[pointKey].hint = hint
end

local function getHint(info)
    local pointKey = tonumber(info[#info - 1])
    local coursePoint =
        WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return coursePoint.hint
end

local function getPointName(info)
    local pointKey = tonumber(info[#info])
    local coursePoint =
        WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return coursePoint.uid.title
end

local function getPointOrder(info) return tonumber(info[#info]) end

local function getCourseSearch() return WorldOfParkour.courseSearch end

local function displayMatchingCourses(courseStartsWith)
    -- Hide courses that do not match the search criteria
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    local courseList = WorldOfParkour.GUIoptionsStore.options.args.courselist
                           .args
    for k, v in pairs(courseList) do
        -- Only check courses (We know its a course by the pattern of their table key)
        if string.match(k, uuidPattern) then
            local savedCourses = WorldOfParkour.savedCoursesStore.savedcourses
            local courseKey = findSavedCourseKeyById(savedCourses, k)
            local courseName = savedCourses[courseKey].title
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
    local coursePoint =
        WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
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
            blankone = {order = 2, type = "description", name = "\n"},
            addpointafter = {
                name = "Add point after",
                desc = "Adds a point after this one.",
                type = "execute",
                width = 0.85,
                order = 2,
                func = addPointAfter
            },
            blanktwo = {order = 3, type = "description", name = "\n\n\n\n"},
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
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId].args
        .tabedit.args.pointslist.args = CreatePointsListGUI()

    -- Regenerate all points again on the GUI
    -- This is done because the points are always being reordered.
    for k, _ in pairs(WorldOfParkour.activeCourseStore.activecourse.course) do
        WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId]
            .args.tabedit.args.pointslist.args[tostring(k)] = createPointGUI()
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

local function isCoursePointsDifferent(courseAPoints, courseBPoints)
    if #courseAPoints ~= #courseBPoints then return true end

    local courseAPointIds = {}
    local courseBPointIds = {}

    for _, coursePoint in pairs(courseAPoints) do
        table.insert(courseAPointIds, TomTom:GetKey(coursePoint.uid))
    end
    for _, coursePoint in pairs(courseBPoints) do
        table.insert(courseBPointIds, TomTom:GetKey(coursePoint.uid))
    end

    if #Difference(courseAPointIds, courseBPointIds) == 0 then return false end
    return true
end

local function isCourseDetailsDifferent(courseA, courseB)
    for detailName, detail in pairs(courseA) do
        -- Skip the course points
        if detailName ~= "course" then
            if courseB[detailName] ~= detail then return true end
        end
    end
    return false
end

local function disableUndo()
    -- If we are not in editing mode, disable button.
    if WorldOfParkour:isNotInEditMode() then return true end
    local backupActiveCourse = WorldOfParkour.activeCourseStore
                                   .backupActivecourse
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local isCoursePointsDiff = isCoursePointsDifferent(activeCourse.course,
                                                       backupActiveCourse.course)
    local isCourseDetailsDiff = isCourseDetailsDifferent(activeCourse,
                                                         backupActiveCourse)
    -- If courses are not different, disable button.
    return not isCoursePointsDiff and not isCourseDetailsDiff
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
                    range = {
                        name = "Course Completion",
                        desc = "complete",
                        type = "range",
                        width = "full",
                        min = 0,
                        max = 1,
                        disabled = true,
                        isPercent = true,
                        order = 1,
                        get = Bind(WorldOfParkour, "GetCourseCompletion")
                    },
                    blank = {order = 3, type = "description", name = "\n"},
                    unsetactivecourse = {
                        name = "Unset Active Course",
                        desc = "Remove this course from Active Course." ..
                            "\n\nIf you edited this course, this will save your changes.",
                        type = "execute",
                        width = "full",
                        order = 4,
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
                        confirm = Bind(WorldOfParkour, "IsCourseBeingRun"),
                        confirmText = "Editing the course now will reset your completion progress. Are you sure?\n\n" ..
                        "If you would like to edit this course without losing your progress, make a copy and edit that.",
                        type = "execute",
                        disabled = Bind(WorldOfParkour, "isInEditMode"),
                        width = 0.85,
                        order = 1,
                        func = enableEditMode
                    },
                    blankone = {order = 2, type = "description", name = ""},
                    title = {
                        name = "Course Name",
                        validate = validateCourseTitle,
                        desc = "Set the title of the course",
                        type = "input",
                        order = 3,
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        set = setEditableCourseTitle,
                        get = getEditableCourseTitle
                    },
                    blanktwo = {order = 4, type = "description", name = ""},
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
                    pointslist = {
                        name = "Course Points",
                        type = "group",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        order = 6,
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
                        order = 5,
                        func = Bind(WorldOfParkour, "ResetCourseCompletion")
                    },
                }
            }
        }
    }

    -- Load already set points
    for k, _ in pairs(WorldOfParkour.activeCourseStore.activecourse.course) do
        activeCourse.args.tabedit.args.pointslist.args[tostring(k)] =
            createPointGUI()
    end

    return activeCourse
end

function ExitWithoutSaving()
    local backupActiveCourse = WorldOfParkour.activeCourseStore
                                   .backupActivecourse
    local courseId = WorldOfParkour.activeCourseStore.activecourse.id
    local backupActiveCourseCopy = Deepcopy(backupActiveCourse)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local isCoursePointsDiff = isCoursePointsDifferent(activeCourse.course,
                                                       backupActiveCourse.course)
    if isCoursePointsDiff then WorldOfParkour:RemoveAllTomTomWaypoints() end

    ReplaceTable(backupActiveCourseCopy,
                 WorldOfParkour.activeCourseStore.activecourse)
    -- Reset ActiveCourse GUI
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] =
        createActiveCourseGUI()

    if isCoursePointsDiff and not #backupActiveCourse.course == 0 then
        -- Only sync if the user made changes to the course points
        -- and the backup actually has points.
        WorldOfParkour:SyncWithTomTomDB()
    end
    -- Reload the TomTom waypoints.
    WorldOfParkour:ReloadActiveCourse()

    -- Turn off editing mode.
    disableEditMode()
end

function ExitWithSave(info)
    local courseId = findCourseIdRecursive(info)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    local backupActiveCourse = WorldOfParkour.activeCourseStore
                                   .backupActivecourse
    local activeCourseCopyOne = Deepcopy(activeCourse)
    local activeCourseCopyTwo = Deepcopy(activeCourse)

    -- Replace the old course with the active course.
    ReplaceTable(activeCourseCopyOne,
                 WorldOfParkour.savedCoursesStore.savedcourses[courseKey])
    -- Update the backup
    ReplaceTable(activeCourseCopyTwo, backupActiveCourse)

    disableEditMode()
end

local function setActiveCourse(info, action)
    local courseId = findCourseIdRecursive(info)
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    local savedCourse = WorldOfParkour.savedCoursesStore.savedcourses[courseKey]
    -- We need to make copies here because Lua passes around tables as reference.
    -- We do not want to edit the original table.
    local savedCourseCopy = Deepcopy(savedCourse)
    local savedCourseBackupCopy = Deepcopy(savedCourse)
    -- WorldOfParkour.activeCourseStore.activecourse = savedCourseCopy
    -- WorldOfParkour.activeCourseStore.backupActivecourse = savedCourseCopyBackup
    ReplaceTable(savedCourseCopy, WorldOfParkour.activeCourseStore.activecourse)
    ReplaceTable(savedCourseBackupCopy,
                 WorldOfParkour.activeCourseStore.backupActivecourse)
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] =
        createActiveCourseGUI()

    enableActiveCourse()
    -- Add TomTom waypoints to screen.
    if #savedCourse.course ~= 0 then WorldOfParkour:ReloadActiveCourse() end
    SetCrazyArrowToFirstOrLastPoint("first")

    WorldOfParkour:ScheduleTimer(selectActiveCourse, 0, courseId)
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
            description = {
                name = getCourseDescription,
                type = "description",
                order = 2
            },
            blank_ = {order = 3, type = "description", name = "\n\n"},
            setactivecourse = {
                name = "Set As Active Course",
                desc = "Edit the course",
                type = "execute",
                width = "full",
                disabled = Bind(WorldOfParkour, "isActiveCourse"),
                func = setActiveCourse,
                order = 4
            },
            blank__ = {order = 5, type = "description", name = "\n"},
            copycourse = {
                name = "Copy Course",
                desc = "Create a copy of this course",
                type = "execute",
                func = CopyCourse,
                width = "full",
                order = 6
            },
            blank___ = {order = 7, type = "description", name = "\n\n"},
            removecourse = {
                name = "Remove Course",
                desc = "Permanently delete this course",
                confirm = true,
                confirmText = "Are you sure you want to delete this course?",
                type = "execute",
                func = removeCourse,
                width = "full",
                order = 8
            }
        }
    }
end

function CopyCourse(info)
    local courseId = findCourseIdRecursive(info)
    local courseKey = findSavedCourseKeyById(
                          WorldOfParkour.savedCoursesStore.savedcourses,
                          courseId)
    local newCourseGUI = createSavedCourseGUI()
    local savedCourse = WorldOfParkour.savedCoursesStore.savedcourses[courseKey]
    local savedCourseCopy = Deepcopy(savedCourse)
    local uuid = UUID()
    savedCourseCopy.id = uuid
    savedCourseCopy.title = savedCourseCopy.title .. " Copy"
    table.insert(WorldOfParkour.savedCoursesStore.savedcourses, savedCourseCopy)
    -- Add course to GUI
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[uuid] =
        newCourseGUI
    -- Select the new course once its been created.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, uuid)
end

local function addNewCourse()
    local newCourseDefaults = WorldOfParkour:NewCourseDefaults()
    table.insert(WorldOfParkour.savedCoursesStore.savedcourses,
                 newCourseDefaults)
    local newCourseGUI = createSavedCourseGUI()

    -- Add course to GUI
    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[newCourseDefaults.id] =
        newCourseGUI
    -- Select the new course once its been created.
    WorldOfParkour:ScheduleTimer(selectCourse, 0, newCourseDefaults.id)
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
                    }
                    -- All courses go here
                }
            }
        }
    }

    -- Load stored courses.
    for _, v in pairs(self.savedCoursesStore.savedcourses) do
        options.args.courselist.args[v.id] = createSavedCourseGUI()
    end

    return options
end

function WorldOfParkour:CreateGUI()
    -- Reset the GUI options back to defaults, because we need to recreate it on reload.
    self.GUIoptionsDB:ResetDB()
    -- self.activeCourseDB:ResetDB()
    -- self.savedCoursesDB:ResetDB()
    AceConfig:RegisterOptionsTable("WorldOfParkour",
                                   self.GUIoptionsStore.options)

    -- AceConfigRegistry:RegisterCallback("ConfigTableChange", test)
    local f = function() AceConfigDialog:Open("WorldOfParkour") end

    -- Load last active course
    if WorldOfParkour:isActiveCourse() then
        local lastActiveCourseId = WorldOfParkour.activeCourseStore.activecourse
                                       .id
        WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[lastActiveCourseId] =
            createActiveCourseGUI()
    end

    self:RegisterChatCommand("parkour", f)
    self:RegisterChatCommand("wop", f)
end
