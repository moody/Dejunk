--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- DejunkFrames: provides Dejunk frames with default functionality.

do -- Mixin basic Dejunk frame functionality
  local AddonName, DJ = ...

  local DejunkFrames = DJ.DejunkFrames
  local FrameFactory = DJ.FrameFactory

  local function MixinFrame(frame)
    -- Variables
    frame.Initialized = false
    frame.UI = {}

    --[[
    //*******************************************************************
    //                       Init/Deinit Functions
    //*******************************************************************
    --]]

    -- Initializes the frame.
    function frame:Initialize()
      if self.Initialized then return end
      self.Initialized = true

      self.UI.Frame = FrameFactory:CreateFrame()

      self:OnInitialize()
    end

    -- Additional initialize logic. Override when necessary.
    function frame:OnInitialize() end

    -- Deinitializes the frame.
    function frame:Deinitialize()
      if not self.Initialized then return end
      self.Initialized = false

      FrameFactory:ReleaseUI(self.UI)

      self:OnDeinitialize()
    end

    -- Additional deinitialize logic. Override when necessary.
    function frame:OnDeinitialize() end

    --[[
    //*******************************************************************
    //                       General Frame Functions
    //*******************************************************************
    --]]

    -- Displays the frame.
    function frame:Show()
      self.UI.Frame:Show()
    end

    -- Hides the frame.
    function frame:Hide()
      self.UI.Frame:Hide()
    end

    -- Toggles the frame.
    function frame:Toggle()
      if not self.UI.Frame:IsVisible() then
        self:Show()
      else
        self:Hide()
      end
    end

    -- Enables the frame.
    function frame:Enable()
      FrameFactory:EnableUI(self.UI)
    end

    -- Disables the frame.
    function frame:Disable()
      FrameFactory:DisableUI(self.UI)
    end

    -- Refreshes the frame.
    function frame:Refresh()
      FrameFactory:RefreshUI(self.UI)
    end

    -- Resizes the frame. Override when necessary.
    function frame:Resize() end

    --[[
    //*******************************************************************
    //                         Get & Set Functions
    //*******************************************************************
    --]]

    -- Gets the width of the frame.
    -- @return - the width of the frame
    function frame:GetWidth()
      return self.UI.Frame:GetWidth()
    end

    -- Sets the width of the frame.
    -- @param width - the new width
    function frame:SetWidth(width)
      self.UI.Frame:SetWidth(width)
    end

    -- Gets the height of the frame.
    -- @return - the height of the frame
    function frame:GetHeight()
      return self.UI.Frame:GetHeight()
    end

    -- Sets the height of the frame.
    -- @param height - the new height
    function frame:SetHeight(height)
      self.UI.Frame:SetHeight(height)
    end

    -- Sets the parent of the frame.
    -- @param parent - the new parent
    function frame:SetParent(parent)
      self.UI.Frame:SetParent(parent)
    end

    -- Sets the point of the frame.
    -- @param point - the new point
    function frame:SetPoint(...)
      self.UI.Frame:ClearAllPoints()
      self.UI.Frame:SetPoint(unpack(...))
    end
  end

  -- Perform mixins
  local pairs = pairs
  for k, v in pairs(DejunkFrames) do
    MixinFrame(v)
  end
end
