local _, EmotesWheel = ...
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local W = {
	["RADIUS"] = 110,
	["SLOTSIZE"] = 60,
	["CENTERSIZE"] = 70,
	["DEADZONE"] = 32,
	["TWOPI"] = math.pi * 2
}

local wheel = nil
local keyButton = nil
local pendingBinding = false
function EmotesWheel:GetConfig(key, default)
	EmotesWheelDB = EmotesWheelDB or {}
	local value = EmotesWheel:GV(EmotesWheelDB, key, default)
	EmotesWheel:SV(EmotesWheelDB, key, value)
	return value
end

function EmotesWheel:SetConfig(key, value)
	EmotesWheelDB = EmotesWheelDB or {}
	EmotesWheel:SV(EmotesWheelDB, key, value)
end

function EmotesWheel:GetSlotCount()
	return EmotesWheel:GetConfig("SLOTS", 8)
end

function EmotesWheel:GetSlotEmote(index)
	return EmotesWheel:GetConfig("SLOT" .. index, EmotesWheel.DEFAULTSLOTS[index] or "WAVE")
end

local function Round(texture)
	if texture.AddMaskTexture == nil then return end
	local parent = texture:GetParent()
	if parent == nil or parent.CreateMaskTexture == nil then return end
	local mask = parent:CreateMaskTexture()
	mask:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(texture)
	texture:AddMaskTexture(mask)
end

local function CreateCircle(parent, size, layer)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(size, size)
	frame.Border = frame:CreateTexture(nil, layer or "BACKGROUND", nil, 1)
	frame.Border:SetAllPoints(frame)
	frame.Border:SetColorTexture(0.8, 0.65, 0.2, 0.9)
	Round(frame.Border)
	frame.Fill = frame:CreateTexture(nil, layer or "BACKGROUND", nil, 2)
	frame.Fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	frame.Fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	Round(frame.Fill)
	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.Text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.Text:SetWidth(size - 8)
	frame.Text:SetWordWrap(true)
	return frame
end

local function SetSlotActive(slot, active)
	if active then
		slot.Fill:SetColorTexture(0.85, 0.6, 0.1, 0.95)
		slot.Text:SetTextColor(1, 1, 1)
		slot:SetSize(W.SLOTSIZE * 1.15, W.SLOTSIZE * 1.15)
	else
		slot.Fill:SetColorTexture(0.08, 0.08, 0.1, 0.85)
		slot.Text:SetTextColor(1, 0.82, 0)
		slot:SetSize(W.SLOTSIZE, W.SLOTSIZE)
	end
end

function EmotesWheel:BuildWheel()
	if wheel == nil then
		wheel = CreateFrame("Frame", "EmotesWheelFrame", UIParent)
		wheel:SetFrameStrata("DIALOG")
		wheel:SetClampedToScreen(true)
		wheel:Hide()
		wheel.Ring = wheel:CreateTexture(nil, "BACKGROUND", nil, 0)
		wheel.Ring:SetAllPoints(wheel)
		wheel.Ring:SetColorTexture(0, 0, 0, 0.45)
		Round(wheel.Ring)
		wheel.Center = CreateCircle(wheel, W.CENTERSIZE, "ARTWORK")
		wheel.Center:SetPoint("CENTER", wheel, "CENTER", 0, 0)
		wheel.Center.Fill:SetColorTexture(0.05, 0.05, 0.06, 0.95)
		wheel.Center.Text:SetFontObject("GameFontNormal")
		wheel.slots = {}
		wheel:SetScript("OnUpdate", function() EmotesWheel:UpdateSelection() end)
	end

	local size = (W.RADIUS + W.SLOTSIZE) * 2
	wheel:SetSize(size, size)
	local count = EmotesWheel:GetSlotCount()
	local step = W.TWOPI / count
	for i = 1, math.max(count, #wheel.slots) do
		local slot = wheel.slots[i]
		if i <= count then
			if slot == nil then
				slot = CreateCircle(wheel, W.SLOTSIZE, "BORDER")
				wheel.slots[i] = slot
			end

			local angle = (i - 1) * step
			slot:ClearAllPoints()
			slot:SetPoint("CENTER", wheel, "CENTER", W.RADIUS * math.sin(angle), W.RADIUS * math.cos(angle))
			slot.token = EmotesWheel:GetSlotEmote(i)
			slot.Text:SetText(EmotesWheel:GetEmoteName(slot.token))
			SetSlotActive(slot, false)
			slot:Show()
		elseif slot then
			slot:Hide()
		end
	end

	wheel.count = count
	wheel.step = step
	wheel:SetScale(EmotesWheel:GetConfig("SCALE", 1))
end

function EmotesWheel:UpdateSelection()
	if wheel == nil or not wheel:IsShown() then return end
	local x, y = GetCursorPosition()
	local scale = wheel:GetEffectiveScale()
	local dx = x / scale - wheel.cx
	local dy = y / scale - wheel.cy
	local selected = nil
	if dx * dx + dy * dy > W.DEADZONE * W.DEADZONE then
		local angle = math.atan2(dx, dy)
		selected = math.floor(((angle + W.TWOPI + wheel.step / 2) % W.TWOPI) / wheel.step) + 1
		if selected > wheel.count then selected = 1 end
	end

	if selected == wheel.selected then return end
	if wheel.selected and wheel.slots[wheel.selected] then SetSlotActive(wheel.slots[wheel.selected], false) end
	wheel.selected = selected
	if selected then
		SetSlotActive(wheel.slots[selected], true)
		wheel.Center.Text:SetText(EmotesWheel:GetEmoteName(wheel.slots[selected].token))
	else
		wheel.Center.Text:SetText(EmotesWheel:Trans("LID_CANCEL"))
	end
end

function EmotesWheel:IsWheelOpen()
	return wheel ~= nil and wheel:IsShown()
end

function EmotesWheel:OpenWheel()
	if wheel == nil then EmotesWheel:BuildWheel() end
	wheel:SetScale(EmotesWheel:GetConfig("SCALE", 1))
	wheel:ClearAllPoints()
	local scale = wheel:GetEffectiveScale()
	if EmotesWheel:GetConfig("POSITION", "CURSOR") == "CURSOR" then
		local x, y = GetCursorPosition()
		wheel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	else
		wheel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	wheel:Show()
	wheel.cx, wheel.cy = wheel:GetCenter()
	wheel.selected = -1
	EmotesWheel:UpdateSelection()
end

function EmotesWheel:CloseWheel()
	if wheel == nil then return nil end
	EmotesWheel:UpdateSelection()
	local token = nil
	if wheel.selected and wheel.selected > 0 and wheel.slots[wheel.selected] then token = wheel.slots[wheel.selected].token end
	if wheel.selected and wheel.slots[wheel.selected] then SetSlotActive(wheel.slots[wheel.selected], false) end
	wheel.selected = nil
	wheel:Hide()
	return token
end

local function ArmEmote(token)
	if InCombatLockdown() then
		if token and not EmotesWheel:PerformEmoteInsecure(token) then EmotesWheel:INFO(EmotesWheel:Trans("LID_NOTINCOMBAT")) end
		return
	end

	if token then
		keyButton:SetAttribute("type", "macro")
		keyButton:SetAttribute("macrotext", EmotesWheel:GetEmoteSlash(token))
	else
		keyButton:SetAttribute("type", nil)
	end
end

local function OnKeyPreClick(_, _, down)
	local hold = EmotesWheel:GetConfig("MODE", "HOLD") == "HOLD"
	if down then
		if not EmotesWheel:IsWheelOpen() then
			keyButton.ewOpenedNow = true
			EmotesWheel:OpenWheel()
		else
			keyButton.ewOpenedNow = false
		end

		return
	end

	if not hold and keyButton.ewOpenedNow then
		ArmEmote(nil)
		return
	end

	ArmEmote(EmotesWheel:CloseWheel())
end

local function OnKeyPostClick(_, _, down)
	if down or InCombatLockdown() then return end
	keyButton:SetAttribute("type", nil)
end

function EmotesWheel:ApplyKeybind()
	if keyButton == nil then return end
	if InCombatLockdown() then
		pendingBinding = true
		return
	end

	pendingBinding = false
	ClearOverrideBindings(keyButton)
	local key = EmotesWheel:GetConfig("KEYBIND", nil)
	if key == nil or key == "" then return end
	SetOverrideBindingClick(keyButton, true, key, "EmotesWheelKeyButton")
end

function EmotesWheel:InitWheel()
	keyButton = CreateFrame("Button", "EmotesWheelKeyButton", UIParent, "SecureActionButtonTemplate")
	keyButton:RegisterForClicks("AnyDown", "AnyUp")
	keyButton:SetScript("PreClick", OnKeyPreClick)
	keyButton:SetScript("PostClick", OnKeyPostClick)
	if not InCombatLockdown() then
		keyButton:SetAttribute("useOnKeyDown", false)
		keyButton:SetAttribute("type", nil)
	else
		pendingBinding = true
	end

	local combat = CreateFrame("Frame")
	combat:RegisterEvent("PLAYER_REGEN_ENABLED")
	combat:RegisterEvent("PLAYER_REGEN_DISABLED")
	combat:SetScript("OnEvent", function(_, event)
		if InCombatLockdown() then return end
		keyButton:SetAttribute("type", nil)
		if event == "PLAYER_REGEN_ENABLED" then
			keyButton:SetAttribute("useOnKeyDown", false)
			if pendingBinding then EmotesWheel:ApplyKeybind() end
		end
	end)

	EmotesWheel:BuildWheel()
	EmotesWheel:ApplyKeybind()
end
