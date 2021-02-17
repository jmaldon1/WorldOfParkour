--[[-------------------------------------------------------------------
--  Define Slash commands
-------------------------------------------------------------------]] --
function SetPoint(args)
    if WorldOfParkour:isNotActiveCourse() then NotInActiveModeError() end
    local idx = WorldOfParkour:GetArgs(args, 1)
    -- Default idx to the next available waypoint position.
    idx = idx or #WorldOfParkour.activeCourseStore.activecourse.course + 1

    -- Check if input is a number
    if not (tonumber(idx)) then
        error("Input to /setpoint must be a number. " .. "'" .. idx .. "'" ..
                    " is not a number.")
    end

    -- Check if user is trying to set a point that already exists
    local keys = TableKeys(WorldOfParkour.activeCourseStore.activecourse.course)
    local err_msg = "That point is already set, remove it first and try again."
    if SetContains(keys, tonumber(idx)) then error(err_msg); end

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(tonumber(idx))
end

local function setPointAfter(args)
    if WorldOfParkour:isNotActiveCourse() then NotInActiveModeError() end
    local afterIdx = WorldOfParkour:GetArgs(args, 1)
    if not afterIdx then return end

    -- Check if input is a number
    if not tonumber(afterIdx) then
        error("Input to /setpointafter must be a number. " .. "'" .. afterIdx ..
                    "'" .. " is not a number.")
    end

    WorldOfParkour:SetWaypointAtIndexOnCurrentPosition(tonumber(afterIdx) + 1)
end

WorldOfParkour:RegisterChatCommand("setpoint", SetPoint)
WorldOfParkour:RegisterChatCommand("setpointafter", setPointAfter)
WorldOfParkour:RegisterChatCommand("reset", "ResetMemory")
WorldOfParkour:RegisterChatCommand("resetc", "ClearSavedCourses")
