local _, addon = ...
addon.errors = {}
local errors = addon.errors

errors.notInActiveModeError = function() error("You must have an Active Course to perform this action.") end
errors.notInEditModeError = function() error("You must be in edit mode to perform this action.") end