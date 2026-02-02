std = "lua51"
codes = true
quiet = 1
max_line_length = false
exclude_files = { ".release/", "libs/", "Libs/" }

ignore = {
    "21.",          -- All unused variable warnings (W211, W212, W213)
    "231",          -- Variable never accessed
    "311",          -- Value assigned to variable is unused
    "631",          -- Line too long
}

globals = { "_G", "LevelGoals" }

read_globals = {
    "LibStub",
    "CreateFrame", "UIParent", "GameTooltip", "Settings",
    "UnitLevel", "UnitXP", "UnitXPMax", "GetTime",
    "InterfaceOptionsFrame_OpenToCategory",
    "C_AddOns", "C_Timer",
    "pairs", "ipairs", "select", "string", "table", "math", "format",
    "tonumber", "tostring", "type", "unpack", "date", "time",
}
