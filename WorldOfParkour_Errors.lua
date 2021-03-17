local _, addon = ...
addon.errors = {}
local errors = addon.errors

errors.notInActiveModeError = function() WorldOfParkour:Error("You must have an Active Course to perform this action.") end
errors.notInEditModeError = function() WorldOfParkour:Error("You must be in edit mode to perform this action.") end
errors.inEditModeError = function() WorldOfParkour:Error("You can't do this in edit mode.") end
