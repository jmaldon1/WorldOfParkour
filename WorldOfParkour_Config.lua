local AceConfig = LibStub("AceConfig-3.0")
local AceDiaglog = LibStub("AceConfigDialog-3.0")

local function createBlizzOptions()
    local args = {
        help = {
            order = 0,
            type = "description",
            name = "Settings for the WorldOfParkour addon.",
        },
        blank = {
            order = 1,
            type = "description",
            name = " ",
        },
    }

    -- args = WoWPro.InsertActionDescriptions(args, 7)
    AceConfig:RegisterOptionsTable("WorldOfParkour-Bliz", {
        name = "WorldOfParkour",
        type = "group",
        args = args })
    -- AceDiaglog:SetDefaultSize("WorldOfParkour-Bliz", 600, 400)
    AceDiaglog:AddToBlizOptions("WorldOfParkour-Bliz", "WorldOfParkour")
end

function WorldOfParkour:CreateConfig()
    createBlizzOptions()
end
