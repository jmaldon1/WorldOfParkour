local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local _, addon = ...
local utils = addon.utils
local errors = addon.errors

--[[-------------------------------------------------------------------
--  Dropdown menu code
-------------------------------------------------------------------]] --
local dropdown = CreateFrame("Frame", "TomTomDropdown", nil, "UIDropDownMenuTemplate")

local function completePoint(uid)
    local idx = utils.getCoursePointIndex(uid)
    local activeCourse = WorldOfParkour.activeCourseStore.activecourse.course
    activeCourse[idx].completed = true
    -- Check if the user is at the last point in the course.
    if idx ~= #activeCourse then
        -- Set crazy arrow to the next point in the course.
        local nextUid = activeCourse[idx + 1].uid
        TomTom:SetCrazyArrow(nextUid, WorldOfParkour.arrivalDistance, nextUid.title)
    else
        -- This is the final waypoint.
        WorldOfParkour.activeCourseStore.activecourse.metadata.isComplete = true
    end
    TomTom:RemoveWaypoint(uid)
    -- Notify that a point as been completed
    AceConfigRegistry:NotifyChange("WorldOfParkour")
end

local dropdown_info = {
    -- Define level one elements here
    [1] = {
        { -- Title
            text = "WorldOfParkour Point Options",
            isTitle = 1
        }, {
            -- set as crazy arrow
            text = "Set as waypoint arrow",
            func = function()
                if WorldOfParkour:isNotInEditMode() then errors.notInEditModeError() end
                local uid = dropdown.uid
                local data = uid
                TomTom:SetCrazyArrow(uid, WorldOfParkour.arrivalDistance, data.title or "TomTom waypoint")
            end
        },
        { -- Add previous point, can be used if the user needs to recomplete the previous point for any reason.
            text = "Show previous point",
            func = function()
                -- Don't clear if we are in edit mode.
                if WorldOfParkour:isInEditMode() then errors.inEditModeError() end
                local uid = dropdown.uid
                local nextUncompletedPoint = WorldOfParkour:GetNextUncompletedPoint()
                if TomTom:GetKey(uid) ~= TomTom:GetKey(nextUncompletedPoint) then
                    error("The previous point is already shown.")
                end

                local idx = utils.getCoursePointIndex(uid)
                local lastIdx = idx - 1
                if lastIdx == 0 then error("You are already at the first point!") end
                local activeCourse = WorldOfParkour.activeCourseStore.activecourse.course
                local lastUid = activeCourse[lastIdx].uid
                local m, x, y, options = WorldOfParkour:CreateTomTomWaypointArgs(lastUid)
                local newLastUid = TomTom:AddWaypoint(m, x, y, options)
                -- Uncomplete the last point
                WorldOfParkour.activeCourseStore.activecourse.course[lastIdx].completed = false
                TomTom:SetCrazyArrow(newLastUid, WorldOfParkour.arrivalDistance, newLastUid.title)
                AceConfigRegistry:NotifyChange("WorldOfParkour")
            end
        }, { -- Remove waypoint
            text = "Remove waypoint",
            func = function()
                if WorldOfParkour:isNotInEditMode() then errors.notInEditModeError() end
                local uid = dropdown.uid
                WorldOfParkour:RemoveWaypointAndReorder(uid)
                AceConfigRegistry:NotifyChange("WorldOfParkour")

                -- TomTom:Printf("Removing waypoint %0.2f, %0.2f in %s", data.x, data.y, data.zone)
            end
        },
        { -- Complete point, can be used if TomTom is being weird and not clearing the waypoint automatically.
            text = "Complete point",
            func = function()
                -- Don't clear if we are in edit mode.
                if WorldOfParkour:isInEditMode() then errors.inEditModeError() end

                local uid = dropdown.uid
                -- Dont clear if it is not the next waypoint.
                local nextUncompletedPoint = WorldOfParkour:GetNextUncompletedPoint()
                if TomTom:GetKey(uid) ~= TomTom:GetKey(nextUncompletedPoint) then
                    error("Complete the previous points first.")
                end

                if TomTom:GetDistanceToWaypoint(uid) > WorldOfParkour.arrivalDistance then
                    error("You need to be closer to complete this point.")
                end
                completePoint(uid)
            end
        }, { -- Show hint
            text = "Show hint",
            func = function()
                local uid = dropdown.uid
                local title = uid.title
                local idx = utils.getCoursePointIndex(uid)
                local coursePoint = WorldOfParkour.activeCourseStore.activecourse.course[idx]
                WorldOfParkour:Printf("Hint for %s: %s", title, coursePoint.hint)
            end
        }
    }
}

local function init_dropdown(level)
    -- Make sure level is set to 1, if not supplied
    level = 1

    -- Get the current level from the info table
    local info = dropdown_info[level]

    -- If a value has been set, try to find it at the current level
    if level > 1 and UIDROPDOWNMENU_MENU_VALUE then
        if info[UIDROPDOWNMENU_MENU_VALUE] then info = info[UIDROPDOWNMENU_MENU_VALUE] end
    end

    -- Add the buttons to the menu
    for idx, entry in ipairs(info) do
        if type(entry.checkeda) == "function" then
            -- Make this button dynamic
            local new = {}
            for k, v in pairs(entry) do new[k] = v end
            new.checked = new.checked()
            entry = new
        else
            entry.checked = nil
        end

        UIDropDownMenu_AddButton(entry, level)
    end
end

function InitializeDropdown(uid)
    dropdown.uid = uid
    UIDropDownMenu_Initialize(dropdown, init_dropdown)
end

--[[-------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------]] --

local function _both_onclick(event, uid, self, button)
    InitializeDropdown(uid)
    _G.ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

local function _both_clear_distance(event, uid, range, distance, lastdistance)
    -- Don't clear if we are in edit mode.
    if WorldOfParkour:isInEditMode() then return end
    -- Dont clear if it is not the next waypoint.
    local nextUncompletedPoint = WorldOfParkour:GetNextUncompletedPoint()
    if TomTom:GetKey(uid) ~= TomTom:GetKey(nextUncompletedPoint) then return end
    -- Only clear the waypoint if we weren't inside it when it was set
    if lastdistance and not UnitOnTaxi("player") then completePoint(uid) end
end

function WorldOfParkour:CreateTomTomCallbacks()
    local defaultCallbacks = TomTom:DefaultCallbacks()

    local callbacks = {
        minimap = {
            onclick = _both_onclick,
            tooltip_show = defaultCallbacks.minimap.tooltip_show,
            tooltip_update = defaultCallbacks.minimap.tooltip_update
        },
        world = {
            onclick = _both_onclick,
            tooltip_show = defaultCallbacks.world.tooltip_show,
            tooltip_update = defaultCallbacks.world.tooltip_update
        },
        distance = {
            -- This table is indexed by distance, so the Key is the distance to clear the waypoint.
            [self.clearDistance] = function(...) _both_clear_distance(...); end
        }
    }
    return callbacks
end
