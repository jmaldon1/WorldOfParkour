local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local function createBlizzOptions()
    return {
        about = {
            order = 1,
            name = "Create parkour courses around the world and share them with friends.",
            type = "description",
        },
        blank = {order = 2, type = "description", name = "\n\n\n"},
        help = {
            order = 3,
            type = "description",
            name = "Account wide settings for the WorldOfParkour addon."
        },
        blank_ = {order = 4, type = "description", name = "\n"},
        resetheader = {order = 5, type = "header", name = "Master Addon Tools"},
        resetbutton = {
            order = 6,
            type = "execute",
            name = "Reset WorldOfParkour Addon",
            desc = "If a WorldOfParkour addon is behaving oddly, this wipes all saved state across all characters. Log out and back in again to complete the reset.",
            confirm = true,
            width = "full",
            func = function()
                AceConfigDialog:Close("WorldOfParkour")
                if WorldOfParkour:isActiveCourse() then
                    WorldOfParkour:RemoveAllTomTomWaypoints()
                end
                WorldOfParkour.activeCourseStore.activecourse.course = {}
                WorldOfParkour.activeCourseDB:ResetProfile()
                WorldOfParkour.activeCourseDB:ResetDB()
                WorldOfParkour.savedCoursesDB:ResetDB()
                WorldOfParkour:OnInitialize()
            end
        },
        blank__ = {order = 7, type = "description", name = "\n\n"},
        githubheader = {order = 8, type = "header", name = "Github"},
        githubdesc = {
            order = 9,
            name = "If you would like to see the code for those addon, report a bug, or request a feature use the following links.",
            type = "description"
        },
        githublink = {
            order = 10,
            name = "Github",
            desc = "Addon code repository",
            type = "input",
            width = 1.7,
            get = function() return WorldOfParkour.github end,
            set = function() return WorldOfParkour.github end
        },
        githubissueslink = {
            order = 11,
            name = "Github issues",
            desc = "Report bugs and request features",
            type = "input",
            width = 1.7,
            get = function() return WorldOfParkour.githubIssues end,
            set = function() return WorldOfParkour.githubIssues end
        }
    }
end

local function createBlizzOptionsGUI()
    AceConfig:RegisterOptionsTable("WorldOfParkour-Bliz", {
        name = "WorldOfParkour",
        type = "group",
        args = createBlizzOptions()
    })
    AceConfigDialog:AddToBlizOptions("WorldOfParkour-Bliz", "WorldOfParkour")

    -- Profile Options
    AceConfig:RegisterOptionsTable("Active Course Profile",
                                   AceDBOptions:GetOptionsTable(
                                       WorldOfParkour.activeCourseDB))
    AceConfigDialog:AddToBlizOptions("Active Course Profile",
                                     "Active Course Profiles", "WorldOfParkour")
    -- Profile Options
    AceConfig:RegisterOptionsTable("Saved Courses Profile",
                                   AceDBOptions:GetOptionsTable(
                                       WorldOfParkour.savedCoursesDB))
    AceConfigDialog:AddToBlizOptions("Saved Courses Profile",
                                     "Saved Courses Profiles", "WorldOfParkour")
end

function WorldOfParkour:CreateConfig() createBlizzOptionsGUI() end
