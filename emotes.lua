local _, EmotesWheel = ...
EmotesWheel.EMOTES = {"WAVE", "HELLO", "BYE", "THANK", "CHEER", "DANCE", "LAUGH", "APPLAUD", "BOW", "CRY", "FLEX", "KISS", "HUG", "POINT", "ROAR", "SALUTE", "SHRUG", "SIT", "SLEEP", "KNEEL", "YES", "NO", "AGREE", "GREET", "CONGRATULATE", "CHICKEN", "RUDE", "THREATEN", "TRAIN", "FOLLOW", "WAIT", "CHARGE", "OPENFIRE", "FLEE", "HEALME", "OOM"}
EmotesWheel.DEFAULTSLOTS = {"WAVE", "THANK", "CHEER", "DANCE", "LAUGH", "APPLAUD", "BOW", "SALUTE", "FLEX", "ROAR", "KISS", "SHRUG"}
EmotesWheel.ICONFALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
EmotesWheel.EMOTEICONS = {
	["WAVE"] = "INV_Gauntlets_04",
	["HELLO"] = "INV_Misc_Note_01",
	["BYE"] = "INV_Misc_Rune_01",
	["THANK"] = "Spell_Holy_HolyBolt",
	["CHEER"] = "Spell_Holy_PowerInfusion",
	["DANCE"] = "Spell_Holy_HolyNova",
	["LAUGH"] = "Ability_Hunter_Pet_Hyena",
	["APPLAUD"] = "INV_Gauntlets_05",
	["BOW"] = "Spell_Holy_DevotionAura",
	["CRY"] = "Spell_Frost_FrostShock",
	["FLEX"] = "Spell_Nature_Strength",
	["KISS"] = "Spell_Shadow_Charm",
	["HUG"] = "Spell_Holy_PrayerOfHealing02",
	["POINT"] = "Ability_Hunter_SniperShot",
	["ROAR"] = "Ability_Druid_DemoralizingRoar",
	["SALUTE"] = "INV_Shield_06",
	["SHRUG"] = "INV_Misc_QuestionMark",
	["SIT"] = "Spell_Misc_Drink",
	["SLEEP"] = "Spell_Nature_Sleep",
	["KNEEL"] = "Spell_Holy_PrayerOfFortitude",
	["YES"] = "Spell_ChargePositive",
	["NO"] = "Spell_ChargeNegative",
	["AGREE"] = "Spell_Holy_SealOfWisdom",
	["GREET"] = "Spell_Holy_SealOfSalvation",
	["CONGRATULATE"] = "INV_Misc_Gift_01",
	["CHICKEN"] = "Spell_Magic_PolymorphChicken",
	["RUDE"] = "Spell_Shadow_CurseOfTounges",
	["THREATEN"] = "INV_Sword_04",
	["TRAIN"] = "Ability_Mount_MechaStrider",
	["FOLLOW"] = "Ability_Tracking",
	["WAIT"] = "INV_Misc_PocketWatch_01",
	["CHARGE"] = "Ability_Warrior_Charge",
	["OPENFIRE"] = "Spell_Fire_FlameBolt",
	["FLEE"] = "Ability_Rogue_Sprint",
	["HEALME"] = "Spell_Holy_Heal",
	["OOM"] = "Spell_Shadow_ManaBurn"
}

local icons = {}
function EmotesWheel:GetEmoteIcon(token)
	if token == nil or EmotesWheel.EMOTEICONS[token] == nil then return EmotesWheel.ICONFALLBACK end
	if icons[token] == nil then
		local path = "Interface\\Icons\\" .. EmotesWheel.EMOTEICONS[token]
		if GetFileIDFromPath and GetFileIDFromPath(path) == nil then path = EmotesWheel.ICONFALLBACK end
		icons[token] = path
	end
	return icons[token]
end

local slashes = nil
local function BuildSlashes()
	slashes = {}
	for i = 1, 1000 do
		local token = _G["EMOTE" .. i .. "_TOKEN"]
		local cmd = _G["EMOTE" .. i .. "_CMD1"]
		if type(token) == "string" and type(cmd) == "string" and slashes[token] == nil then slashes[token] = cmd end
	end
end

function EmotesWheel:GetEmoteSlash(token)
	if token == nil or token == "" then return nil end
	if slashes == nil then BuildSlashes() end
	return slashes[token] or ("/" .. strlower(token))
end

function EmotesWheel:GetEmoteName(token)
	local slash = EmotesWheel:GetEmoteSlash(token)
	if slash == nil then return "" end
	local name = slash:gsub("^/", "")
	return strupper(strsub(name, 1, 1)) .. strsub(name, 2)
end

function EmotesWheel:GetEmoteChoices()
	local choices = {}
	for _, token in ipairs(EmotesWheel.EMOTES) do
		local name = EmotesWheel:GetEmoteName(token)
		tinsert(choices, {
			["value"] = token,
			["name"] = name,
			["label"] = format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", EmotesWheel:GetEmoteIcon(token), name)
		})
	end

	table.sort(choices, function(a, b) return a["name"] < b["name"] end)
	return choices
end

function EmotesWheel:PerformEmoteInsecure(token)
	if EmotesWheel:GetWoWBuild() ~= "RETAIL" and DoEmote then
		DoEmote(token)
		return true
	end

	return false
end
