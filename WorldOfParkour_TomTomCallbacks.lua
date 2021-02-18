--[[-------------------------------------------------------------------
--  Dropdown menu code
-------------------------------------------------------------------]] --
local dropdown = CreateFrame("Frame", "TomTomDropdown", nil,
                             "UIDropDownMenuTemplate")

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
                local uid = dropdown.uid
                local data = uid
                TomTom:SetCrazyArrow(uid, TomTom.profile.arrow.arrival,
                                     data.title or "TomTom waypoint")
            end
        }, { -- Remove waypoint
            text = "Remove waypoint",
            func = function()
                local uid = dropdown.uid
                local data = uid
                WorldOfParkour:RemoveWaypointAndReorder(uid)
                AceConfigRegistry:NotifyChange("WorldOfParkour")

                -- TomTom:Printf("Removing waypoint %0.2f, %0.2f in %s", data.x, data.y, data.zone)
            end
        }, { -- Show hint
            text = "Show hint",
            func = function()
                local uid = dropdown.uid
                local title = uid.title
                local idx = GetCourseIndex(uid)
                local coursePoint = WorldOfParkour.activeCourseStore
                                        .activecourse.course[idx]
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
        if info[UIDROPDOWNMENU_MENU_VALUE] then
            info = info[UIDROPDOWNMENU_MENU_VALUE]
        end
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

    -- Only clear the waypoint if we weren't inside it when it was set
    if lastdistance and not UnitOnTaxi("player") then
        local idx = GetCourseIndex(uid)
        local activeCourse = WorldOfParkour.activeCourseStore.activecourse
                                 .course
        activeCourse[idx].completed = true
        -- Check if the user is at the last point in the course.
        if idx ~= #activeCourse then
            -- Set crazy arrow to the next point in the course.
            local nextUid = activeCourse[idx + 1].uid
            TomTom:SetCrazyArrow(nextUid, TomTom.profile.arrow.arrival,
                                 nextUid.title)
        end
        TomTom:RemoveWaypoint(uid)
    end
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
        -- TODO: This function should only be here when outside of creation mode.
        distance = {[3] = function(...) _both_clear_distance(...); end}
    }
    return callbacks
end
