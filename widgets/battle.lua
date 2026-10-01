-- RACE TV v10 // Battle cards em glass com setores ao vivo.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim, data = require('core.anim'), require('core.data')
local sectors = require('core.sectors')
local control = require('core.control')

local pulse = 0
local pairKey = nil
local pairAnim = 1
local intro = 0
local selected, hold = nil, 0
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  pulse = pulse + dt
  intro = math.min(1, intro + dt * 2.6)
  if pairAnim < 1 then pairAnim = math.min(1, pairAnim + dt * 3.5) end
  hold = hold + dt
  local sim = ac.getSim()
  local focus = sim and (data.byIndex[sim.focusedCar] or data.list[1])
  if focus then
    local cfg = config.get()
    local manual = control.pair()
    local pair = manual or (cfg.autoBattle and data.battle() or nil)
    local desired = pair or { focus, data.list[focus.rank - 1] or data.list[focus.rank + 1] }
    local key = desired[1].idx .. ':' .. (desired[2] and desired[2].idx or -1)
    if not selected or not data.byIndex[selected[1]] or (selected[2] and not data.byIndex[selected[2]])
      or (key ~= pairKey and (manual or hold >= 4 or not cfg.autoBattle)) then
      selected = { desired[1].idx, desired[2] and desired[2].idx }
      if pairKey then pairAnim = 0 end
      pairKey, hold = key, 0
    end
  else selected = nil end
  control.trackPair(dt, selected and data.byIndex[selected[1]], selected and data.byIndex[selected[2]])
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() pairKey = nil pairAnim = 1 intro = 0 selected = nil hold = 0 end

local function fmtCurrent(ms)
  if not ms or ms <= 0 then return '--:--.-' end
  local m = math.floor(ms / 60000)
  local s = (ms - m * 60000) / 1000
  return string.format('%d:%04.1f', m, s)
end

local function drawCardK(x, y, entry, gapO, k, cw, ch, alpha)
  local car = entry.car
  local okN, nm = pcall(ac.getDriverName, entry.idx)
  local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or '---'
  local col = draw.driverColor(entry.idx)
  local topH = 26 * k
  local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
  local ink = lum > 0.65 and draw.PHIL_BG or draw.WHITE
  -- faixa do piloto
  ui.drawRectFilled(vec2(x, y), vec2(x + cw, y + topH), draw.fade(col, alpha), 6)
  local dark = draw.darken(col, 0.6)
  ui.drawRectFilled(vec2(x + cw / 2, y), vec2(x + cw, y + topH), draw.fade(dark, alpha), 6)
  -- corpo
  ui.drawRectFilled(vec2(x, y + topH - 4 * k), vec2(x + cw, y + ch), draw.surface(0.92 * alpha), 6)
  ui.drawRect(vec2(x + 0.5, y + topH - 4 * k + 0.5), vec2(x + cw - 0.5, y + ch - 0.5), rgbm(1, 1, 1, 0.09 * alpha))
  draw.textF(draw.FONT_HEAD, x + 8 * k, y + 1 * k, dname, 14 * k, draw.fade(ink, alpha),
    ui.Alignment.Center, cw - 16 * k, topH - 4 * k)
  local pos = tostring(entry.pos or '-')
  draw.pill(x + 8 * k, y + topH + 6 * k, 38 * k, 30 * k, draw.fade(col, alpha))
  draw.textF(draw.FONT_NUM, x + 8 * k, y + topH + 6 * k, pos, 20 * k, draw.fade(ink, alpha),
    ui.Alignment.Center, 38 * k, 30 * k)
  local cur = fmtCurrent(car.lapTimeMs or 0)
  local best = draw.fmtLap(car.bestLapTimeMs or 0)
  local big = cur
  local isGap = gapO and gapO > 0.05 and gapO < 90
  if isGap then big = '+' .. string.format('%.3f', gapO) end
  draw.textF(draw.FONT_NUM, x + 52 * k, y + topH + 4 * k, big, 27 * k,
    draw.fade(isGap and draw.PHIL_YEL or draw.WHITE, alpha), ui.Alignment.Start, cw - 190 * k, 40 * k)
  draw.textF(draw.FONT_SEMI, x + cw - 122 * k, y + topH + 8 * k, best, 12 * k,
    draw.fade(draw.GRAY, alpha), ui.Alignment.End, 114 * k, 18 * k)
  draw.textF(draw.FONT_TXT, x + cw - 122 * k, y + topH + 26 * k, 'MELHOR VLT', 8 * k,
    draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.End, 114 * k, 14 * k)
  -- setores live
  local spl = car.currentSplits or car.bestLapSplits
  local pb = car.bestLapSplits
  local curSec = car.currentSector or -1
  local sy = y + ch - 20 * k
  local segW = (cw - 16 * k) / 3
  for kk = 1, 3 do
    local sx = x + 8 * k + (kk - 1) * segW
    local t = spl and spl[kk - 1] or nil
    local done = curSec >= 0 and (kk - 1) < curSec and t and t > 0
    local isCur = curSec == (kk - 1)
    local scol = draw.sectorColor(t, sectors.best(kk), pb and pb[kk - 1] or nil)
    if not done then scol = isCur and draw.WHITE or draw.PHIL_GRAY end
    local pillBg = (isCur or done) and draw.fade(scol, alpha) or rgbm(0.24, 0.24, 0.31, 0.35 * alpha)
    draw.pill(sx, sy, segW - 6 * k, 14 * k, pillBg)
    draw.textF(draw.FONT_TXT, sx, sy, 'S' .. kk, 9 * k,
      draw.fade((isCur or done) and draw.PHIL_BG or draw.PHIL_GRAY, alpha),
      ui.Alignment.Center, segW - 6 * k, 14 * k)
  end
end

function M.main()
  if not selected then return end
  local cfg = config.get()
  local foc2, rival = data.byIndex[selected[1]], data.byIndex[selected[2]]
  if not foc2 then return end
  local paired = rival ~= nil and rival.idx ~= foc2.idx
  local k = draw.fit(cfg.scale, paired and 632 or 312, 112, 'TV Battle')
  local cw, ch = 312 * k, 112 * k
  local gap = 8 * k
  local slideX = (1 - anim.ease_out_quart(math.min(1, pairAnim))) * -30 * k
  local introP = anim.ease_out_quart(intro)
  local alpha = introP
  local gapFoc = paired and data.gap(rival, foc2) or nil
  local gapRiv = paired and data.gap(foc2, rival) or nil
  local drawW = 632 * k
  ui.pushClipRect(vec2(0, 0), vec2(drawW, 166 * k), true)
  drawCardK(slideX, 0, foc2, gapFoc, k, cw, ch, alpha)
  if paired then
    drawCardK(slideX + cw + gap, 0, rival, gapRiv, k, cw, ch, alpha)
  end
  ui.drawRectFilled(vec2(0, 116*k), vec2(drawW, 166*k), draw.surface(0.92 * alpha), 6)
  local function stats(entry, x)
    local nativeText = require('core.native').text(entry.idx)
    local laps = control.laps(entry.idx)
    local last = laps[#laps] or entry.car.previousLapTimeMs
    local average = control.average(entry.idx)
    local text = 'ULT ' .. draw.fmtLap(last) .. '  ·  MÉDIA ' .. draw.fmtLap(average) .. (nativeText and ('  ·  ' .. nativeText) or '')
    local code = require('core.classes').short(entry.idx)
    if code ~= '' then text = text .. '  ·  ' .. code end
    if config.get().showTyre then
      local letter = require('core.tyres').get(entry.idx)
      text = text .. '  ·  ' .. letter
    end
    draw.textF(draw.FONT_TXT, x+8*k, 119*k, text, 10*k, draw.fade(draw.GRAY, alpha), ui.Alignment.Start, cw-16*k, 20*k)
  end
  stats(foc2, 0)
  if paired then stats(rival, cw+gap) end
  local trend = control.trend()
  local caption = control.pair() and 'COMPARAÇÃO MANUAL' or 'BATALHA'
  if trend then
    caption = caption .. (math.abs(trend) < 0.02 and '  ·  INTERVALO ESTÁVEL'
      or string.format('  ·  %s %.2fs', trend > 0 and 'APROXIMANDO' or 'AFASTANDO', math.abs(trend)))
  end
  draw.textF(draw.FONT_SEMI, 8*k, 141*k, caption, 10*k, draw.fade(cfg.brand1, alpha), ui.Alignment.Center, drawW-16*k, 20*k)
  ui.popClipRect()
end
return M
