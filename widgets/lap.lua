-- RACE TV v10 // Timing em glass com delta suavizado.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local intro = 0
local smoothLive, hasLive = 0, false
local lastFocus
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if sim and lastFocus ~= sim.focusedCar then hasLive = false lastFocus = sim.focusedCar end
  local live = car and car.performanceMeter
  if car and car.physicsAvailable and not car.isRemote and not car.isInPitlane
    and car.bestLapTimeMs > 0 and live and live == live and math.abs(live) < 60 then
    if not hasLive then smoothLive, hasLive = live, true end
    smoothLive = anim.damp(smoothLive, live, 10, dt)
  else
    hasLive = false
  end
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 smoothLive, hasLive = 0, false lastFocus = nil end

function M.main()
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if not car then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 300, 170, 'TV Timing')
  local W, H = 300 * k, 170 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  local cur = car.lapTimeMs or 0
  local last = car.previousLapTimeMs or 0
  local best = car.bestLapTimeMs or 0

  local sessBest = nil
  if sim then
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected ~= false then
        local b = c.bestLapTimeMs or 0
        if b and b > 0 and (not sessBest or b < sessBest) then sessBest = b end
      end
    end
  end
  local isOverall = best and best > 0 and sessBest and best <= sessBest + 1

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'TIMING', 12 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 120 * k, 18 * k)
  local okN, nm = pcall(ac.getDriverName, sim.focusedCar or 0)
  local who = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 16) or ''
  if who ~= '' then
    draw.textF(draw.FONT_TXT, W - 172 * k, 8 * k, who, 10 * k, draw.fade(draw.PHIL_GRAY, alpha),
      ui.Alignment.End, 160 * k, 18 * k)
  end

  local function row(label, val, size, color, yy)
    draw.textF(draw.FONT_TXT, 12 * k, yy, label, 10 * k, draw.fade(draw.GRAY, alpha),
      ui.Alignment.Start, 44 * k, 22 * k)
    draw.textF(draw.FONT_NUM, 60 * k, yy - 2 * k, val, size, draw.fade(color, alpha),
      ui.Alignment.Start, 232 * k, 26 * k)
  end
  row('CUR', draw.fmtLap(cur), 19 * k, draw.WHITE, 30 * k)
  row('LAST', draw.fmtLap(last), 15 * k, draw.GRAY, 54 * k)
  local bcol = isOverall and draw.PURPLE or draw.WHITE
  row('BEST', draw.fmtLap(best) .. (isOverall and '  ★' or ''), 15 * k, bcol, 78 * k)

  -- delta live suavizado + previsão
  local live = hasLive and smoothLive or nil
  local ly = 104 * k
  if live then
    local dcol = live <= 0 and draw.GREEN or draw.RED
    draw.textF(draw.FONT_TXT, 12 * k, ly, 'LIVE', 10 * k, draw.fade(draw.GRAY, alpha),
      ui.Alignment.Start, 44 * k, 20 * k)
    draw.textF(draw.FONT_NUM, 60 * k, ly - 2 * k, draw.fmtDeltaS(live), 18 * k,
      draw.fade(dcol, alpha), ui.Alignment.Start, 120 * k, 24 * k)
    if best and best > 0 then
      local pred = best + live * 1000
      local pcol = pred < best and draw.GREEN or draw.GRAY
      draw.textF(draw.FONT_SEMI, 186 * k, ly, 'PRED ' .. draw.fmtLap(pred), 10.5 * k,
        draw.fade(pcol, alpha), ui.Alignment.Start, 106 * k, 20 * k)
    end
  end

  -- barra móvel ±2s
  local dy, bh = 130 * k, 12 * k
  local bx, bw = 12 * k, W - 24 * k
  ui.drawRectFilled(vec2(bx, dy), vec2(bx + bw, dy + bh), rgbm(1, 1, 1, 0.10 * alpha), 3)
  local step = bw / 8
  local dd = bx + step
  while dd < bx + bw - 1 do
    ui.drawRectFilled(vec2(dd, dy + 2 * k), vec2(dd + 1, dy + bh - 2 * k), rgbm(1, 1, 1, 0.14 * alpha))
    dd = dd + step
  end
  local midX = bx + bw / 2
  ui.drawRectFilled(vec2(midX - 1, dy - 2 * k), vec2(midX + 1, dy + bh + 2 * k),
    rgbm(0.85, 0.86, 0.9, alpha))
  if live then
    local frac = draw.clamp(-live / 2, -1, 1)
    local ex = midX + frac * (bw / 2)
    local bcol = live <= 0 and draw.GREEN or draw.RED
    if frac < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(midX, dy + bh), draw.fade(bcol, alpha), 2)
    else ui.drawRectFilled(vec2(midX, dy), vec2(ex, dy + bh), draw.fade(bcol, alpha), 2) end
    draw.textF(draw.FONT_SEMI, W - 92 * k, dy - 3 * k, draw.fmtDeltaS(live), 10.5 * k,
      draw.fade(bcol, alpha), ui.Alignment.End, 84 * k, 18 * k)
  elseif last and last > 0 and best and best > 0 then
    local d = (last - best) / 1000
    local norm = draw.clamp(d / 2, -1, 1)
    local ex = midX + norm * (bw / 2)
    local col = norm <= 0.05 and draw.GREEN or draw.RED
    if norm < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(midX, dy + bh), draw.fade(col, alpha), 2)
    else ui.drawRectFilled(vec2(midX, dy), vec2(ex, dy + bh), draw.fade(col, alpha), 2) end
    draw.textF(draw.FONT_SEMI, W - 92 * k, dy - 3 * k, draw.fmtGap(last - best), 10.5 * k,
      draw.fade(col, alpha), ui.Alignment.End, 84 * k, 18 * k)
  end
  -- setores mini (S1 S2 S3 do best)
  local spl = car.bestLapSplits
  if spl then
    local sx = 12 * k
    for sIdx = 1, 3 do
      local t = spl[sIdx - 1]
      local dotC = t and t > 0 and draw.GREEN or draw.fade(draw.PHIL_GRAY, 0.4)
      ui.drawCircleFilled(vec2(sx + 4 * k, 152 * k), 3 * k, draw.fade(dotC, alpha), 8)
      draw.textF(draw.FONT_TXT, sx + 10 * k, 144 * k, 'S' .. sIdx .. ' ' .. (t and t > 0 and draw.fmtLap(t) or '--'), 9.5 * k,
        draw.fade(draw.GRAY, alpha), ui.Alignment.Start, 82 * k, 16 * k)
      sx = sx + 94 * k
    end
  end
  ui.popClipRect()
end
return M
