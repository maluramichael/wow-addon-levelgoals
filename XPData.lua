local addonName, addon = ...

-- XP required to complete each level (TBC Classic values)
-- Index = level, Value = XP needed to go from that level to next level
addon.XP_TO_LEVEL = {
    [1] = 400,
    [2] = 900,
    [3] = 1400,
    [4] = 2100,
    [5] = 2800,
    [6] = 3600,
    [7] = 4500,
    [8] = 5400,
    [9] = 6500,
    [10] = 7600,
    [11] = 8700,
    [12] = 9800,
    [13] = 11000,
    [14] = 12300,
    [15] = 13600,
    [16] = 15000,
    [17] = 16400,
    [18] = 17800,
    [19] = 19300,
    [20] = 20800,
    [21] = 22400,
    [22] = 24000,
    [23] = 25500,
    [24] = 27200,
    [25] = 28900,
    [26] = 30500,
    [27] = 32200,
    [28] = 33900,
    [29] = 36300,
    [30] = 38800,
    [31] = 41600,
    [32] = 44600,
    [33] = 48000,
    [34] = 51400,
    [35] = 55000,
    [36] = 58700,
    [37] = 62400,
    [38] = 66200,
    [39] = 70200,
    [40] = 74300,
    [41] = 78500,
    [42] = 82800,
    [43] = 87100,
    [44] = 91600,
    [45] = 96300,
    [46] = 101000,
    [47] = 105800,
    [48] = 110700,
    [49] = 115700,
    [50] = 120900,
    [51] = 126100,
    [52] = 131500,
    [53] = 137000,
    [54] = 142500,
    [55] = 148200,
    [56] = 154000,
    [57] = 159900,
    [58] = 165800,
    [59] = 172000,
    [60] = 290000,
    [61] = 317000,
    [62] = 349000,
    [63] = 386000,
    [64] = 428000,
    [65] = 475000,
    [66] = 527000,
    [67] = 586000,
    [68] = 650000,
    [69] = 720000,
}

-- Calculate total XP needed from level A to level B
function addon:GetTotalXPBetweenLevels(fromLevel, toLevel)
    if fromLevel >= toLevel then return 0 end

    local total = 0
    for level = fromLevel, toLevel - 1 do
        total = total + (self.XP_TO_LEVEL[level] or 0)
    end
    return total
end

-- Get XP required for a specific level (uses API for current level, table for others)
function addon:GetXPForLevel(level)
    local playerLevel = UnitLevel("player")

    -- For current level, use the API (most accurate)
    if level == playerLevel then
        return UnitXPMax("player")
    end

    -- For other levels, use the hardcoded table
    return self.XP_TO_LEVEL[level] or 0
end

-- Update our table with real data from the API (call on level up)
function addon:UpdateXPTableFromAPI()
    local playerLevel = UnitLevel("player")
    local maxXP = UnitXPMax("player")

    if playerLevel and maxXP and maxXP > 0 then
        self.XP_TO_LEVEL[playerLevel] = maxXP
    end
end

-- Calculate total XP needed from current state to target level
function addon:GetXPToTarget(currentLevel, currentXP, targetLevel)
    if currentLevel >= targetLevel then return 0 end

    -- XP remaining in current level (use API for accuracy)
    local xpInCurrentLevel = self:GetXPForLevel(currentLevel) - currentXP

    -- XP for all levels between current+1 and target
    local xpForRemainingLevels = self:GetTotalXPBetweenLevels(currentLevel + 1, targetLevel)

    return xpInCurrentLevel + xpForRemainingLevels
end

-- Get total XP earned from level 1 to current state
function addon:GetTotalXPEarned(currentLevel, currentXP)
    local total = self:GetTotalXPBetweenLevels(1, currentLevel)
    return total + currentXP
end

-- Get total XP from level 1 to target level
function addon:GetTotalXPForLevel(targetLevel)
    return self:GetTotalXPBetweenLevels(1, targetLevel)
end
