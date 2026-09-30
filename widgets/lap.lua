-- ========================================
-- ENDURO TV // widgets/lap.lua
-- Timing screen solida: CUR/LAST/BEST + delta
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

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
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 300 * s, 158 * s
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

    -- delta bar solida
    local dy = y0 + 76 * s
    ui.drawRectFilled(vec2(8 * s, dy), vec2(W - 8 * s, dy + 12 * s), rgbm.from0255(40, 40, 52, 255))
    ui.drawRectFilled(vec2(W / 2 - 1, dy - 2 * s), vec2(W / 2 + 1, dy + 14 * s), rgbm.from0255(130, 130, 150, 255))
    if last and last > 0 and best and best > 0 then
      local d = (last - best) / 1000
      local norm = draw.clamp(d / 2, -1, 1)
      local cx = W / 2
      local ex = cx + (W / 2 - 10 * s) * norm
      local col = norm <= 0.05 and rgbm.from0255(0, 200, 80, 255) or rgbm.from0255(225, 6, 0, 255)
      if norm < 0 then ui.drawRectFilled(vec2(ex, dy), vec2(cx, dy + 12 * s), col)
      else ui.drawRectFilled(vec2(cx, dy), vec2(ex, dy + 12 * s), col) end
      draw.textF(draw.FONT_SEMI, W - 90 * s, dy - 4 * s, draw.fmtGap(last - best), 11 * s, col, ui.Alignment.End, 82 * s, 20 * s)
    end
  end)
  if not ok then ac.debug('ETV Lap', err) end
end

return M
