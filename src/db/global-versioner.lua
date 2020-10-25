local _, Addon = ...
local GlobalVersioner = Addon.GlobalVersioner

-- Versions
GlobalVersioner.CURRENT_VERSION = 1
GlobalVersioner.DEFAULT_VERSION = -1

GlobalVersioner.versions = {}

-- ============================================================================
-- Functions
-- ============================================================================

function GlobalVersioner:Run(global)
  if global.version == self.DEFAULT_VERSION then
    global.version = self.CURRENT_VERSION
  end

  while global.version < self.CURRENT_VERSION do
    self.versions[global.version+1](global)
  end
end

function GlobalVersioner:_AddVersion(version, func)
  assert(type(version) == "number")
  assert(type(func) == "function")
  assert(version > 1 and version <= GlobalVersioner.CURRENT_VERSION)
  assert(self.versions[version] == nil)
  self.versions[version] = function(global)
    func(global)
    global.version = version
  end
end
