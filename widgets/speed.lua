-- ========================================
-- VELOCITY SLASH // widgets/speed.lua
-- Speed + Gear + RPM slash bar + shift flash
-- Mostra carro focado (hibrido piloto/transmissao)
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm
local math = math

local isVisible = false
local pulse = 0

function M.init() end
function M.update(dt) pulse = pulse + (dt or 0.016) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

local function gearStr(g)
  if g == 0 then return 'N' end
  if g == -1 then return 'R' end
  return tostring(g or '-')
end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 400 * s, 190 * s
    draw.slashPanel(0, 0, W, H, cfg, { slash = 26 * s })
    draw.header(0, 0, W, cfg, 'SPEED // GEAR', pulse * 4)

    local sim = ac.getSim()
    local focIdx = (sim and sim.focusedCar) or 0
    local car = ac.getCar(focIdx)
    if not car then return end

    local kmh = car.speedKmh or 0
    if cfg.mph then kmh = kmh * 0.621371 end
    local unit = cfg.mph and 'MPH' or 'KM/H'
    local gear = gearStr(car.gear)
    local rpm = car.rpm or 0
    local limiter = car.rpmLimiter or 0
    if type(limiter) ~= 'number' or limiter <= 1000 then limiter = 7500 end
    local frac = draw.clamp(rpm / limiter, 0, 1)

    -- RPM bar (slash style)
    local bx, by, bw, bh = 12 * s, 52 * s, W - 24 * s, 12 * s
    draw.hbar(bx, by, bw, bh, frac, draw.accent(cfg, 1), rgbm(1, 1, 1, 0.12), 3)
    -- shift flash: >92%
    if frac > 0.92 then
      local bl = 0.4 + 0.4 * math.sin(pulse * 18)
      ui.drawRectFilled(vec2(0, 0), vec2(W, H), rgbm(1, 0.15, 0.2, bl * 0.25), 7)
      draw.text(12 * s, 66 * s, 'SHIFT!', 13 * s, rgbm(1, 0.3, 0.35, 1), ui.Alignment.Start, 80 * s, 18 * s)
    end
    -- segmentos RPM
    for i = 1, 9 do
      local sx = bx + (bw / 10) * i
      ui.drawLine(vec2(sx, by), vec2(sx, by + bh), rgbm(0, 0, 0, 0.55), 1)
    end

    -- GEAR gigante
    draw.text(12 * s, 84 * s, gear, 74 * s, draw.white(1), ui.Alignment.Center, 110 * s, 84 * s)
    -- divisor slash
    ui.drawLine(vec2(132 * s, 88 * s), vec2(118 * s, 168 * s), draw.accent(cfg, 1), 3 * s)

    -- SPEED
    draw.text(136 * s, 86 * s, string.format('%.0f', kmh), 62 * s, draw.white(1), ui.Alignment.Start, 170 * s, 66 * s)
    draw.text(140 * s, 148 * s, unit .. '  •  ' .. string.format('%.0f', rpm) .. ' RPM', 14 * s, draw.dim(1), ui.Alignment.Start, 240 * s, 20 * s)

    -- quem é
    local label = 'YOU'
    if focIdx ~= 0 then
      local okN, nm = pcall(ac.getDriverName, focIdx)
      if okN and nm then label = draw.shortName(tostring(nm)) end
    end
    draw.text(W - 132 * s, 66 * s, label, 12 * s, draw.accent(cfg, 1), ui.Alignment.End, 120 * s, 18 * s)
  end)
  if not ok then ac.debug('VS Speed', err) end
end

return M
