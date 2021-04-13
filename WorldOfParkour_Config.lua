local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local function createBlizzOptions()
    return {
        about = {
            order = 1,
            name = "Create parkour courses around the world and share them with friends.",
            type = "description"
        },
        blank = {order = 2, type = "description", name = "\n\n\n"},
        help = {order = 3, type = "description", name = "Account wide settings for the WorldOfParkour addon."},
        quickstartheader = {order = 4, type = "header", name = "Quick Start"},
        quickstart = {order = 5, type = "description", name = "To open WorldOfParkour, type /wop or /parkour into your chat and hit enter."},
        blank_ = {order = 6, type = "description", name = "\n\n"},
        resetheader = {order = 8, type = "header", name = "Master Addon Tools"},
        resetbutton = {
            order = 9,
            type = "execute",
            name = "Reset WorldOfParkour Addon",
            desc = "If the WorldOfParkour addon is behaving oddly, this wipes all saved state across all characters. " ..
                "Log out and back in again to complete the reset. " ..
                "This will NOT reset your course backups!",
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
                WorldOfParkour.firstLoadDB:ResetDB()
                WorldOfParkour:OnInitialize()
            end
        },
        resetbackupbuttondesc = {
            order = 10,
            type = "description",
            name = "\n\nI recommend NOT resetting the Course Backup unless absolutely necessary. " ..
                "This backup can be used to recover your courses in the case of addon failure and an addon reset was required. " ..
                "\nHow to recover course strings: " .. "\n    1. Open the following path in a text editor (Notepad, VS code, Sublime Text editor, etc...): \n" ..
                "        `World of Warcraft\\_{retail, classic}_\\WTF\\Account\\{Account#}\\SavedVariables\\WorldOfParkour.lua`" ..
                "\n    2. Look for a key named `WoPBackupDB` and search for course strings that you would like to recover within it."
        },
        resetbackupbutton = {
            order = 11,
            type = "execute",
            name = "Reset WorldOfParkour Course Backup",
            desc = "Clears the course string backup",
            confirm = true,
            width = "full",
            func = function() WorldOfParkour.backupDB:ResetDB() end
        },
        blank__ = {order = 12, type = "description", name = "\n\n"},
        githubheader = {order = 13, type = "header", name = "Github"},
        githubdesc = {
            order = 14,
            name = "If you would like to see the code for those addon, report a bug, or request a feature use the following links.",
            type = "description"
        },
        githublink = {
            order = 15,
            name = "Github",
            desc = "Addon code repository",
            type = "input",
            width = 1.7,
            get = function() return WorldOfParkour.github end,
            set = function() return WorldOfParkour.github end
        },
        githubissueslink = {
            order = 16,
            name = "Github issues",
            desc = "Report bugs and request features",
            type = "input",
            width = 1.7,
            get = function() return WorldOfParkour.githubIssues end,
            set = function() return WorldOfParkour.githubIssues end
        },
        blank___ = {order = 17, type = "description", name = "\n\n"},
        twitchheader = {order = 18, type = "header", name = "Twitch"},
        twitchdesc = {
            order = 19,
            name = "Check me out on Twitch, always taking suggestions for new courses.",
            type = "description"
        },
        twitchlink = {
            order = 20,
            name = "Twitch",
            type = "input",
            width = 1.7,
            get = function() return WorldOfParkour.twitch end,
            set = function() return WorldOfParkour.twitch end
        }
    }
end

local function createBlizzOptionsGUI()
    AceConfig:RegisterOptionsTable("WorldOfParkour-Bliz",
                                   {name = "WorldOfParkour", type = "group", args = createBlizzOptions()})
    AceConfigDialog:AddToBlizOptions("WorldOfParkour-Bliz", "WorldOfParkour")

    -- Profile Options
    AceConfig:RegisterOptionsTable("Active Course Profile",
                                   AceDBOptions:GetOptionsTable(WorldOfParkour.activeCourseDB))
    AceConfigDialog:AddToBlizOptions("Active Course Profile", "Active Course Profiles", "WorldOfParkour")
end

function WorldOfParkour:CreateConfig() createBlizzOptionsGUI() end
