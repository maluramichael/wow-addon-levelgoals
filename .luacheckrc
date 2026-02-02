std = "lua51"
codes = true
quiet = 1
max_line_length = false
exclude_files = { ".release/", "libs/", "Libs/" }

globals = { "LevelGoals" }

read_globals = {
    "_G", "LibStub",
    "CreateFrame", "UIParent", "GameTooltip", "Settings",
    "UnitLevel", "UnitXP", "UnitXPMax", "GetTime",
    "InterfaceOptionsFrame_OpenToCategory",
    "pairs", "ipairs", "select", "string", "table", "math", "format",
    "tonumber", "tostring", "type", "unpack",
}
