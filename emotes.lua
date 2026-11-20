local _, EmotesWheel = ...
EmotesWheel.EMOTES = {"WAVE", "HELLO", "BYE", "THANK", "CHEER", "DANCE", "LAUGH", "APPLAUD", "BOW", "CRY", "FLEX", "KISS", "HUG", "POINT", "ROAR", "SALUTE", "SHRUG", "SIT", "SLEEP", "KNEEL", "YES", "NO", "AGREE", "GREET", "CONGRATULATE", "CHICKEN", "RUDE", "THREATEN", "TRAIN", "FOLLOW", "WAIT", "CHARGE", "OPENFIRE", "FLEE", "HEALME", "OOM"}
EmotesWheel.DEFAULTSLOTS = {"WAVE", "THANK", "CHEER", "DANCE", "LAUGH", "APPLAUD", "BOW", "SALUTE", "FLEX", "ROAR", "KISS", "SHRUG"}
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
		tinsert(choices, {
			["value"] = token,
			["label"] = EmotesWheel:GetEmoteName(token)
		})
	end

	table.sort(choices, function(a, b) return a["label"] < b["label"] end)
	return choices
end

function EmotesWheel:PerformEmoteInsecure(token)
	if EmotesWheel:GetWoWBuild() ~= "RETAIL" and DoEmote then
		DoEmote(token)
		return true
	end

	return false
end
