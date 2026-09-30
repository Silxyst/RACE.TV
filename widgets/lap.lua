-- ========================================
-- VELOCITY SLASH // widgets/lap.lua
-- Current / Last / Best + delta bar (best vs last)
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm

local isVisible = false
local pulse = 0
function M.init() end
function M.update(dt) pulse = pulse + (dt or 0.016) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 370 * s, 190 * s
    draw.slashPanel(0, 0, W, H, cfg, { slash = 22 * s })
    draw.header(0, 0, W, cfg, 'LAP // DELTA', pulse * 4)

    local sim = ac.getSim()
    local focIdx = (sim and sim.focusedCar) or 0
    local car = ac.getCar(focIdx)
    if not car then return end

    local cur = car.lapTimeMs or 0
    local last = car.previousLapTimeMs or car.lastLapTimeMs or 0
    local best = car.bestLapTimeMs or 0
    -- fallback: se best 0, usa last
    if (not best or best <= 0) and last and last > 0 then best = last end

    local y0 = 54 * s
    local function lapRow(label, ms, col, row, big)
      local ly = y0 + row * 30 * s
      draw.text(14 * s, ly, label, 12 * s, draw.dim(1), ui.Alignment.Start, 70 * s, 22 * s)
      draw.text(80 * s, ly - (big and 4 * s or 0), draw.fmtLap(ms), (big and 22 or 17) * s, col, ui.Alignment.Start, 270 * s, 26 * s)
    end

    lapRow('CUR', cur, draw.white(1), 0, true)
    lapRow('LAST', last, draw.dim(1), 1, false)

    -- BEST com destaque accent + roxo se for overall best da sessao
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
    local bestCol = isOverall and rgbm(0.75, 0.4, 1, 1) or draw.accent(cfg, 1)
    lapRow(isOverall and 'BEST ★' or 'BEST', best, bestCol, 2, false)

    -- delta bar: last vs best (-2s..+2s)
    local dy = y0 + 3 * 30 * s + 6 * s
    draw.text(14 * s, dy, 'Δ BEST', 11 * s, draw.dim(1), ui.Alignment.Start, 60 * s, 16 * s)
    local bx, bw, bh = 74 * s, W - 88 * s, 10 * s
    ui.drawRectFilled(vec2(bx, dy + 3 * s), vec2(bx + bw, dy + 3 * s + bh), rgbm(1, 1, 1, 0.10), 3)
    -- centro
    ui.drawLine(vec2(bx + bw / 2, dy + 1 * s), vec2(bx + bw / 2, dy + 5 * s + bh), rgbm(1, 1, 1, 0.4), 1)
    if last and last > 0 and best and best > 0 then
      local d = (last - best) / 1000 -- seg, + = pior
      local norm = draw.clamp(d / 2, -1, 1) -- -1 bom, +1 ruim
      local cx = bx + bw / 2
      local ex = cx + (bw / 2) * norm
      local col = norm <= 0.05 and rgbm(0.2, 1, 0.45, 1) or rgbm(1, 0.3, 0.35, 1)
      if norm < 0 then
        ui.drawRectFilled(vec2(ex, dy + 3 * s), vec2(cx, dy + 3 * s + bh), col, 2)
      else
        ui.drawRectFilled(vec2(cx, dy + 3 * s), vec2(ex, dy + 3 * s + bh), col, 2)
      end
      draw.text(bx + bw + 6 * s, dy, draw.fmtGap(last - best), 11 * s, col, ui.Alignment.Start, 80 * s, 16 * s)
    end
  end)
  if not ok then ac.debug('VS Lap', err) end
end

return M
