-- Luacheck configuration for LevelGoals
-- WoW Classic addon

std = "lua51"
codes = true
quiet = 1
max_line_length = false

exclude_files = {
    ".release/",
    "libs/",
    "Libs/",
    ".git/",
}

ignore = {
    "212",          -- Unused argument (common in event handlers)
    "213",          -- Unused loop variable
    "311",          -- Value assigned to variable is unused
    "211/addonName", -- Unused addonName from addon bootstrap
}

-- Addon-specific globals
globals = {
    "_G",
    "LevelGoals",
}

-- WoW API globals
read_globals = {
    -- Lua standard
    "abs", "ceil", "floor", "max", "min", "mod", "random", "sqrt",
    "format", "gmatch", "gsub", "strbyte", "strfind", "strlen", "strlower",
    "strmatch", "strsub", "strupper", "strsplit", "strjoin", "strtrim",
    "date", "time", "difftime",
    "sort", "tinsert", "tremove", "wipe", "unpack",
    "pairs", "ipairs", "next", "select", "type", "tonumber", "tostring",
    "getmetatable", "setmetatable", "rawget", "rawset",
    "pcall", "xpcall", "error", "assert", "loadstring",
    "print", "debugstack",

    -- Libraries
    "LibStub",

    -- Frame API
    "CreateFrame", "UIParent", "GameTooltip", "GameFontNormal",
    "BackdropTemplateMixin",

    -- Unit API
    "UnitName", "UnitLevel", "UnitXP", "UnitXPMax",

    -- Misc API
    "GetTime", "GetAddOnMetadata",
    "InCombatLockdown", "InterfaceOptionsFrame_OpenToCategory",
    "Settings", "C_Timer", "C_AddOns",

    -- Constants
    "SOUNDKIT",
}
