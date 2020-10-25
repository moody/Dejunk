local AddonName, Addon = ...
local Chat = Addon.Chat
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local FCF_GetNumActiveChatFrames = _G.FCF_GetNumActiveChatFrames
local strjoin = _G.strjoin

local FORCE_HEADING = DCL:ColorString(("[%s]"):format(AddonName), Colors.Yellow)
local HEADING = DCL:ColorString(("[%s]"):format(AddonName), Colors.Primary)

function Chat:Debug(...)
  --@debug@
  print(DCL:ColorString(("[%s Debug]"):format(AddonName), Colors.Red), ...)
  --@end-debug@
end

function Chat:Force(...)
  print(FORCE_HEADING, ...)
end

function Chat:Print(...)
  if DB.Profile and DB.Profile.general.chat.enabled then
    local chatFrame = _G[DB.Profile.general.chat.frame] or _G.DEFAULT_CHAT_FRAME
    chatFrame:AddMessage(strjoin(" ", HEADING, ...))
  end
end

function Chat:Verbose(...)
  if DB.Profile and DB.Profile.general.chat.verbose then
    self:Print(...)
  end
end

function Chat:Reason(reason)
  if DB.Profile and DB.Profile.general.chat.reason then
    self:Verbose("  -", reason)
  end
end

function Chat:GetDropdownList()
  local info = {}

  for i=1, FCF_GetNumActiveChatFrames() do
    info["ChatFrame" .. i] = _G["ChatFrame" .. i .. "Tab"]:GetText()
  end

  return info
end
