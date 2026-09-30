-- ========================================
-- ENDURO TV // widgets/lap.lua
-- Timing screen solida: CUR/LAST/BEST + delta
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')
local cams = require('core.cams')
local winfit = require('core.winfit')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm

local isVisible = false
function M.init() end
function M.update(dt) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

function M.main()
  if not isVisible then return end
  if not cams.gate('TV Timing') then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = draw.fit(cfg.scale, 300, 150)
    local W, H = 300 * s, 150 * s
    local headH = 24 * s

    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)
    draw.textF(draw.FONT_HEAD, 8 * s, 0, 'TIMING', 13 * s, draw.WHITE, ui.Alignment.Start, W - 16 * s, headH)
    ui.drawRectFilled(vec2(0, headH), vec2(W, H), draw.DARK)

    local sim = ac.getSim()
    local foc = (sim and sim.focusedCar) or 0
    local car = ac.getCar(foc)
    if not car then return end

    local cur = car.lapTimeMs or 0
    local last = car.previousLapTimeMs or car.lastLapTimeMs or 0
    local best = car.bestLapTimeMs or 0
    if (not best or best <= 0) and last and last > 0 then best = last end

    -- overall best da sessao (roxo TV)
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

    local y0 = headH + 8 * s
    draw.textF(draw.FONT_TXT, 8 * s, y0, 'CUR', 11 * s, draw.GRAY, ui.Alignment.Start, 44 * s, 18 * s)
    draw.textF(draw.FONT_NUM, 56 * s, y0 - 4 * s, draw.fmtLap(cur), 20 * s, draw.WHITE, ui.Alignment.Start, 236 * s, 26 * s)
    draw.textF(draw.FONT_TXT, 8 * s, y0 + 26 * s, 'LAST', 11 * s, draw.GRAY, ui.Alignment.Start, 44 * s, 18 * s)
    draw.textF(draw.FONT_SEMI, 56 * s, y0 + 26 * s, draw.fmtLap(last), 16 * s, draw.GRAY, ui.Alignment.Start, 236 * s, 22 * s)
    draw.textF(draw.FONT_TXT, 8 * s, y0 + 50 * s, 'BEST', 11 * s, draw.GRAY, ui.Alignment.Start, 44 * s, 18 * s)
    local bcol = isOverall and rgbm.from0255(190, 90, 255, 255) or draw.WHITE
    draw.textF(draw.FONT_SEMI, 56 * s, y0 + 50 * s, draw.fmtLap(best) .. (isOverall and '  ★' or ''), 16 * s, bcol, ui.Alignment.Start, 236 * s, 22 * s)

    -- DELTA LIVE LapAlly (performanceMeter nativo) + PREDICTED
    local live = car.performanceMeter -- segundos, negativo = mais rápido
    local ly = y0 + 74 * s
    if live and math.abs(live) < 60 then
      local dcol = live <= 0 and rgbm.from0255(0, 210, 90, 255) or rgbm.from0255(225, 6, 0, 255)
      draw.textF(draw.FONT_TXT, 8 * s, ly, 'LIVE', 11 * s, draw.GRAY, ui.Alignment.Start, 44 * s, 20 * s)
      draw.textF(draw.FONT_NUM, 56 * s, ly - 2 * s, draw.fmtDeltaS(live), 19 * s, dcol, ui.Alignment.Start, 120 * s, 24 * s)
      if best and best > 0 then
        local pred = best + live * 1000
        local pcol = pred < best and rgbm.from0255(0, 210, 90, 255) or draw.GRAY
        draw.textF(draw.FONT_SEMI, 180 * s, ly, 'PRED ' .. draw.fmtLap(pred), 11 * s, pcol, ui.Alignment.Start, 112 * s, 20 * s)
      end
    end

    -- barra LIVE móvel ±2s (LapAlly deltabar)
    local dy = y0 + 96 * s
    local bx, bw, bh = 8 * s, W - 16 * s, 12 * s
    ui.drawRectFilled(vec2(bx, dy), vec2(bx + bw, dy + bh), rgbm.from0255(40, 40, 52, 255))
    -- dots de fundo
    do
      local step = bw / 8
      local dd = bx + step
      while dd < bx + bw - 1 do
        ui.drawRectFilled(vec2(dd, dy + 2 * s), vec2(dd + 1, dy + bh - 2 * s), rgbm(1, 1, 1, 0.12))
        dd = dd + step
      end
    end
    local midX = bx + bw / 2
    ui.drawRectFilled(vec2(midX - 1, dy - 2 * s), vec2(midX + 1, dy + bh + 2 * s), rgbm.from0255(200, 200, 215, 255))
    if live and math.abs(live) < 60 then
      local frac = draw.clamp(-live / 2, -1, 1)
      local ex = midX + frac * (bw / 2)
      local bcol = live <= 0 and rgbm.from0255(0, 210, 90, 255) or rgbm.from0255(225, 6, 0, 255)
      if frac < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(midX, dy + bh), bcol)
      else ui.drawRectFilled(vec2(midX, dy), vec2(ex, dy + bh), bcol) end
      draw.textF(draw.FONT_SEMI, W - 90 * s, dy - 4 * s, draw.fmtDeltaS(live), 11 * s, bcol, ui.Alignment.End, 82 * s, 20 * s)
    elseif last and last > 0 and best and best > 0 then
      local d = (last - best) / 1000
      local norm = draw.clamp(d / 2, -1, 1)
      local ex = midX + norm * (bw / 2)
      local col = norm <= 0.05 and rgbm.from0255(0, 200, 80, 255) or rgbm.from0255(225, 6, 0, 255)
      if norm < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(midX, dy + bh), col)
      else ui.drawRectFilled(vec2(midX, dy), vec2(ex, dy + bh), col) end
      draw.textF(draw.FONT_SEMI, W - 90 * s, dy - 4 * s, draw.fmtGap(last - best), 11 * s, col, ui.Alignment.End, 82 * s, 20 * s)
    end
    winfit.fit('TV Timing', W, H)
  end)
  if not ok then ac.debug('ETV Lap', err) end
end

return M
