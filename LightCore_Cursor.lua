local floor = math.floor
local GetCursorPosition = GetCursorPosition

LightCore_CursorDB = LightCore_CursorDB or {}
LightCore_Cursor = {}

local DEFAULT_SIZE = 28
local TEXTURE = "Interface\\AddOns\\LightCore_Cursor\\cursor_ring"

local f = CreateFrame("Frame", "LightCore_CursorFrame", UIParent)
f:SetFrameStrata("TOOLTIP")
f:SetFrameLevel(9999)
f:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
f:EnableMouse(false)

local t = f:CreateTexture(nil, "OVERLAY")
t:SetAllPoints(f)
t:SetTexture(TEXTURE)

local ADDON_NAME = "LightCore_Cursor"
local SLASH_COMMAND = "/lcc"
local DEFAULT_COLOR_R = 1
local DEFAULT_COLOR_G = 1
local DEFAULT_COLOR_B = 1

local inCombat = InCombatLockdown()
local currentX, currentY, lastX, lastY
local currentScale, invScale

local function GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        return color.r, color.g, color.b
    end

    return DEFAULT_COLOR_R, DEFAULT_COLOR_G, DEFAULT_COLOR_B
end

local function SetRingColor(r, g, b)
    t:SetVertexColor(r, g, b, 1)
end

local function SetCombatEvents(enabled)
    if enabled then
        f:RegisterEvent("PLAYER_REGEN_DISABLED")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        f:UnregisterEvent("PLAYER_REGEN_DISABLED")
        f:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

local function UpdateVisibility()
    if LightCore_CursorDB.combatOnly then
        f:SetShown(inCombat)
    else
        f:Show()
    end
end

local function OpenSettings()
    if InCombatLockdown() then
        print("LightCore Cursor: Cannot open settings during combat.")
        return
    end

    if not SettingsPanel then
        print("LightCore Cursor: Settings panel not available.")
        return
    end

    SettingsPanel:Show()

    local categoryID = LightCore_Cursor.settingsCategoryID
    if not categoryID then
        return
    end

    local category = SettingsPanel:GetCategoryList():GetCategory(categoryID)
    if category then
        category:SetExpanded(true)
        SettingsPanel:SelectCategory(category)
    end
end

local function InitializeDefaults()
    if LightCore_CursorDB.size == nil then
        LightCore_CursorDB.size = DEFAULT_SIZE
    end

    if LightCore_CursorDB.useClassColor == nil then
        LightCore_CursorDB.useClassColor = true
    end

    if LightCore_CursorDB.colorR == nil then
        LightCore_CursorDB.colorR = DEFAULT_COLOR_R
        LightCore_CursorDB.colorG = DEFAULT_COLOR_G
        LightCore_CursorDB.colorB = DEFAULT_COLOR_B
    end

    if LightCore_CursorDB.combatOnly == nil then
        LightCore_CursorDB.combatOnly = false
    end
end

function LightCore_Cursor.ApplySize(size)
    LightCore_CursorDB.size = size
    f:SetSize(size, size)
end

function LightCore_Cursor.ApplyColor(r, g, b)
    LightCore_CursorDB.colorR = r
    LightCore_CursorDB.colorG = g
    LightCore_CursorDB.colorB = b
    SetRingColor(r, g, b)
end

function LightCore_Cursor.ApplyClassColor()
    SetRingColor(GetClassColor())
end

function LightCore_Cursor.SetCombatOnly(value)
    LightCore_CursorDB.combatOnly = value
    SetCombatEvents(value)
    UpdateVisibility()
end

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        InitializeDefaults()
        LightCore_Cursor.ApplySize(LightCore_CursorDB.size)

        if LightCore_CursorDB.useClassColor then
            LightCore_Cursor.ApplyClassColor()
        else
            LightCore_Cursor.ApplyColor(LightCore_CursorDB.colorR, LightCore_CursorDB.colorG, LightCore_CursorDB.colorB)
        end

        SetCombatEvents(LightCore_CursorDB.combatOnly)
        UpdateVisibility()

        SLASH_LCC1 = SLASH_COMMAND
        SlashCmdList["LCC"] = OpenSettings

        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateVisibility()
    end
end)

f:SetScript("OnUpdate", function()
    currentX, currentY = GetCursorPosition()
    if currentX ~= lastX or currentY ~= lastY then
        lastX, lastY = currentX, currentY
        local scale = UIParent:GetEffectiveScale()
        if scale ~= currentScale then
            currentScale = scale
            invScale = 1 / scale
        end
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", floor(currentX * invScale + 0.5), floor(currentY * invScale + 0.5))
    end
end)
