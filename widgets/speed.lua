-- ========================================
-- ENDURO TV // widgets/speed.lua
-- Onboard telemetry solida (gear/speed/thr/brk/rpm)
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
    local W, H = 300 * s, 150 * s
    local headH = 24 * s

    local sim = ac.getSim()
    local foc = (sim and sim.focusedCar) or 0
    local car = ac.getCar(foc)
    if not car then return end

    -- header brand
    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)
    local okN, nm = pcall(ac.getDriverName, foc)
    local who = (foc == 0) and 'YOU' or draw.shortName(okN and nm or 'DRIVER')
    draw.textF(draw.FONT_HEAD, 8 * s, 0, 'ONBOARD  •  ' .. who, 13 * s, draw.WHITE, ui.Alignment.Start, W - 16 * s, headH)

    -- corpo navy
    ui.drawRectFilled(vec2(0, headH), vec2(W, H), draw.DARK)

    local kmh = car.speedKmh or 0
    if cfg.mph then kmh = kmh * 0.621371 end
    local rpm = car.rpm or 0
    local lim = car.rpmLimiter or 0
    if type(lim) ~= 'number' or lim < 1000 then lim = 7500 end
    local frac = draw.clamp(rpm / lim, 0, 1)

    -- RPM top bar fina
    ui.drawRectFilled(vec2(0, headH), vec2(W, headH + 5 * s), rgbm.from0255(50, 50, 60, 255))
    ui.drawRectFilled(vec2(0, headH), vec2(W * frac, headH + 5 * s), frac > 0.92 and rgbm.from0255(225, 6, 0, 255) or draw.WHITE)
    if frac > 0.92 then
      local bl = 0.5 + 0.5 * math.sin(pulse * 16)
      ui.drawRect(vec2(0.5, headH + 0.5), vec2(W - 0.5, H - 0.5), rgbm(1, 0.1, 0.1, bl), 2)
    end

    -- GEAR (esq, gigante)
    draw.textF(draw.FONT_NUM, 8 * s, headH + 12 * s, gearStr(car.gear), 64 * s, draw.WHITE, ui.Alignment.Center, 90 * s, 80 * s)
    -- divisor
    ui.drawRectFilled(vec2(102 * s, headH + 14 * s), vec2(104 * s, H - 34 * s), rgbm.from0255(70, 70, 85, 255))

    -- SPEED
    draw.textF(draw.FONT_NUM, 112 * s, headH + 12 * s, string.format('%.0f', kmh), 52 * s, draw.WHITE, ui.Alignment.Start, 170 * s, 60 * s)
    draw.textF(draw.FONT_TXT, 114 * s, headH + 66 * s, (cfg.mph and 'MPH' or 'KM/H') .. '  •  ' .. string.format('%.0f', rpm) .. ' RPM', 11 * s, draw.GRAY, ui.Alignment.Start, 180 * s, 16 * s)

    -- THR / BRK barras finas base
    local thr = draw.clamp(car.gas or 0, 0, 1)
    local brk = draw.clamp(car.brake or 0, 0, 1)
    local by = H - 26 * s
    -- THR
    draw.textF(draw.FONT_TXT, 8 * s, by, 'T', 11 * s, draw.GRAY, ui.Alignment.Center, 14 * s, 14 * s)
    ui.drawRectFilled(vec2(24 * s, by + 2 * s), vec2(24 * s + 120 * s, by + 12 * s), rgbm.from0255(40, 40, 52, 255))
    ui.drawRectFilled(vec2(24 * s, by + 2 * s), vec2(24 * s + 120 * s * thr, by + 12 * s), rgbm.from0255(0, 200, 80, 255))
    -- BRK
    draw.textF(draw.FONT_TXT, 152 * s, by, 'B', 11 * s, draw.GRAY, ui.Alignment.Center, 14 * s, 14 * s)
    ui.drawRectFilled(vec2(168 * s, by + 2 * s), vec2(168 * s + 120 * s, by + 12 * s), rgbm.from0255(40, 40, 52, 255))
    ui.drawRectFilled(vec2(168 * s, by + 2 * s), vec2(168 * s + 120 * s * brk, by + 12 * s), rgbm.from0255(225, 6, 0, 255))
  end)
  if not ok then ac.debug('ETV Speed', err) end
end

return M
