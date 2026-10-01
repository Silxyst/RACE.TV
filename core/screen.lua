local M = {}

-- uiScale belongs to ac.getUI(), NOT the runtime state_sim FFI structure.
function M.size()
  local sim = ac.getSim()
  local factor = 1
  if ac.getUI then
    local ok, value = pcall(function() return ac.getUI().uiScale end)
    if ok and type(value) == 'number' and value > 0 and value == value then factor = value end
  end
  local width, height = sim and sim.windowWidth or 1920, sim and sim.windowHeight or 1080
  return vec2(math.max(128, width / factor), math.max(128, height / factor))
end

return M
