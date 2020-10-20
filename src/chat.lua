local AddonName, Addon = ...
local Chat = Addon.Chat
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local FCF_GetNumActiveChatFrames = _G.FCF_GetNumActiveChatFrames
local strjoin = _G.strjoin

local HEADING = DCL:ColorString(("[%s]"):format(AddonName), Colors.Primary)

function Chat:Debug(...)
  --@debug@
  print(DCL:ColorString(("[%s Debug]"):format(AddonName), Colors.Red), ...)
  --@end-debug@
end

function Chat:Print(...)
  if DB.Global and DB.Global.chat.enabled then
    local chatFrame = _G[DB.Global.chat.frame] or _G.DEFAULT_CHAT_FRAME
    chatFrame:AddMessage(strjoin(" ", HEADING, ...))
  end
end

function Chat:Verbose(...)
  if DB.Global and DB.Global.chat.verbose then
    self:Print(...)
  end
end

function Chat:Reason(reason)
  if DB.Global.chat.reason then
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
