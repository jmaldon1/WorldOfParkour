--[[-------------------------------------------------------------------
--  Define Slash commands
-------------------------------------------------------------------]] --
local function setPointCmd(args)
    if WorldOfParkour:isNotActiveCourse() then NotInActiveModeError() end
    local idx = WorldOfParkour:GetArgs(args, 1)

    -- Input must be nil or a number
    if idx ~= nil and not tonumber(idx) then
        error("Input to /setpoint must be a number. " .. "'" .. idx .. "'" ..
                    " is not a number.")
    end

    SetPoint(tonumber(idx))
    -- Notify changes to GUI
    AceConfigRegistry:NotifyChange("WorldOfParkour")
end

local function setPointAfterCmd(args)
    if WorldOfParkour:isNotActiveCourse() then NotInActiveModeError() end
    local afterIdx = WorldOfParkour:GetArgs(args, 1)
    if not afterIdx then error("setPointAfterCmd(args): Point index is required.") end

    -- Input must be a number
    if not tonumber(afterIdx) then
        error("Input to /setpointafter must be a number. " .. "'" .. afterIdx .. "'" ..
                    " is not a number.")
    end

    SetPoint(tonumber(afterIdx) + 1)
    -- Notify changes to GUI
    AceConfigRegistry:NotifyChange("WorldOfParkour")
end

function SetPoint(idx)
    -- Default idx to the next available waypoint position.
    idx = idx or #WorldOfParkour.activeCourseStore.activecourse.course + 1

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(idx)

    -- Add point to GUI
    local uuidPattern = "%w+-%w+-4%w+-%w+-%w+"
    local activeCourseGUI = WorldOfParkour.GUIoptionsStore.options.args.activecourse
                           .args
    for k, _ in pairs(activeCourseGUI) do
        -- Find the active course, there will only be 1.
        if string.match(k, uuidPattern) then
            ReloadPointsToGUI(k)
        end
    end
end

WorldOfParkour:RegisterChatCommand("wopsetpoint", setPointCmd)
WorldOfParkour:RegisterChatCommand("wopsetpointafter", setPointAfterCmd)
-- WorldOfParkour:RegisterChatCommand("reset", "ResetMemory")
