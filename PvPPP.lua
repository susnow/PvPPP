local Locales = {
	zhCN = { msg = "荣誉击杀:%s/%s", avg = "过去的一小时中一共获取了 %s 个荣誉击杀"  },
	zhTW = { msg = "榮譽擊殺:%s/%s", avg = "過去的一小時中一共獲取了 %s 個榮譽擊殺"  },
	enUS = { msg = "Honorable kills:%s/%s", avg = "You've get %s 's honorable kills in last hour" },
}
local L = Locales[GetLocale()]
local NextLimit = { 100, 500, 1000, 5000, 10000, 25000, 50000, 100000,250000,500000,1000000 }
local GetNextLimit = function(kills)
	for i =1, #NextLimit do
		if kills < NextLimit[i] then
			return NextLimit[i]
		elseif kills >= NextLimit[#NextLimit] then
			return
		end
	end
end

local loadKills = GetPVPLifetimeStats()
local oldKills = GetPVPLifetimeStats()
local oldTime = GetTime()
UIErrorsFrame.nextUpdate = 0
UIErrorsFrame:SetScript("OnUpdate",function(self,elapsed)
	self.nextUpdate = self.nextUpdate + elapsed
	if self.nextUpdate > 1 then
		local newTime = GetTime()
		local newKills = GetPVPLifetimeStats()
		if newKills > oldKills then
			local msg = string.format(L.msg, newKills, GetNextLimit(newKills))
			self:AddMessage(msg,1,1,0,1)
			oldKills = newKills
		elseif newKills == NextLimit[#NextLimit] then
			self:SetScript("OnUpdate",nil)
		end
		self.nextUpdate = 0
	end
end)

local PVP = CreateFrame("Frame") 
local media = "Interface\\AddOns\\PvPPP\\media\\"
local texFile = "Interface\\Buttons\\WHITE8X8"
local f = WorldStateScoreFrame
local classes = {"MAGE","ROGUE","PRIEST","HUNTER","WARLOCK","WARRIOR","PALADIN","DEATHKNIGHT","DRUID","SHAMAN"}
local buttons = {}

local members = {
	MAGE = "",
	ROGUE = "",
	PRIEST = "",
	HUNTER = "",
	WARLOCK = "",
	WARRIOR = "",
	PALADIN = "",
	DEATHKNIGHT = "",
	DRUID = "",
	SHAMAN = "",
}

local LM = {
	DAMAGER = 0,
	HEALER = 0,
	TANK = 0,
}
local BL = {
	DAMAGER = 0,
	HEALER = 0,
	TANK = 0,
}

local GetTalentStr = {
	["冰霜"] = "DAMAGER",
	["火焰"] = "DAMAGER",
	["奥术"] = "DAMAGER",
	["刺杀"] = "DAMAGER",
	["战斗"] = "DAMAGER",
	["敏锐"] = "DAMAGER",
	["戒律"] = "HEALER",
	["神圣"] = "HEALER",
	["暗影"] = "DAMAGER",
	["野兽控制"] = "DAMAGER",
	["射击"] = "DAMAGER",
	["生存"] = "DAMAGER",
	["痛苦"] = "DAMAGER",
	["恶魔学识"] = "DAMAGER",
	["毁灭"] = "DAMAGER",
	["武器"] = "DAMAGER",
	["狂怒"] = "DAMAGER",
	["防护"] = "TANK",
	["惩戒"] = "DAMAGER",
	["鲜血"] = "TANK",
	["邪恶"] = "DAMAGER",
	["平衡"] = "DAMAGER",
	["野性战斗"] = "TANK",
	["恢复"] = "HEALER",
	["元素"] = "DAMAGER",
	["增强"] = "DAMAGER"
}

for num = 1, 10 do
	local button = CreateFrame("Button",format("%s%s","ClassButton_",classes[num]),f)
	button:SetSize(20,20)
	button:SetPoint("BOTTOMRIGHT",f,-num*25,18)
	button.bg = button:CreateTexture(nil,"OVERLAY")
	button.bg:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	local coords = CLASS_BUTTONS[classes[num]]
	button.bg:SetTexCoord(coords[1],coords[2],coords[3],coords[4])
	button.bg:SetAllPoints(button)
	button.num = button:CreateFontString(nil,"OVERLAY","ChatFontNormal")
	button.num:SetPoint("TOP",button,"BOTTOM",0,-2)
	button.num:SetText(0)
	buttons[num] = button
end

local function CreateFlagButton(name)
	local button = CreateFrame("Button","FlagButton_"..name,_G["WorldStateAlwaysUpFrame"])	
	button:Hide()
	button:SetSize(16,16)
	button.bg = button:CreateTexture(nil,"OVERLAY")
	button.bg:SetAllPoints(button)
	button.bg:SetTexture(media..name)
	button.LM = button:CreateFontString(nil,"OVERLAY","GameFontNormal")
	button.LM:SetPoint("BOTTOM",button,"TOP",0,4)
	button.BL = button:CreateFontString(nil,"OVERLAY","GameFontNormal")
	button.BL:SetPoint("TOP",button,"BOTTOM",0,-4)
	if name == "DAMAGER" then
		button:SetPoint("RIGHT",_G["WorldStateAlwaysUpFrame"],"LEFT",-50,-8)
		button.LM:SetText(LM["DAMAGER"])
		button.BL:SetText(BL["DAMAGER"])
	elseif name == "HEALER" then
		button:SetPoint("RIGHT",_G["WorldStateAlwaysUpFrame"],"LEFT",-70,-8)
		button.LM:SetText(LM["HEALER"])
		button.BL:SetText(BL["HEALER"])
	elseif name == "TANK" then
		button:SetPoint("RIGHT",_G["WorldStateAlwaysUpFrame"],"LEFT",-90,-8)
		button.LM:SetText(LM["TANK"])
		button.BL:SetText(BL["TANK"])
	end
end

CreateFlagButton("DAMAGER")
CreateFlagButton("TANK")
CreateFlagButton("HEALER")


local function GetFactionTalentFlag(faction,flag)
	local button = _G["FlagButton_"..flag]
	button:Show()
	if faction == 0 then
		BL[flag] = BL[flag] + 1
		button.BL:SetText(BL[flag])						
	elseif faction == 1 then
		LM[flag] = LM[flag] + 1
		button.LM:SetText(LM[flag])						
	end
end

local function GetFactionColor(faction,str)
	if faction == 0 then
		str = format("%s%s%s","|h|cffff0000",str,"|r")	
	elseif faction == 1 then
		str = format("%s%s%s","|h|cff00ccff",str,"|r")	
	end
	return str
end

local function UpdateBattleMembers()
	if not _G["WorldStateScoreFrameLeaveButton"]:IsShown() then
		for i = 1, GetNumBattlefieldScores() do
			local name = select(1,GetBattlefieldScore(i))
			local faction = select(6,GetBattlefieldScore(i))
			local class = select(9,GetBattlefieldScore(i))
			local talent = select(16,GetBattlefieldScore(i))
			local function TalentIcon(talent)
				local talentIcon = ""
				if GetTalentStr[talent] == "DAMAGER" then
					talentIcon = "x"
				elseif GetTalentStr[talent] == "HEALER" then
					talentIcon = "+"
				elseif GetTalentStr[talent] == "TANK" then
					talentIcon = "T"
				end
				return talentIcon 
			end
			if GetTalentStr[talent]	== "DAMAGER" then
				GetFactionTalentFlag(faction,GetTalentStr[talent])
			elseif GetTalentStr[talent] == "HEALER" then
				GetFactionTalentFlag(faction,GetTalentStr[talent])
			elseif GetTalentStr[talent] == "TANK" then
				GetFactionTalentFlag(faction,GetTalentStr[talent])
			end
			if name then
				if members[class] == "" then
					members[class] = format("%s%s",TalentIcon(talent),GetFactionColor(faction,name))
				else
					members[class] = format("%s\n%s%s",members[class],TalentIcon(talent),GetFactionColor(faction,name)) 
				end
			end
			_G["ClassButton_"..class].num:SetText(tonumber(_G["ClassButton_"..class].num:GetText()) + 1) 
		end
	end
end

local function InitData()
	for k,v in pairs(members) do
		members[k] = ""
	end
	for num = 1, 10 do
		buttons[num].num:SetText(0)
	end
	for k,v in pairs(LM) do
		 LM[k]= 0
	end
	for k,v in pairs(BL) do
		BL[k] = 0
	end
end

PVP:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
PVP:RegisterEvent("ZONE_CHANGED_NEW_AREA")
PVP:HookScript("OnEvent",function(self,event)
	if event == "PLAYER_ENTERING_BATTLEGROUND" then 

		f:Show()
		f:Hide()
		InitData()
		UpdateBattleMembers()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if not UnitInBattleground("player") then
			InitData()
			_G["FlagButton_TANK"]:Hide()
			_G["FlagButton_DAMAGER"]:Hide()
			_G["FlagButton_HEALER"]:Hide()
		end
	end
end)

f:HookScript("OnShow",function()
	InitData()
	UpdateBattleMembers()
end)

for i = 1, #classes do
	_G["ClassButton_"..classes[i]]:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
		GameTooltip:AddLine(members[classes[i]],1,1,1)
		GameTooltip:Show()
	end)

	_G["ClassButton_"..classes[i]]:SetScript("OnLeave",function(self)
		GameTooltip:Hide()
	end)

end

f:HookScript("OnHide",function()
	for num =1, 10 do
		buttons[num].num:SetText(0)
	end
end)
f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
f:HookScript("OnEvent",function(self,event)
	InitData()
	UpdateBattleMembers()
end)

