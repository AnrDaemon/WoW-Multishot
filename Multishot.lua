Multishot = LibStub("AceAddon-3.0"):NewAddon("Multishot", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

MultishotConfig = {}
Multishot_dbBoss = LibStub("LibBossIDs-1.0").BossIDs

local isEnabled, isDelayed, oldalpha
local strMatch = string.gsub(FACTION_STANDING_CHANGED, "%%%d?%$?s", "(.+)")
local player = UnitName("player")

function Multishot:OnEnable()
  self:RegisterEvent("CHAT_MSG_SYSTEM")
  self:RegisterEvent("PLAYER_LEVEL_UP")
  self:RegisterEvent("ACHIEVEMENT_EARNED")
  self:RegisterEvent("TRADE_ACCEPT_UPDATE")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
--  self:RegisterEvent("GUILD_PERK_UPDATE")
--  self:RegisterEvent("GUILD_ACHIEVEMENT_UPDATE")
  self:RegisterEvent("SCREENSHOT_FAILED", "Debug")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterChatCommand("multishot", function()
    InterfaceOptionsFrame_OpenToCategory(Multishot.PrefPane)
  end)
end

--function Multishot:GUILD_PERK_UPDATE(strEvent)
--  if MultishotConfig.guildachievement then self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay1, strEvent) end
--end

--function Multishot:GUILD_ACHIEVEMENT_UPDATE(strEvent)
--  if MultishotConfig.guildlevelup then self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay1, strEvent) end
--end

function Multishot:PLAYER_LEVEL_UP(strEvent)
  if MultishotConfig.levelup then self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay1, strEvent) end
end

function Multishot:ACHIEVEMENT_EARNED(strEvent)
  if MultishotConfig.achievement then self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay1, strEvent) end
end

function Multishot:TRADE_ACCEPT_UPDATE(strEvent, strPlayer, strTarget)
  if ((strPlayer == 1 and strTarget == 0) or (strPlayer == 0 and strTarget == 1)) and MultishotConfig.trade then
    self:CustomScreenshot(strEvent)
  end
end

function Multishot:CHAT_MSG_SYSTEM(strEvent, strMessage)
  if MultishotConfig.repchange then
    if string.match(strMessage, strMatch) then
      self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay1, strEvent) 
    end
  end
end

function Multishot:COMBAT_LOG_EVENT_UNFILTERED(strEvent, ...)
  local strType, sourceGuid, _, _, destGuid = select(2, ...)
  local currentId = tonumber("0x" .. string.sub(destGuid, 7, 10))
  if strType == "UNIT_DIED" or strType == "PARTY_KILL" then
    local inInstance, instanceType = IsInInstance()
    if not (sourceGuid == UnitGUID("player") and MultishotConfig.rares and Multishot_dbRares[currentId]) and strType == "PARTY_KILL" then return end
    if not ((instanceType == "party" and MultishotConfig.party) or (instanceType == "raid" and MultishotConfig.raid)) then return end
    if not (Multishot_dbWhitelist[currentId] or Multishot_dbCataclysm[currentId] or Multishot_dbBoss[currentId]) or Multishot_dbBlacklist[currentId] then return end
    if MultishotConfig.firstkill and MultishotConfig.history[player .. currentId] then return end
    MultishotConfig.history[player .. currentId] = true
    if UnitIsDead("player") then
      self:PLAYER_REGEN_ENABLED(strType)
    else
      isDelayed = currentId
    end
  end
end

function Multishot:PLAYER_REGEN_ENABLED(strEvent)
  if isDelayed then 
    self:ScheduleTimer("CustomScreenshot", MultishotConfig.delay2, strEvent .. isDelayed)
    isDelayed = nil
  end
end

function Multishot:SCREENSHOT_SUCCEEDED(Q)
  if oldalpha and oldalpha > 0 then
  	UIParent:SetAlpha(oldalpha)
  	oldalpha = nil
  end
  self:UnregisterEvent("SCREENSHOT_SUCCEEDED")
end

function Multishot:CustomScreenshot(strDebug)
  self:Debug(strDebug)
  if MultishotConfig.charpane then ToggleCharacter("PaperDollFrame") end
  if MultishotConfig.close and strDebug ~= "TRADE_ACCEPT_UPDATE" then CloseAllWindows() end
  if MultishotConfig.played and strDebug ~= "PLAYER_LEVEL_UP" then RequestTimePlayed() end
  self:RegisterEvent("SCREENSHOT_SUCCEEDED")
  if MultishotConfig.uihide and (string.find(strDebug, "PLAYER_REGEN_ENABLED") or string.find(strDebug, "UNIT_DIED") or string.find(strDebug, "PARTY_KILL") or string.find(strDebug, "PLAYER_LEVEL_UP")) then
    oldalpha = UIParent:GetAlpha()
    UIParent:SetAlpha(0)
  end
  Screenshot()
end

function Multishot:Debug(strMessage)
  if MultishotConfig.debug then self:Print(strMessage) end
end