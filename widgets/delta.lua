-- RACE TV v12 // Delta dedicado: live gigante, previsão e barra ±2s.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local intro = 0
local smoothLive, hasLive, lastFocus = 0, false, nil
local W0, H0 = 460, 132
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if sim and lastFocus ~= sim.focusedCar then hasLive, lastFocus = false, sim.focusedCar end
  local live = car and car.performanceMeter
  if car and car.physicsAvailable and not car.isRemote and not car.isInPitlane
    and car.bestLapTimeMs and car.bestLapTimeMs > 0 and live and live == live and math.abs(live) < 60 then
    if not hasLive then smoothLive, hasLive = live, true end
    smoothLive = anim.damp(smoothLive, live, 10, dt)
  else
    hasLive = false
  end
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 smoothLive, hasLive, lastFocus = 0, false, nil end

function M.main()
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if not car then return end
  local cfg = config.get()
  local k = cfg.scale
  local W, H = W0 * k, H0 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  local live = hasLive and smoothLive or nil
  local best = car.bestLapTimeMs or 0
  local dcol = draw.GRAY
  local big = '---'
  if live then
    dcol = live <= 0 and draw.GREEN or draw.RED
    big = draw.fmtDeltaS(live)
  end

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, dcol == draw.GRAY and cfg.brand1 or dcol, alpha)
  local okN, nm = pcall(ac.getDriverName, sim.focusedCar or 0)
  local who = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or ''
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'DELTA', 13 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 120 * k, 20 * k)
  if who ~= '' then
    draw.textF(draw.FONT_TXT, W - 212 * k, 8 * k, who, 11 * k, draw.fade(draw.PHIL_GRAY, alpha),
      ui.Alignment.End, 200 * k, 20 * k)
  end
  if live then
    draw.textF(draw.FONT_TXT, 12 * k, 30 * k, 'LIVE', 11 * k, draw.fade(draw.GRAY, alpha),
      ui.Alignment.Start, 60 * k, 22 * k)
  else
    draw.textF(draw.FONT_TXT, 12 * k, 30 * k, 'SEM REFERÊNCIA', 11 * k, draw.fade(draw.GRAY, alpha),
      ui.Alignment.Start, 220 * k, 22 * k)
  end
  draw.textF(draw.FONT_NUM, 12 * k, 50 * k, big, 44 * k, draw.fade(live and dcol or draw.GRAY, alpha),
    ui.Alignment.Start, 260 * k, 52 * k)
  if live and best > 0 then
    local pred = best + live * 1000
    draw.textF(draw.FONT_SEMI, 280 * k, 52 * k, 'PREV ' .. draw.fmtLap(pred), 13 * k,
      draw.fade(pred < best and draw.GREEN or draw.GRAY, alpha), ui.Alignment.Start, 168 * k, 24 * k)
    draw.textF(draw.FONT_TXT, 280 * k, 78 * k, 'REF ' .. draw.fmtLap(best), 11 * k,
      draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Start, 168 * k, 20 * k)
  else
    draw.textF(draw.FONT_SEMI, 280 * k, 52 * k, 'REF ' .. draw.fmtLap(best), 13 * k,
      draw.fade(draw.GRAY, alpha), ui.Alignment.Start, 168 * k, 24 * k)
  end
  -- barra móvel ±2s
  local dy, bh = 106 * k, 12 * k
  local bx, bw = 12 * k, W - 24 * k
  ui.drawRectFilled(vec2(bx, dy), vec2(bx + bw, dy + bh), rgbm(1, 1, 1, 0.10 * alpha), 3)
  local midX = bx + bw / 2
  ui.drawRectFilled(vec2(midX - 1, dy - 2 * k), vec2(midX + 1, dy + bh + 2 * k),
    rgbm(0.85, 0.86, 0.9, alpha))
  if live then
    local frac = draw.clamp(-live / 2, -1, 1)
    local ex = midX + frac * (bw / 2)
    if frac < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(midX, dy + bh), draw.fade(dcol, alpha), 2)
    else ui.drawRectFilled(vec2(midX, dy), vec2(ex, dy + bh), draw.fade(dcol, alpha), 2) end
  end
  ui.popClipRect()
end
return M
