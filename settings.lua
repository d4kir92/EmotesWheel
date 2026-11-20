local _, EmotesWheel = ...
EmotesWheel:SetAddonOutput()
local ewset = nil
local slotDropdowns = {}
local colorPickers = {}
local ADDED = "2026-11-20"
function EmotesWheel:ToggleSettings()
	if ewset == nil then return end
	ewset:Toggle()
end

local function GetCollapsed(key)
	if key == nil or type(EmotesWheelDB) ~= "table" then return nil end
	if type(EmotesWheelDB["COLLAPSED"]) ~= "table" then return nil end
	return EmotesWheelDB["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
	if key == nil or type(EmotesWheelDB) ~= "table" then return end
	if type(EmotesWheelDB["COLLAPSED"]) ~= "table" then EmotesWheelDB["COLLAPSED"] = {} end
	EmotesWheelDB["COLLAPSED"][key] = collapsed and true or nil
end

local function AddCategory(key)
	ewset:AddCategory({
		["label"] = "LID_" .. key,
		["key"] = key,
		["search"] = key
	})
end

local function AddDropdown(key, default, choices, func, label)
	return ewset:AddDropdown({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["value"] = EmotesWheel:GetConfig(key, default),
		["choices"] = choices,
		["func"] = function(value)
			EmotesWheel:SetConfig(key, value)
			if func then func(value) end
		end
	})
end

local function UpdateSlotRows()
	local count = EmotesWheel:GetSlotCount()
	ewset:SuspendLayout()
	for i, holder in ipairs(slotDropdowns) do
		ewset:SetElementShown(holder, i <= count)
	end

	ewset:ResumeLayout()
end

local function BuildElements()
	ewset:SuspendLayout()
	ewset:AddSearch()
	AddCategory("GENERAL")
	ewset:AddCheckbox({
		["label"] = "LID_MMBTN",
		["search"] = "MMBTN",
		["value"] = EmotesWheel:GetConfig("MMBTN", true),
		["func"] = function(value)
			EmotesWheel:SetConfig("MMBTN", value)
			if value then
				EmotesWheel:ShowMMBtn("EmotesWheel")
			else
				EmotesWheel:HideMMBtn("EmotesWheel")
			end
		end
	})

	ewset:AddKeybind({
		["label"] = "LID_KEYBIND",
		["search"] = "KEYBIND",
		["added"] = ADDED,
		["value"] = EmotesWheel:GetConfig("KEYBIND", nil),
		["func"] = function(value)
			EmotesWheel:SetConfig("KEYBIND", value)
			EmotesWheel:ApplyKeybind()
		end
	})

	AddDropdown("MODE", "HOLD", {
		{
			["value"] = "HOLD",
			["label"] = "LID_MODEHOLD"
		},
		{
			["value"] = "TOGGLE",
			["label"] = "LID_MODETOGGLE"
		}
	})

	AddCategory("WHEEL")
	AddDropdown("POSITION", "CURSOR", {
		{
			["value"] = "CURSOR",
			["label"] = "LID_POSITIONCURSOR"
		},
		{
			["value"] = "CENTER",
			["label"] = "LID_POSITIONCENTER"
		}
	})

	ewset:AddSlider({
		["label"] = "LID_SCALE",
		["search"] = "SCALE",
		["value"] = EmotesWheel:GetConfig("SCALE", 1),
		["min"] = 0.5,
		["max"] = 2,
		["step"] = 0.05,
		["decimals"] = 2,
		["func"] = function(value)
			EmotesWheel:SetConfig("SCALE", value)
			EmotesWheel:BuildWheel()
		end
	})

	ewset:AddSlider({
		["label"] = "LID_SLOTS",
		["search"] = "SLOTS",
		["value"] = EmotesWheel:GetSlotCount(),
		["min"] = 4,
		["max"] = #EmotesWheel.DEFAULTSLOTS,
		["step"] = 1,
		["decimals"] = 0,
		["func"] = function(value)
			EmotesWheel:SetConfig("SLOTS", value)
			EmotesWheel:BuildWheel()
			UpdateSlotRows()
		end
	})

	AddCategory("EMOTES")
	local choices = EmotesWheel:GetEmoteChoices()
	for i = 1, #EmotesWheel.DEFAULTSLOTS do
		slotDropdowns[i] = AddDropdown("SLOT" .. i, EmotesWheel.DEFAULTSLOTS[i], choices, function() EmotesWheel:BuildWheel() end, format(EmotesWheel:Trans("LID_SLOT"), i))
	end

	AddCategory("COLORS")
	for _, key in ipairs(EmotesWheel.COLORORDER) do
		local r, g, b, a = EmotesWheel:GetColor(key)
		colorPickers[key] = ewset:AddColorPicker({
			["label"] = "LID_" .. key,
			["search"] = key,
			["added"] = "2026-11-20",
			["value"] = {r, g, b, a},
			["func"] = function(nr, ng, nb, na) EmotesWheel:SetColor(key, nr, ng, nb, na) end
		})
	end

	UpdateSlotRows()
	ewset:ResumeLayout()
end

local function BuildFooter()
	local footer = ewset:AddFooter({
		["height"] = 24
	})

	local reset = EmotesWheel:CreateButton("EmotesWheelResetColors", footer)
	reset:SetSize(160, 24)
	reset:SetPoint("LEFT", footer, "LEFT", 0, 0)
	reset:SetText(EmotesWheel:Trans("LID_RESETCOLORS"))
	reset:SetScript("OnClick", function()
		EmotesWheel:ResetColors()
		for key, holder in pairs(colorPickers) do
			holder:SetValue(EmotesWheel:GetColor(key))
		end
	end)
end

function EmotesWheel:InitSettings()
	ewset = EmotesWheel:CreateUIWindow({
		["name"] = "EmotesWheelSettings",
		["pTab"] = {"CENTER"},
		["width"] = EmotesWheel:GetConfig("WINDOWWIDTH", 420),
		["height"] = EmotesWheel:GetConfig("WINDOWHEIGHT", 520),
		["minWidth"] = 360,
		["minHeight"] = 240,
		["onResize"] = function(width, height)
			EmotesWheel:SetConfig("WINDOWWIDTH", width)
			EmotesWheel:SetConfig("WINDOWHEIGHT", height)
		end,
		["getCollapsed"] = function(key) return GetCollapsed(key) end,
		["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
		["title"] = format("|T%s:16:16:0:0|t EmotesWheel v%s", EmotesWheel:GetAddonIcon(), EmotesWheel:GetVersion())
	})

	BuildFooter()
	BuildElements()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
	EmotesWheelDB = EmotesWheelDB or {}
	EmotesWheel:SetVersion()
	EmotesWheel:InitSettings()
	EmotesWheel:InitWheel()
	EmotesWheel:AddSlash("emoteswheel", EmotesWheel.ToggleSettings)
	EmotesWheel:AddSlash("ewheel", EmotesWheel.ToggleSettings)
	EmotesWheel:CreateMinimapButton({
		["name"] = "EmotesWheel",
		["icon"] = EmotesWheel:GetAddonIcon(),
		["dbtab"] = EmotesWheelDB,
		["vTT"] = {{format("|T%s:16:16:0:0|t EmotesWheel", EmotesWheel:GetAddonIcon()), "v" .. EmotesWheel:GetVersion()}, {EmotesWheel:Trans("LID_LEFTCLICK"), EmotesWheel:Trans("LID_OPENSETTINGS")}, {EmotesWheel:Trans("LID_SHIFTRIGHTCLICK"), EmotesWheel:Trans("LID_HIDEMINIMAPBUTTON")}},
		["funcL"] = function() EmotesWheel:ToggleSettings() end,
		["funcSR"] = function()
			EmotesWheel:SetConfig("MMBTN", false)
			EmotesWheel:HideMMBtn("EmotesWheel")
		end,
		["dbkey"] = "MMBTN"
	})

	if EmotesWheel:GetConfig("KEYBIND", nil) == nil then EmotesWheel:INFO(EmotesWheel:Trans("LID_NOKEYBIND")) end
end)
