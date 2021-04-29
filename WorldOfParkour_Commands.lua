local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local _, addon = ...
local errors = addon.errors

--[[-------------------------------------------------------------------
--  Define Slash commands
-------------------------------------------------------------------]] --
local function setPointCmd()
    if WorldOfParkour:IsNotActiveCourse() then errors.notInActiveModeError() end
    WorldOfParkour:SetPoint()
    -- Notify changes to GUI
    AceConfigRegistry:NotifyChange("WorldOfParkour")
end

local function setPointAfterCmd(args)
    if WorldOfParkour:IsNotActiveCourse() then errors.notInActiveModeError() end
    local afterIdx = WorldOfParkour:GetArgs(args, 1)
    if not afterIdx then WorldOfParkour:Error("setPointAfterCmd(args): Point index is required.") end

    -- Input must be a number
    if not tonumber(afterIdx) then
        WorldOfParkour:Error("Input to /setpointafter must be a number. " .. "'" .. afterIdx .. "'" ..
                                 " is not a number.")
    end

    WorldOfParkour:SetPoint(tonumber(afterIdx) + 1)
    -- Notify changes to GUI
    AceConfigRegistry:NotifyChange("WorldOfParkour")
end

function WorldOfParkour:SetPoint(idx)
    -- Default idx to the next available waypoint position.
    idx = idx or #WorldOfParkour.activeCourseStore.activecourse.course + 1

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(idx)

    -- Add point to GUI
    local activeCourseGUI = WorldOfParkour.GUIoptionsStore.options.args.activecourse.args
    for id, _ in pairs(activeCourseGUI) do
        -- Find the active course, there will only be 1.
        if string.match(id, self.uuidPattern) then ReloadPointsToGUI(id) end
    end
end

WorldOfParkour:RegisterChatCommand("wopsetpoint", setPointCmd)
WorldOfParkour:RegisterChatCommand("wopsetpointafter", setPointAfterCmd)
-- WorldOfParkour:RegisterChatCommand("reset", "ResetMemory")
