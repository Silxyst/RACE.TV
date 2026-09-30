-- ========================================
-- RACE TV v3 // widgets/speed.lua
-- Replica PHIL telemetry topo: [NUM] GEAR 1-6 | SPEED | RPM bars
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
function M.init() end
function M.update(dt) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local k = draw.fit(cfg.scale, 470, 64)
    local W, H = 470 * k, 64 * k

    local sim = ac.getSim()
    local foc = (sim and sim.focusedCar) or 0
    local car = ac.getCar(foc)
    if not car then return end

    ui.drawRectFilled(vec2(0, 0), vec2(W, H), rgbm.from0255(5, 5, 10, 255))

    local kmh = car.speedKmh or 0
    local mph = kmh * 0.621371
    local rpm = car.rpm or 0
    local lim = car.rpmLimiter or 0
    if type(lim) ~= 'number' or lim < 1000 then lim = 7500 end
    local frac = draw.clamp(rpm / lim, 0, 1)
    local gear = car.gear or 0
    local pos = tostring(car.racePosition or '-')
    local col = draw.driverColor(foc)

    -- RPM barra vermelha topo
    ui.drawRectFilled(vec2(0, 0), vec2(W, 5 * k), rgbm.from0255(40, 40, 55, 255))
    ui.drawRectFilled(vec2(0, 0), vec2(W * frac, 5 * k), rgbm.from0255(225, 6, 0, 255))

    -- NUM pos (amarelo/vermelho estilo PHIL)
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    local numCol = lum > 0.65 and col or draw.PHIL_YEL
    if foc == 0 then numCol = draw.PHIL_YEL end
    draw.textF(draw.FONT_NUM, 6 * k, 6 * k, pos, 34 * k, numCol, ui.Alignment.Center, 52 * k, 40 * k)

    -- GEARS 1..6 centro
    draw.textF(draw.FONT_TXT, 62 * k, 8 * k, 'GEAR', 9 * k, draw.PHIL_GRAY, ui.Alignment.Start, 40 * k, 12 * k)
    local gx = 62 * k
    for g = 1, 6 do
      local gw = 26 * k
      local active = (gear == g)
      if active then
        ui.drawRectFilled(vec2(gx, 22 * k), vec2(gx + gw, 46 * k), draw.WHITE)
        draw.textF(draw.FONT_NUM, gx, 22 * k, tostring(g), 20 * k, draw.PHIL_BG, ui.Alignment.Center, gw, 24 * k)
      else
        draw.textF(draw.FONT_SEMI, gx, 22 * k, tostring(g), 17 * k, rgbm.from0255(130, 135, 155, 255), ui.Alignment.Center, gw, 24 * k)
      end
      gx = gx + gw + 2 * k
    end
    if gear == 0 then
      draw.textF(draw.FONT_NUM, gx + 4 * k, 22 * k, 'N', 20 * k, draw.PHIL_YEL, ui.Alignment.Start, 30 * k, 24 * k)
    elseif gear == -1 then
      draw.textF(draw.FONT_NUM, gx + 4 * k, 22 * k, 'R', 20 * k, draw.PHIL_YEL, ui.Alignment.Start, 30 * k, 24 * k)
    end

    -- SPEED direita
    local spd = cfg.mph and mph or kmh
    draw.textF(draw.FONT_NUM, W - 170 * k, 8 * k, string.format('%.0f', spd), 32 * k, draw.WHITE, ui.Alignment.End, 110 * k, 34 * k)
    draw.textF(draw.FONT_TXT, W - 170 * k, 40 * k, cfg.mph and 'MPH' or 'KM/H', 9 * k, draw.PHIL_GRAY, ui.Alignment.End, 110 * k, 12 * k)
    draw.textF(draw.FONT_TXT, W - 58 * k, 8 * k, string.format('%.0f RPM', rpm), 10 * k, draw.WHITE, ui.Alignment.Start, 52 * k, 14 * k)
    draw.textF(draw.FONT_TXT, W - 58 * k, 22 * k, string.format('%.0f MPH', mph), 9 * k, draw.PHIL_GRAY, ui.Alignment.Start, 52 * k, 12 * k)

    -- barra verde base (thr) estilo PHIL
    local thr = 0
    if foc == 0 then thr = draw.clamp(car.gas or 0, 0, 1) end
    ui.drawRectFilled(vec2(60 * k, H - 8 * k), vec2(W - 6 * k, H - 4 * k), rgbm.from0255(30, 30, 45, 255))
    ui.drawRectFilled(vec2(60 * k, H - 8 * k), vec2(60 * k + (W - 66 * k) * (foc == 0 and thr or frac), H - 4 * k), rgbm.from0255(57, 255, 20, 255))

    draw.textF(draw.FONT_TXT, W - 58 * k, H - 20 * k, 'TELEMETRY', 9 * k, draw.WHITE, ui.Alignment.Start, 52 * k, 12 * k)
    ui.drawRect(vec2(0.5, 0.5), vec2(W - 0.5, H - 0.5), rgbm.from0255(70, 70, 95, 255), 1)
  end)
  if not ok then ac.debug('PHIL Tele', err) end
end

return M
