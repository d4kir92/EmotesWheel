local _, EmotesWheel = ...
EmotesWheel:SetAddonOutput()
local ewset = nil
local slotDropdowns = {}
local ADDED = "2026-11-20"
EmotesWheel.LANGUAGES = {{"English", "enUS"}, {"Deutsch", "deDE"}, {"Español (España)", "esES"}, {"Español (México)", "esMX"}, {"Français", "frFR"}, {"Italiano", "itIT"}, {"한국어", "koKR"}, {"Português (Brasil)", "ptBR"}, {"Русский", "ruRU"}, {"简体中文", "zhCN"}, {"繁體中文", "zhTW"}}
EmotesWheel.LanguageNames = {}
for _, info in ipairs(EmotesWheel.LANGUAGES) do
	EmotesWheel.LanguageNames[info[2]] = info[1]
end

function EmotesWheel:GetLanguage()
	local lang = type(EmotesWheelDB) == "table" and EmotesWheelDB["LANGUAGE"] or nil
	if lang ~= nil and EmotesWheel.LanguageNames[lang] ~= nil then return lang end
	if EmotesWheel.LanguageNames[GetLocale()] ~= nil then return GetLocale() end
	return "enUS"
end

function EmotesWheel:GetLanguageName(lang)
	lang = lang or EmotesWheel:GetLanguage()
	return EmotesWheel.LanguageNames[lang] or lang
end

EmotesWheel.LibTrans = EmotesWheel.Trans
function EmotesWheel:Trans(key, lang, ...)
	return EmotesWheel.LibTrans(self, key, lang or EmotesWheel:GetLanguage(), ...)
end

function EmotesWheel:SetLanguage(lang)
	if EmotesWheel.LanguageNames[lang] == nil or lang == EmotesWheel:GetLanguage() then return end
	EmotesWheelDB = EmotesWheelDB or {}
	if lang == GetLocale() then
		EmotesWheelDB["LANGUAGE"] = nil
	else
		EmotesWheelDB["LANGUAGE"] = lang
	end

	EmotesWheel:RefreshLanguage()
end

function EmotesWheel:RefreshLanguage()
	if ewset ~= nil then
		ewset:RefreshLanguage()
		if ewset.ewRefreshLanguageButton then ewset.ewRefreshLanguageButton() end
	end

	if EmotesWheel.WhatsNew then EmotesWheel.WhatsNew:RefreshLanguage() end
end

local function LanguageMenu(_, root)
	root:CreateTitle(EmotesWheel:Trans("LID_LANGUAGE"))
	for _, info in ipairs(EmotesWheel.LANGUAGES) do
		local lang = info[2]
		root:CreateRadio(format("%s (%s)", info[1], lang), function() return EmotesWheel:GetLanguage() == lang end, function() EmotesWheel:SetLanguage(lang) end)
	end
end

function EmotesWheel:AddLanguageButton(win)
	local parent = win.titleBar or win
	local button
	if EmotesWheel:GetWoWBuild() == "RETAIL" and EmotesWheel:CheckTemplates("WowStyle1DropdownTemplate") then
		button = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
		button:SetScale(0.8)
		button:SetSize(162.5, 25)
		button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -1.25)
		button:SetSelectionText(function() return EmotesWheel:GetLanguageName() end)
		button:SetTooltip(function(tooltip) tooltip:SetText(EmotesWheel:Trans("LID_LANGUAGE")) end)
		button:SetupMenu(LanguageMenu)
	else
		button = EmotesWheel:CreateButton(nil, parent)
		button:SetSize(130, 20)
		button:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -2)
		button.Arrow = button:CreateTexture(nil, "OVERLAY")
		button.Arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
		button.Arrow:SetSize(16, 16)
		button.Arrow:SetPoint("RIGHT", button, "RIGHT", -2, 0)
		button:SetScript("OnClick", function(sel)
			if MenuUtil and MenuUtil.CreateContextMenu then
				MenuUtil.CreateContextMenu(sel, LanguageMenu)
			else
				local current = 1
				for index, info in ipairs(EmotesWheel.LANGUAGES) do
					if info[2] == EmotesWheel:GetLanguage() then current = index end
				end

				EmotesWheel:SetLanguage(EmotesWheel.LANGUAGES[current % #EmotesWheel.LANGUAGES + 1][2])
			end
		end)

		button:SetScript("OnEnter", function(sel)
			GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
			GameTooltip:SetText(EmotesWheel:Trans("LID_LANGUAGE"))
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	local function RefreshButton()
		button:SetText(EmotesWheel:GetLanguageName())
	end

	RefreshButton()
	win.Language = button
	return RefreshButton
end

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

local function AddDropdown(key, default, choices, func, label, added)
	return ewset:AddDropdown({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["added"] = added,
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

	if EmotesWheel.WhatsNew then EmotesWheel.WhatsNew:AddSettingsCheckbox(ewset, ADDED) end

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
	AddDropdown("DESIGN", EmotesWheel.DESIGNDEFAULT, EmotesWheel:GetDesignChoices(), function() EmotesWheel:BuildWheel() end, nil, ADDED)
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

	UpdateSlotRows()
	ewset:ResumeLayout()
end

function EmotesWheel:InitSettings()
	ewset = EmotesWheel:CreateUIWindow({
		["name"] = "EmotesWheelSettings",
		["pTab"] = {"CENTER"},
		["width"] = EmotesWheel:GetConfig("WINDOWWIDTH", 600),
		["height"] = EmotesWheel:GetConfig("WINDOWHEIGHT", 520),
		["minWidth"] = 460,
		["minHeight"] = 240,
		["navigation"] = true,
		["onResize"] = function(width, height)
			EmotesWheel:SetConfig("WINDOWWIDTH", width)
			EmotesWheel:SetConfig("WINDOWHEIGHT", height)
		end,
		["getCollapsed"] = function(key) return GetCollapsed(key) end,
		["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
		["title"] = EmotesWheel:GetSettingsTitle()
	})

	ewset.ewRefreshLanguageButton = EmotesWheel:AddLanguageButton(ewset)
	BuildElements()
end

function EmotesWheel:GetSettingsTitle()
	return format("|T%s:16:16:0:0|t EmotesWheel v%s", EmotesWheel:GetAddonIcon(), EmotesWheel:GetVersion())
end

function EmotesWheel:InitWhatsNew()
	EmotesWheelDB["WHATSNEW"] = EmotesWheelDB["WHATSNEW"] or {}
	EmotesWheel.WhatsNew = EmotesWheel:CreateUIWhatsNew({
		["name"] = "EmotesWheelWhatsNew",
		["title"] = EmotesWheel:GetSettingsTitle(),
		["db"] = EmotesWheelDB["WHATSNEW"],
		["since"] = ADDED,
		["getSettings"] = function() return ewset end,
		["addLanguageButton"] = function(win) return EmotesWheel:AddLanguageButton(win) end
	})
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
	EmotesWheelDB = EmotesWheelDB or {}
	EmotesWheel:SetVersion()
	EmotesWheel:InitWhatsNew()
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
	C_Timer.After(2, function() EmotesWheel.WhatsNew:ShowIfNew() end)
end)
