-- ========================================
-- RACE TV v4 // core/layout.lua
-- Auto-posicionamento (técnica CMRT settings.win stuff):
-- ac.getAppWindows + ac.accessAppWindow:move/resize
-- Presets proporcionais para 16:9, escala pela resolução real.
-- ========================================
local M = {}

local ac = ac
local vec2 = vec2

-- posições em 1920x1080 (x, y, w, h). Windows fora da lista ficam manuais.
local PRESET_1080 = {
  ['TV Tower']        = { 24, 130, 300, 420 },
  ['TV Telemetry']    = { 720, 24, 480, 72 },
  ['TV Onboard Top']  = { 720, 104, 480, 52 },
  ['TV Alert']        = { 730, 165, 460, 56 },
  ['TV Battle']       = { 630, 890, 660, 130 },
  ['TV Onboard Bar']  = { 24, 890, 470, 100 },
  ['TV Timing']       = { 1586, 130, 310, 170 },
  ['TV Inputs']       = { 1586, 310, 310, 140 },
  ['TV Spotter']      = { 1696, 740, 200, 220 },
}

function M.apply()
  local sim = ac.getSim()
  if not sim then return 0 end
  local rw, rh = sim.windowWidth or 1920, sim.windowHeight or 1080
  local kx, ky = rw / 1920, rh / 1080
  local all = ac.getAppWindows()
  if not all then return 0 end
  local moved = 0
  for i = 1, #all do
    local app = all[i]
    if app and app.title then
      local p = PRESET_1080[app.title]
      if p and app.name then
        local ok, win = pcall(ac.accessAppWindow, app.name)
        if ok and win then
          pcall(win.move, win, vec2(p[1] * kx, p[2] * ky))
          pcall(win.resize, win, vec2(p[3] * kx, p[4] * ky))
          moved = moved + 1
        end
      end
    end
  end
  return moved
end

return M
