-- RACE TV v10 // Telemetria em glass com pop de marcha e shift flash.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local intro, pulse = 0, 0
local lastGear, popT = nil, 0
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  pulse = pulse + dt
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  local g = car and car.gear or nil
  if g ~= lastGear then lastGear, popT = g, 0.28 end
  popT = math.max(0, popT - dt)
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 lastGear, popT = nil, 0 end

local function gearStr(g)
  if g == 0 then return 'N' end
  if g == -1 then return 'R' end
  return tostring(g or '-')
end

function M.main()
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if not car then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 470, 80, 'TV Telemetry')
  local W, H = 470 * k, 80 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)

  local kmh = car.speedKmh or 0
  local mph = kmh * 0.621371
  local rpm = car.rpm or 0
  local lim = car.rpmLimiter or 0
  if type(lim) ~= 'number' or lim < 1000 then lim = 7500 end
  local frac = draw.clamp(rpm / lim, 0, 1)
  local gear = car.gear or 0
  local pos = tostring(car.racePosition or '-')
  local foc = sim.focusedCar or 0
  local col = draw.driverColor(foc)

  -- barra de RPM no topo
  ui.drawRectFilled(vec2(10 * k, 8 * k), vec2(W - 10 * k, 13 * k), rgbm(1, 1, 1, 0.10 * alpha), 2)
  if frac > 0.001 then
    local rpmCol = frac > 0.92 and draw.RED or draw.fade(col, 1)
    ui.drawRectFilled(vec2(10 * k, 8 * k), vec2(10 * k + (W - 20 * k) * frac, 13 * k),
      draw.fade(rpmCol, alpha), 2)
  end
  -- shift flash
  if frac > 0.97 then
    local bl = 0.35 + 0.35 * math.sin(pulse * 14)
    ui.drawRect(vec2(0.5, 0.5), vec2(W - 0.5, H - 0.5), rgbm(1, 0.15, 0.2, bl * alpha))
  end

  -- posição
  draw.pill(10 * k, 20 * k, 44 * k, 30 * k, draw.fade(col, alpha))
  local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
  draw.textF(draw.FONT_NUM, 10 * k, 20 * k, pos, 20 * k,
    draw.fade(lum > 0.65 and draw.PHIL_BG or draw.WHITE, alpha), ui.Alignment.Center, 44 * k, 30 * k)

  -- marcha gigante com pop
  local pop = 1 + 0.28 * (popT / 0.28)
  local gs = 52 * k * pop
  draw.textF(draw.FONT_NUM, 58 * k, 14 * k, gearStr(gear), gs, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Center, 84 * k, 58 * k)
  -- filete divisor
  ui.drawRectFilled(vec2(150 * k, 20 * k), vec2(152 * k, H - 22 * k), rgbm(1, 1, 1, 0.12 * alpha))
  draw.textF(draw.FONT_TXT, 58 * k, H - 13 * k, 'GEAR', 8.5 * k, draw.fade(draw.PHIL_GRAY, alpha),
    ui.Alignment.Center, 84 * k, 11 * k)

  -- velocidade
  local spd = cfg.mph and mph or kmh
  draw.textF(draw.FONT_NUM, 158 * k, 16 * k, string.format('%.0f', spd), 40 * k,
    draw.fade(draw.WHITE, alpha), ui.Alignment.Start, 150 * k, 44 * k)
  draw.textF(draw.FONT_TXT, 160 * k, 56 * k, (cfg.mph and 'MPH' or 'KM/H') .. '  ·  ' .. string.format('%.0f', rpm) .. ' RPM',
    10 * k, draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Start, 200 * k, 16 * k)

  -- marchas 1..8 compactas
  local gx = 316 * k
  for g = 1, 8 do
    local gw, active = 16 * k, gear == g
    if active then
      draw.pill(gx, 22 * k, gw, 22 * k, draw.fade(draw.WHITE, alpha))
      draw.textF(draw.FONT_NUM, gx, 22 * k, tostring(g), 13 * k, draw.fade(draw.PHIL_BG, alpha),
        ui.Alignment.Center, gw, 22 * k)
    else
      draw.textF(draw.FONT_SEMI, gx, 22 * k, tostring(g), 12 * k,
        rgbm(0.55, 0.58, 0.66, alpha), ui.Alignment.Center, gw, 22 * k)
    end
    gx = gx + gw + 1 * k
  end

  -- mini barras thr/brk na base
  local thr = draw.clamp(car.gas or 0, 0, 1)
  local brk = draw.clamp(car.brake or 0, 0, 1)
  draw.textF(draw.FONT_TXT, 316 * k, H - 18 * k, 'T', 9 * k, draw.fade(draw.PHIL_GRAY, alpha),
    ui.Alignment.Center, 14 * k, 12 * k)
  ui.drawRectFilled(vec2(332 * k, H - 15 * k), vec2(392 * k, H - 8 * k), rgbm(1, 1, 1, 0.10 * alpha), 2)
  ui.drawRectFilled(vec2(332 * k, H - 15 * k), vec2(332 * k + 60 * k * thr, H - 8 * k),
    rgbm(0.15, 0.95, 0.45, alpha), 2)
  draw.textF(draw.FONT_TXT, 396 * k, H - 18 * k, 'B', 9 * k, draw.fade(draw.PHIL_GRAY, alpha),
    ui.Alignment.Center, 14 * k, 12 * k)
  ui.drawRectFilled(vec2(412 * k, H - 15 * k), vec2(W - 10 * k, H - 8 * k), rgbm(1, 1, 1, 0.10 * alpha), 2)
  ui.drawRectFilled(vec2(412 * k, H - 15 * k), vec2(412 * k + (W - 10 * k - 412 * k) * brk, H - 8 * k),
    rgbm(1, 0.22, 0.28, alpha), 2)
  ui.popClipRect()
end
return M
