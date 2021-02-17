local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
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

local function findSavedCourseKeyById(savedCourses, id)
    for k, v in ipairs(savedCourses) do if v.id == id then return k end end
end

local function enableEditMode()
    WorldOfParkour.activeCourseStore.isInEditMode = true
end

local function disableEditMode()
    WorldOfParkour.activeCourseStore.isInEditMode = false
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

local function selectCourse(courseId)
    AceConfigDialog:SelectGroup("WorldOfParkour", "courselist", courseId)
end

local function setEditableCourseTitle(info, title)
    WorldOfParkour.activeCourseStore.activecourse.title = title
end

local function getEditableCourseTitle()
    return WorldOfParkour.activeCourseStore.activecourse.title
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
    local course =
        WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return course.hint
end

local function getPointName(info)
    local pointKey = tonumber(info[#info])
    local coursePoint =
        WorldOfParkour.activeCourseStore.activecourse.course[pointKey]
    return coursePoint.uid.title
end

local function getPointOrder(info) return tonumber(info[#info]) end

--[[-------------------------------------------------------------------
--  GUI Options
-------------------------------------------------------------------]] --
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
                width = "double",
                get = getHint,
                set = setHint
            }
        }
    }
end

local function addNewPoint(info)
    local courseId = findCourseIdRecursive(info)
    SetPoint("")
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

function CreatePointsListGUI()
    return {
        addpoint = {
            name = "Add point",
            desc = "Add point to course",
            type = "execute",
            func = addNewPoint
        }
        -- All points go here
    }
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
                    unsetactivecourse = {
                        name = "Unset Active Course",
                        desc = "Remove this course from Active Course." ..
                            "\n\nIf you edited this course, press this to save your changes.",
                        type = "execute",
                        width = "full",
                        func = unsetActiveCourse
                    }
                }
            },
            tabedit = {
                name = "edit",
                type = "group",
                order = 2,
                args = {
                    title = {
                        name = "Course Name",
                        validate = validateCourseTitle,
                        desc = "Set the title of the course",
                        type = "input",
                        order = 1,
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        set = setEditableCourseTitle,
                        get = getEditableCourseTitle
                    },
                    editcourse = {
                        name = "Edit Course",
                        desc = "Edit the course",
                        type = "execute",
                        disabled = Bind(WorldOfParkour, "isInEditMode"),
                        width = 0.85,
                        order = 2,
                        func = enableEditMode
                    },
                    pointslist = {
                        name = "Course Points",
                        type = "group",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        -- inline = true,
                        order = 3,
                        -- args = {}
                        args = CreatePointsListGUI()
                        -- args = {
                        --     editcourse = {
                        --         name = "Add point",
                        --         desc = "Add point to course",
                        --         type = "execute"
                        --         -- func = removeCourse
                        --     },
                        --     point = {name = "Point1", type = "group", args = {}},
                        --     point_two = {
                        --         name = "Point2",
                        --         type = "group",
                        --         args = {}
                        --     }
                        -- }
                    }
                }
            },
            taboptions = {
                name = "options",
                type = "group",
                order = 3,
                args = {
                    editcourse = {
                        name = "Exit course editing without saving",
                        desc = "Rollback all changes made while editing this course.",
                        type = "execute",
                        width = "double",
                        disabled = Bind(WorldOfParkour, "isNotInEditMode"),
                        order = 2,
                        func = ExitWithoutSaving
                    }
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

local function isCoursesDifferent(courseA, courseB)
    if #courseA ~= #courseB then return true end

    local courseAIds = {}
    local courseBIds = {}

    for _, coursePoint in pairs(courseA) do
        table.insert(courseAIds, TomTom:GetKey(coursePoint.uid))
    end
    for _, coursePoint in pairs(courseB) do
        table.insert(courseBIds, TomTom:GetKey(coursePoint.uid))
    end

    if #Difference(courseAIds, courseBIds) == 0 then return false end
    return true
end

function ExitWithoutSaving()
    local backupActiveCourse = WorldOfParkour.activeCourseStore
                                   .backupActivecourse
    local courseId = WorldOfParkour.activeCourseStore.activecourse.id
    local backupActiveCourseCopy = Deepcopy(backupActiveCourse)
    local isCoursesDiff = isCoursesDifferent(
                              WorldOfParkour.activeCourseStore.activecourse
                                  .course, backupActiveCourse.course)
    if isCoursesDiff then
        WorldOfParkour:RemoveAllTomTomWaypoints()
    end

    ReplaceTable(backupActiveCourseCopy,
                 WorldOfParkour.activeCourseStore.activecourse)
    -- Reset ActiveCourse GUI
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] =
        createActiveCourseGUI()

    if isCoursesDiff and not #backupActiveCourse.course == 0 then
        -- Only sync if the user made changes to the course points
        -- and the backup has more than 0 points.
        WorldOfParkour:SyncWithTomTomDB()
    end
    -- Turn off editing mode.
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
    local savedCourseCopyBackup = Deepcopy(savedCourse)
    -- WorldOfParkour.activeCourseStore.activecourse = savedCourseCopy
    -- WorldOfParkour.activeCourseStore.backupActivecourse = savedCourseCopyBackup
    ReplaceTable(savedCourseCopy, WorldOfParkour.activeCourseStore.activecourse)
    ReplaceTable(savedCourseCopyBackup,
                 WorldOfParkour.activeCourseStore.backupActivecourse)
    WorldOfParkour.GUIoptionsStore.options.args.activecourse.args[courseId] =
        createActiveCourseGUI()
    enableActiveCourse()

    -- Add TomTom waypoints to screen.
    if #savedCourse.course ~= 0 then
        WorldOfParkour:ReloadActiveCourse()
    end
    WorldOfParkour:ScheduleTimer(selectActiveCourse, 0, courseId)
end

local function createSavedCourseGUI()
    return {
        name = getCourseTitle,
        desc = getCourseDescription,
        type = "group",
        disabled = disableActiveCourseFromAllCourses,
        args = {
            titleheader = {name = getCourseTitle, type = "header", order = 1},
            description = {
                name = getCourseDescription,
                type = "description",
                order = 2
            },
            setactivecourse = {
                name = "Set As Active Course",
                desc = "Edit the course",
                type = "execute",
                width = "full",
                disabled = Bind(WorldOfParkour, "isActiveCourse"),
                func = setActiveCourse,
                order = 3
            },
            blank = {order = 4, type = "description", name = "\n\n"},
            removecourse = {
                name = "Remove Course",
                desc = "Permanently delete this course",
                confirm = true,
                confirmText = "Are you sure you want to delete this course?",
                type = "execute",
                func = removeCourse,
                width = "full",
                order = 5
            }
        }
    }
end

local function addNewCourse()
    local newCourseDefaults = WorldOfParkour:NewCourseDefaults()
    table.insert(WorldOfParkour.savedCoursesStore.savedcourses,
                 newCourseDefaults)
    local newCourse = createSavedCourseGUI()

    WorldOfParkour.GUIoptionsStore.options.args.courselist.args[newCourseDefaults.id] =
        newCourse
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
                desc = "Can only have 1 active course at a time.",
                args = {
                    noactive = {
                        name = "No Active Course Selected",
                        type = "group",
                        hidden = Bind(WorldOfParkour, "isActiveCourse"),
                        disabled = true,
                        args = {}
                    }
                }
            },
            courselist = {
                name = "All Courses",
                type = "group",
                desc = "Selection of parkour courses to set as active.",
                args = {
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
