local addonName, addon = ...

local LevelGoals = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
    "AceEvent-3.0", "AceConsole-3.0")

_G["LevelGoals"] = LevelGoals

LevelGoals.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Runtime milestone tracking (not saved)
LevelGoals.lastMilestone = 0

local defaults = {
    profile = {
        enabled = true,
        targetLevel = 70,
        targetDay = 15,
        targetMonth = 2,
        targetYear = 2026,
        windowVisible = true,
        windowLocked = false,
        windowPoint = { "CENTER", nil, "CENTER", 0, 0 },
        compactPoint = { "CENTER", nil, "CENTER", 0, 100 },
        compactMode = false,
        notificationsEnabled = true,
        notificationInterval = 2, -- every X percent
    },
    -- Character-specific session data (persists across /reload)
    char = {
        sessionDate = nil,           -- "YYYY-MM-DD" format
        sessionStartLevel = nil,
        sessionStartXP = nil,
        sessionStartTotalXP = nil,
    },
}

function LevelGoals:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LevelGoalsDB", defaults, true)

    self:RegisterChatCommand("lg", "SlashCommand")
    self:RegisterChatCommand("levelgoals", "SlashCommand")

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptionsTable())
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "LevelGoals")

    self:CreateMainFrame()
    self:CreateCompactFrame()

    self:Print("v" .. self.version .. " loaded. Type /lg to toggle window.")
end

function LevelGoals:OnEnable()
    self:RegisterEvent("PLAYER_XP_UPDATE", "OnXPUpdate")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnLevelUp")

    -- Update XP table with current level's real XP requirement from API
    self:UpdateXPTableFromAPI()

    -- Check if we need to start a new session (new day or first time)
    self:CheckAndInitSession()

    if self.db.profile.windowVisible then
        C_Timer.After(2, function()
            if self.db.profile.compactMode then
                self:ShowCompactFrame()
            else
                self:ShowMainFrame()
            end
        end)
    end
end

function LevelGoals:OnDisable()
    self:UnregisterAllEvents()
end

-- Get today's date as string "YYYY-MM-DD"
function LevelGoals:GetTodayDate()
    return date("%Y-%m-%d")
end

-- Check if session needs to be reset (new day) or restored
function LevelGoals:CheckAndInitSession()
    local today = self:GetTodayDate()
    local savedDate = self.db.char.sessionDate

    if savedDate ~= today then
        -- It's a new day - reset session
        self:ResetSession()
        local data = self:CalculateProgress()
        self:Print(string.format("New day! Today's goal: %s XP (%d days remaining)",
            self:FormatNumber(data.xpPerDay), data.daysRemaining))
    else
        -- Same day - restore milestone tracking based on current progress
        self:RestoreMilestone()
        local data = self:CalculateProgress()
        self:Print(string.format("Session restored: %.1f%% of today's goal (%s XP remaining)",
            data.sessionPercent, self:FormatNumber(data.dailyXPRemaining)))
    end
end

-- Restore milestone counter based on current session progress
function LevelGoals:RestoreMilestone()
    local data = self:CalculateProgress()
    local interval = self.db.profile.notificationInterval
    self.lastMilestone = math.floor(data.sessionPercent / interval) * interval
end

-- Reset session to current XP (starts tracking from 0%)
function LevelGoals:ResetSession()
    local level, currentXP = self:GetCurrentPlayerData()
    local totalXP = self:GetTotalXPEarned(level, currentXP)

    -- Save to character-specific SavedVariables
    self.db.char.sessionDate = self:GetTodayDate()
    self.db.char.sessionStartLevel = level
    self.db.char.sessionStartXP = currentXP
    self.db.char.sessionStartTotalXP = totalXP

    -- Reset milestone tracking
    self.lastMilestone = 0
end

-- Get session start total XP (from SavedVariables)
function LevelGoals:GetSessionStartTotalXP()
    return self.db.char.sessionStartTotalXP or 0
end

function LevelGoals:OnXPUpdate()
    self:CheckMilestones()
    self:UpdateDisplay()
    self:UpdateCompactDisplay()
end

function LevelGoals:OnLevelUp()
    C_Timer.After(0.5, function()
        -- Update XP table with the new level's XP requirement
        self:UpdateXPTableFromAPI()
        self:CheckMilestones()
        self:UpdateDisplay()
        self:UpdateCompactDisplay()
    end)
end

function LevelGoals:CheckMilestones()
    if not self.db.profile.notificationsEnabled then return end

    local data = self:CalculateProgress()
    local interval = self.db.profile.notificationInterval

    -- Calculate which milestone we're at
    local currentMilestone = math.floor(data.sessionPercent / interval) * interval

    -- If we crossed a new milestone
    if currentMilestone > self.lastMilestone and currentMilestone > 0 then
        local remaining = 100 - data.sessionPercent
        if data.sessionPercent >= 100 then
            self:Print("|cff00ff00Daily goal reached! You earned " .. self:FormatNumber(data.sessionXPEarned) .. " XP this session!|r")
        else
            self:Print(string.format("|cffffff00Daily Goal: %d%% complete - %.1f%% remaining (%s XP to go)|r",
                currentMilestone, remaining, self:FormatNumber(data.dailyXPRemaining)))
        end
        self.lastMilestone = currentMilestone
    end
end

function LevelGoals:SlashCommand(input)
    local cmd = input and input:lower():trim() or ""

    if cmd == "config" or cmd == "options" then
        Settings.OpenToCategory("LevelGoals")
    elseif cmd == "reset" then
        self:ResetPosition()
    elseif cmd == "hide" then
        self:HideMainFrame()
        self:HideCompactFrame()
    elseif cmd == "compact" then
        self:ToggleCompactMode()
    elseif cmd == "session" or cmd == "restart" then
        self:ResetSession()
        self:UpdateDisplay()
        self:UpdateCompactDisplay()
        local data = self:CalculateProgress()
        self:Print(string.format("Session reset! Today's goal: %s XP", self:FormatNumber(data.xpPerDay)))
    elseif cmd == "" or cmd == "show" or cmd == "toggle" then
        self:ToggleMainFrame()
    else
        self:Print("Commands: /lg [show|hide|toggle|compact|session|config|reset]")
    end
end

function LevelGoals:Toggle()
    self:ToggleMainFrame()
end

function LevelGoals:ToggleCompactMode()
    self.db.profile.compactMode = not self.db.profile.compactMode
    if self.db.profile.compactMode then
        self:HideMainFrame()
        self:ShowCompactFrame()
    else
        self:HideCompactFrame()
        self:ShowMainFrame()
    end
end

-- Date/Time utilities
function LevelGoals:GetTargetTimestamp()
    local target = {
        year = self.db.profile.targetYear,
        month = self.db.profile.targetMonth,
        day = self.db.profile.targetDay,
        hour = 23,
        min = 59,
        sec = 59,
    }
    return time(target)
end

function LevelGoals:GetDaysRemaining()
    local now = time()
    local target = self:GetTargetTimestamp()
    local diff = target - now

    if diff <= 0 then return 0 end

    return math.ceil(diff / 86400) -- 86400 seconds per day
end

-- Get hours remaining until midnight (local time)
function LevelGoals:GetHoursUntilMidnight()
    local now = date("*t")
    local secondsUntilMidnight = (24 - now.hour - 1) * 3600 + (60 - now.min) * 60 + (60 - now.sec)
    return secondsUntilMidnight / 3600 -- Return as decimal hours
end

function LevelGoals:GetCurrentPlayerData()
    local level = UnitLevel("player")
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")

    return level, currentXP, maxXP
end

function LevelGoals:CalculateProgress()
    local level, currentXP, maxXP = self:GetCurrentPlayerData()
    local targetLevel = self.db.profile.targetLevel
    local daysRemaining = self:GetDaysRemaining()

    -- Current total XP (all XP earned from level 1 to now)
    local currentTotalXP = self:GetTotalXPEarned(level, currentXP)

    -- Session XP earned (since today's session started)
    local sessionStartTotalXP = self:GetSessionStartTotalXP()
    local sessionXPEarned = math.max(0, currentTotalXP - sessionStartTotalXP)

    -- XP remaining to reach target level
    local xpRemaining = self:GetXPToTarget(level, currentXP, targetLevel)

    -- Daily XP goal = XP remaining / days remaining
    -- This automatically adjusts if you miss days or earn extra
    local xpPerDay = 0
    if daysRemaining > 0 then
        xpPerDay = math.ceil(xpRemaining / daysRemaining)
    end

    -- Session progress toward today's daily goal (0-100%+)
    local sessionPercent = 0
    local dailyXPRemaining = xpPerDay
    if xpPerDay > 0 then
        sessionPercent = (sessionXPEarned / xpPerDay) * 100
        dailyXPRemaining = math.max(0, xpPerDay - sessionXPEarned)
    end

    -- XP per hour needed (based on hours until midnight)
    local hoursRemaining = self:GetHoursUntilMidnight()
    local xpPerHour = 0
    if hoursRemaining > 0 and dailyXPRemaining > 0 then
        xpPerHour = math.ceil(dailyXPRemaining / hoursRemaining)
    end

    -- Overall progress to target level (for reference)
    local totalXPNeeded = self:GetTotalXPForLevel(targetLevel)
    local overallPercent = 0
    if totalXPNeeded > 0 then
        overallPercent = (currentTotalXP / totalXPNeeded) * 100
    end

    -- Already at or past target
    local goalReached = level >= targetLevel

    return {
        currentLevel = level,
        currentXP = currentXP,
        maxXP = maxXP,
        targetLevel = targetLevel,
        daysRemaining = daysRemaining,
        xpRemaining = xpRemaining,
        xpPerDay = xpPerDay,
        xpPerHour = xpPerHour,
        hoursRemaining = hoursRemaining,
        sessionXPEarned = sessionXPEarned,
        sessionPercent = sessionPercent,
        dailyXPRemaining = dailyXPRemaining,
        overallPercent = overallPercent,
        goalReached = goalReached,
        deadlinePassed = daysRemaining <= 0,
    }
end

-- Format large numbers with commas
function LevelGoals:FormatNumber(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- Main Frame
function LevelGoals:CreateMainFrame()
    local frame = CreateFrame("Frame", "LevelGoalsMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(320, 370)
    frame:SetPoint(unpack(self.db.profile.windowPoint))
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if not self.db.profile.windowLocked then
            f:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        self.db.profile.windowPoint = { point, nil, relPoint, x, y }
    end)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Level Goals")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        self:HideMainFrame()
    end)

    -- Compact button
    local compactBtn = CreateFrame("Button", nil, frame)
    compactBtn:SetSize(20, 20)
    compactBtn:SetPoint("TOPRIGHT", -30, -8)
    compactBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
    compactBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
    compactBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    compactBtn:SetScript("OnClick", function()
        self:ToggleCompactMode()
    end)

    -- Content area
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 20, -50)
    content:SetPoint("BOTTOMRIGHT", -20, 50)

    -- Create text lines
    local function CreateLine(parent, yOffset)
        local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 0, yOffset)
        text:SetPoint("TOPRIGHT", 0, yOffset)
        text:SetJustifyH("LEFT")
        return text
    end

    frame.lines = {}
    frame.lines.currentLevel = CreateLine(content, 0)
    frame.lines.targetLevel = CreateLine(content, -22)
    frame.lines.targetDate = CreateLine(content, -44)
    frame.lines.daysRemaining = CreateLine(content, -66)
    frame.lines.xpPerDay = CreateLine(content, -88)

    -- Session header
    frame.lines.sessionHeader = CreateLine(content, -115)
    frame.lines.sessionHeader:SetText("|cffffd700-- Today's Session --|r")

    frame.lines.sessionDate = CreateLine(content, -137)
    frame.lines.sessionXP = CreateLine(content, -159)
    frame.lines.dailyRemaining = CreateLine(content, -181)
    frame.lines.xpPerHour = CreateLine(content, -203)

    -- Daily progress bar (session progress)
    local progressBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
    progressBg:SetPoint("TOPLEFT", 0, -230)
    progressBg:SetPoint("TOPRIGHT", 0, -230)
    progressBg:SetHeight(20)
    progressBg:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    progressBg:SetBackdropColor(0.1, 0.1, 0.1, 1)
    progressBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local progressBar = progressBg:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("TOPLEFT", 1, -1)
    progressBar:SetPoint("BOTTOMLEFT", 1, 1)
    progressBar:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    progressBar:SetVertexColor(0.2, 0.6, 1, 1)
    frame.progressBar = progressBar
    frame.progressBg = progressBg

    local progressText = progressBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressText:SetPoint("CENTER")
    progressText:SetTextColor(1, 1, 1)
    frame.progressText = progressText

    -- Status line
    frame.lines.status = CreateLine(content, -260)

    -- Reset session button
    local recalcBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    recalcBtn:SetSize(100, 24)
    recalcBtn:SetPoint("BOTTOMLEFT", 20, 15)
    recalcBtn:SetText("Reset Session")
    recalcBtn:SetScript("OnClick", function()
        self:ResetSession()
        self:UpdateDisplay()
        self:UpdateCompactDisplay()
        local data = self:CalculateProgress()
        self:Print(string.format("Session reset! Today's goal: %s XP", self:FormatNumber(data.xpPerDay)))
    end)

    -- Config button
    local configBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    configBtn:SetSize(80, 24)
    configBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    configBtn:SetText("Settings")
    configBtn:SetScript("OnClick", function()
        Settings.OpenToCategory("LevelGoals")
    end)

    self.mainFrame = frame
end

-- Compact Frame
function LevelGoals:CreateCompactFrame()
    local frame = CreateFrame("Frame", "LevelGoalsCompactFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 40)
    frame:SetPoint(unpack(self.db.profile.compactPoint))
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if not self.db.profile.windowLocked then
            f:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        self.db.profile.compactPoint = { point, nil, relPoint, x, y }
    end)
    frame:Hide()

    -- Progress bar background
    local progressBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    progressBg:SetPoint("TOPLEFT", 8, -8)
    progressBg:SetPoint("RIGHT", -35, 0)
    progressBg:SetHeight(24)
    progressBg:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    progressBg:SetBackdropColor(0.1, 0.1, 0.1, 1)
    progressBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    frame.progressBg = progressBg

    -- Progress bar fill
    local progressBar = progressBg:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("TOPLEFT", 1, -1)
    progressBar:SetPoint("BOTTOMLEFT", 1, 1)
    progressBar:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    progressBar:SetVertexColor(0.2, 0.6, 1, 1)
    frame.progressBar = progressBar

    -- Progress text
    local progressText = progressBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER")
    progressText:SetTextColor(1, 1, 1)
    frame.progressText = progressText

    -- Expand button
    local expandBtn = CreateFrame("Button", nil, frame)
    expandBtn:SetSize(20, 20)
    expandBtn:SetPoint("RIGHT", -8, 0)
    expandBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
    expandBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Down")
    expandBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    expandBtn:SetScript("OnClick", function()
        self:ToggleCompactMode()
    end)

    self.compactFrame = frame
end

function LevelGoals:UpdateDisplay()
    if not self.mainFrame or not self.mainFrame:IsShown() then return end

    local data = self:CalculateProgress()
    local lines = self.mainFrame.lines

    lines.currentLevel:SetText("|cffffffffCurrent Level:|r " .. data.currentLevel .. " (" .. self:FormatNumber(data.currentXP) .. "/" .. self:FormatNumber(data.maxXP) .. " XP)")
    lines.targetLevel:SetText("|cffffffffTarget Level:|r " .. data.targetLevel)
    lines.targetDate:SetText("|cffffffffTarget Date:|r " .. string.format("%02d.%02d.%04d",
        self.db.profile.targetDay, self.db.profile.targetMonth, self.db.profile.targetYear))

    -- Days remaining with color
    local daysColor = "|cff00ff00" -- green
    if data.daysRemaining <= 3 then
        daysColor = "|cffff0000" -- red
    elseif data.daysRemaining <= 7 then
        daysColor = "|cffffff00" -- yellow
    end
    lines.daysRemaining:SetText("|cffffffffDays Remaining:|r " .. daysColor .. data.daysRemaining .. "|r")

    lines.xpPerDay:SetText("|cffffffffDaily XP Goal:|r " .. self:FormatNumber(data.xpPerDay))

    -- Session info
    local sessionDate = self.db.char.sessionDate or self:GetTodayDate()
    local year, month, day = sessionDate:match("(%d+)-(%d+)-(%d+)")
    lines.sessionDate:SetText("|cffffffffSession Started:|r " .. string.format("%s.%s.%s", day, month, year))
    lines.sessionXP:SetText("|cffffffffSession XP:|r " .. self:FormatNumber(data.sessionXPEarned) .. " / " .. self:FormatNumber(data.xpPerDay))
    lines.dailyRemaining:SetText("|cffffffffRemaining Today:|r " .. self:FormatNumber(data.dailyXPRemaining))

    -- XP per hour with hours remaining
    local hoursText = string.format("%.1fh left", data.hoursRemaining)
    lines.xpPerHour:SetText("|cffffffffXP Per Hour:|r " .. self:FormatNumber(data.xpPerHour) .. " |cff888888(" .. hoursText .. ")|r")

    -- Progress bar (session/daily progress)
    local width = self.mainFrame.progressBg:GetWidth() - 2
    local progress = math.min(data.sessionPercent, 100)
    self.mainFrame.progressBar:SetWidth(math.max(1, width * (progress / 100)))
    self.mainFrame.progressText:SetText(string.format("%.1f%%", data.sessionPercent))

    -- Status and bar color
    if data.goalReached then
        lines.status:SetText("|cff00ff00Goal reached! Congratulations!|r")
        self.mainFrame.progressBar:SetVertexColor(0, 0.8, 0, 1)
    elseif data.deadlinePassed then
        lines.status:SetText("|cffff0000Deadline has passed!|r")
        self.mainFrame.progressBar:SetVertexColor(0.8, 0, 0, 1)
    elseif data.sessionPercent >= 100 then
        lines.status:SetText("|cff00ff00Daily goal complete!|r")
        self.mainFrame.progressBar:SetVertexColor(0, 0.8, 0, 1)
    elseif data.sessionPercent >= 50 then
        lines.status:SetText("|cff00ff00Good progress today!|r")
        self.mainFrame.progressBar:SetVertexColor(0.2, 0.6, 1, 1)
    else
        lines.status:SetText("|cffffff00Keep going!|r")
        self.mainFrame.progressBar:SetVertexColor(0.2, 0.6, 1, 1)
    end
end

function LevelGoals:UpdateCompactDisplay()
    if not self.compactFrame or not self.compactFrame:IsShown() then return end

    local data = self:CalculateProgress()

    -- Progress bar
    local width = self.compactFrame.progressBg:GetWidth() - 2
    local progress = math.min(data.sessionPercent, 100)
    self.compactFrame.progressBar:SetWidth(math.max(1, width * (progress / 100)))
    self.compactFrame.progressText:SetText(string.format("%.1f%% (%s)", data.sessionPercent, self:FormatNumber(data.dailyXPRemaining)))

    -- Bar color
    if data.sessionPercent >= 100 then
        self.compactFrame.progressBar:SetVertexColor(0, 0.8, 0, 1)
    else
        self.compactFrame.progressBar:SetVertexColor(0.2, 0.6, 1, 1)
    end
end

function LevelGoals:ShowMainFrame()
    if self.mainFrame then
        self.db.profile.compactMode = false
        self.db.profile.windowVisible = true
        if self.compactFrame then self.compactFrame:Hide() end
        self.mainFrame:Show()
        self:UpdateDisplay()
    end
end

function LevelGoals:HideMainFrame()
    if self.mainFrame then
        self.db.profile.windowVisible = false
        self.mainFrame:Hide()
    end
end

function LevelGoals:ShowCompactFrame()
    if self.compactFrame then
        self.db.profile.compactMode = true
        self.db.profile.windowVisible = true
        if self.mainFrame then self.mainFrame:Hide() end
        self.compactFrame:Show()
        self:UpdateCompactDisplay()
    end
end

function LevelGoals:HideCompactFrame()
    if self.compactFrame then
        self.db.profile.windowVisible = false
        self.compactFrame:Hide()
    end
end

function LevelGoals:ToggleMainFrame()
    if self.db.profile.compactMode then
        if self.compactFrame and self.compactFrame:IsShown() then
            self:HideCompactFrame()
        else
            self:ShowCompactFrame()
        end
    else
        if self.mainFrame and self.mainFrame:IsShown() then
            self:HideMainFrame()
        else
            self:ShowMainFrame()
        end
    end
end

function LevelGoals:ResetPosition()
    if self.mainFrame then
        self.db.profile.windowPoint = { "CENTER", nil, "CENTER", 0, 0 }
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint("CENTER")
    end
    if self.compactFrame then
        self.db.profile.compactPoint = { "CENTER", nil, "CENTER", 0, 100 }
        self.compactFrame:ClearAllPoints()
        self.compactFrame:SetPoint("CENTER", 0, 100)
    end
    self:Print("Window positions reset.")
end
