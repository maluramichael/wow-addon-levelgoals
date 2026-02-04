local addonName, addon = ...
local LevelGoals = addon

function LevelGoals:GetOptionsTable()
    return {
        name = "LevelGoals",
        type = "group",
        args = {
            header = {
                type = "description",
                name = "|cffffd700LevelGoals|r v" .. self.version .. "\n\nTrack your daily leveling progress with XP goals and deadlines.\n\nSlash commands: /lg, /levelgoals\nMacro: /run LevelGoals:Toggle()\n",
                order = 1,
            },

            generalHeader = {
                type = "header",
                name = "General Settings",
                order = 10,
            },

            windowVisible = {
                type = "toggle",
                name = "Show Window",
                desc = "Show or hide the progress window. This state is remembered across sessions.",
                order = 11,
                get = function() return self.db.profile.windowVisible end,
                set = function(_, val)
                    self.db.profile.windowVisible = val
                    if val then
                        if self.db.profile.compactMode then
                            self:ShowCompactFrame()
                        else
                            self:ShowMainFrame()
                        end
                    else
                        self:HideMainFrame()
                        self:HideCompactFrame()
                    end
                end,
            },

            windowLocked = {
                type = "toggle",
                name = "Lock Window",
                desc = "Prevent the window from being moved.",
                order = 12,
                get = function() return self.db.profile.windowLocked end,
                set = function(_, val) self.db.profile.windowLocked = val end,
            },

            compactMode = {
                type = "toggle",
                name = "Compact Mode",
                desc = "Use the small compact view instead of the full window.",
                order = 13,
                get = function() return self.db.profile.compactMode end,
                set = function(_, val)
                    self.db.profile.compactMode = val
                    if val then
                        self:ShowCompactFrame()
                    else
                        self:ShowMainFrame()
                    end
                end,
            },

            goalHeader = {
                type = "header",
                name = "Goal Settings",
                order = 20,
            },

            targetLevel = {
                type = "range",
                name = "Target Level",
                desc = "The level you want to reach.",
                order = 21,
                min = 2,
                max = 70,
                step = 1,
                get = function() return self.db.profile.targetLevel end,
                set = function(_, val)
                    self.db.profile.targetLevel = val
                    self:UpdateDisplay()
                    self:UpdateCompactDisplay()
                end,
            },

            dateHeader = {
                type = "header",
                name = "Target Date",
                order = 30,
            },

            targetDay = {
                type = "range",
                name = "Day",
                desc = "Target day of month (1-31).",
                order = 31,
                min = 1,
                max = 31,
                step = 1,
                get = function() return self.db.profile.targetDay end,
                set = function(_, val)
                    self.db.profile.targetDay = val
                    self:UpdateDisplay()
                    self:UpdateCompactDisplay()
                end,
            },

            targetMonth = {
                type = "range",
                name = "Month",
                desc = "Target month (1-12).",
                order = 32,
                min = 1,
                max = 12,
                step = 1,
                get = function() return self.db.profile.targetMonth end,
                set = function(_, val)
                    self.db.profile.targetMonth = val
                    self:UpdateDisplay()
                    self:UpdateCompactDisplay()
                end,
            },

            targetYear = {
                type = "range",
                name = "Year",
                desc = "Target year.",
                order = 33,
                min = 2024,
                max = 2030,
                step = 1,
                get = function() return self.db.profile.targetYear end,
                set = function(_, val)
                    self.db.profile.targetYear = val
                    self:UpdateDisplay()
                    self:UpdateCompactDisplay()
                end,
            },

            notificationHeader = {
                type = "header",
                name = "Notifications",
                order = 40,
            },

            notificationsEnabled = {
                type = "toggle",
                name = "Enable Milestone Notifications",
                desc = "Show chat messages when you reach milestone percentages of your daily goal.",
                order = 41,
                width = "full",
                get = function() return self.db.profile.notificationsEnabled end,
                set = function(_, val) self.db.profile.notificationsEnabled = val end,
            },

            notificationInterval = {
                type = "range",
                name = "Notification Interval (%)",
                desc = "Show a notification every X percent of daily progress (e.g., 2 = notify at 2%, 4%, 6%, etc.).",
                order = 42,
                min = 1,
                max = 25,
                step = 1,
                get = function() return self.db.profile.notificationInterval end,
                set = function(_, val) self.db.profile.notificationInterval = val end,
                disabled = function() return not self.db.profile.notificationsEnabled end,
            },

            actionsHeader = {
                type = "header",
                name = "Actions",
                order = 50,
            },

            showWindow = {
                type = "execute",
                name = "Show Progress Window",
                order = 51,
                func = function()
                    if self.db.profile.compactMode then
                        self:ShowCompactFrame()
                    else
                        self:ShowMainFrame()
                    end
                end,
            },

            resetSession = {
                type = "execute",
                name = "Reset Session",
                desc = "Reset your daily progress tracking to 0%. Use this if you want to start fresh today.",
                order = 52,
                func = function()
                    self:ResetSession()
                    self:UpdateDisplay()
                    self:UpdateCompactDisplay()
                    local data = self:CalculateProgress()
                    self:Print(string.format("Session reset! Today's goal: %s XP", self:FormatNumber(data.xpPerDay)))
                end,
            },

            resetPosition = {
                type = "execute",
                name = "Reset Window Position",
                order = 53,
                func = function() self:ResetPosition() end,
            },
        },
    }
end
