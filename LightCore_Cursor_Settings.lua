local format = string.format
local DEFAULT_COLOR_R = 1
local DEFAULT_COLOR_G = 1
local DEFAULT_COLOR_B = 1

local function SizeLabel(value)
    return format("%d px", value)
end

local function GetSwatchColor()
    return CreateColor(
        LightCore_CursorDB.colorR or 1,
        LightCore_CursorDB.colorG or DEFAULT_COLOR_G,
        LightCore_CursorDB.colorB or DEFAULT_COLOR_B
    )
end

local function GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        return color.r, color.g, color.b
    end

    return DEFAULT_COLOR_R, DEFAULT_COLOR_G, DEFAULT_COLOR_B
end

local function EnsureCustomColor()
    if LightCore_CursorDB.colorR == nil then
        LightCore_CursorDB.colorR, LightCore_CursorDB.colorG, LightCore_CursorDB.colorB = GetClassColor()
    end
end

local function OnSwatchClick(swatch)
    local color = GetSwatchColor()
    local info = {}
    info.swatch = swatch
    info.r, info.g, info.b = color:GetRGB()
    info.swatchFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        LightCore_Cursor.ApplyColor(r, g, b)
    end
    info.cancelFunc = function()
        local r, g, b = ColorPickerFrame:GetPreviousValues()
        LightCore_Cursor.ApplyColor(r, g, b)
    end
    ColorPickerFrame:SetupColorPickerAndShow(info)
end

EventUtil.ContinueOnAddOnLoaded("LightCore_Cursor", function()
    local category, layout = Settings.RegisterVerticalLayoutCategory("LightCore Cursor")
    LightCore_Cursor.settingsCategoryID = category:GetID()

    local sizeSetting = Settings.RegisterProxySetting(
        category,
        "LIGHTCORE_CURSOR_SIZE",
        Settings.VarType.Number,
        "Cursor Ring Size",
        28,
        function() return LightCore_CursorDB.size end,
        function(value) LightCore_Cursor.ApplySize(value) end
    )

    local sizeOptions = Settings.CreateSliderOptions(16, 64, 1)
    sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, SizeLabel)
    Settings.CreateSlider(category, sizeSetting, sizeOptions, "Size of the cursor ring in pixels.")

    local useClassColorSetting = Settings.RegisterProxySetting(
        category,
        "LIGHTCORE_CURSOR_USE_CLASS_COLOR",
        Settings.VarType.Boolean,
        "Use Class Color",
        true,
        function() return LightCore_CursorDB.useClassColor end,
        function(value)
            LightCore_CursorDB.useClassColor = value
            if value then
                LightCore_Cursor.ApplyClassColor()
            else
                EnsureCustomColor()
                LightCore_Cursor.ApplyColor(LightCore_CursorDB.colorR, LightCore_CursorDB.colorG, LightCore_CursorDB.colorB)
            end
        end
    )

    local colorInitializer = CreateSettingsCheckboxWithColorSwatchInitializer(
        useClassColorSetting,
        "Color the cursor ring with your class color.",
        OnSwatchClick,
        true,
        true,
        GetSwatchColor,
        "Custom Color",
        "Pick a custom color for the cursor ring."
    )
    layout:AddInitializer(colorInitializer)

    local combatOnlySetting = Settings.RegisterProxySetting(
        category,
        "LIGHTCORE_CURSOR_COMBAT_ONLY",
        Settings.VarType.Boolean,
        "Show in Combat Only",
        false,
        function() return LightCore_CursorDB.combatOnly end,
        function(value) LightCore_Cursor.SetCombatOnly(value) end
    )
    Settings.CreateCheckbox(category, combatOnlySetting, "Only show the cursor ring while in combat.")

    Settings.RegisterAddOnCategory(category)
end)
