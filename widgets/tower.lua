-- ========================================
-- RACE TV v3 // widgets/tower.lua
-- Replica PHIL TV: header preto + timer azul + linhas navy + P1/focus branco
-- Quali mostra BEST, corrida mostra GAP. PIT/OUT + borda cyan.
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')
local anim = require('core.anim')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm
local math = math

local isVisible = false
local pulse = 0
local rowY = {}

function M.init() end
function M.update(dt)
  pulse = pulse + (dt or 0.016)
  -- amortecimento das linhas é feito no main (precisa do dt global)
  M._dt = dt or 0.016
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() rowY = {} end

local function carProgress(car)
  local lap = car.lapCount or 0
  local sp = car.splinePosition or 0
  if type(lap) ~= 'number' then lap = 0 end
  if type(sp) ~= 'number' then sp = 0 end
  return lap + sp
end

local function estimateGap(leaderEntry, entry, trackLen)
  if not leaderEntry or not entry then return nil end
  if entry.idx == leaderEntry.idx then return 0 end
  local lp = carProgress(leaderEntry.car)
  local cp = carProgress(entry.car)
  local diff = lp - cp
  if diff < 0 then diff = 0 end
  if diff > 1.5 then return nil end
  local kmh = entry.car.speedKmh or 110
  if type(kmh) ~= 'number' or kmh < 50 then kmh = 110 end
  local ms = kmh / 3.6
  if ms < 1 then return nil end
  return diff * (trackLen or 4500) / ms
end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W = 290 * s
    local logoH, clockH, footH = 52 * s, 26 * s, 22 * s
    local rowH = 27 * s
    local maxRows = cfg.towerRows or 8
    local n = 0

    local sim = ac.getSim()
    if not sim then return end
    local list = {}
    local focused = sim.focusedCar or 0
    local trackLen = sim.trackLengthM or 4500
    for i = 0, (sim.carsCount or 1) - 1 do
      local car = ac.getCar(i)
      if car and car.isConnected ~= false then
        list[#list + 1] = { idx = i, car = car, pos = car.racePosition or 99 }
      end
    end
    table.sort(list, function(a, b) return a.pos < b.pos end)
    n = math.min(maxRows, #list)
    local H = logoH + clockH + n * rowH + footH

    local quali = draw.isQualiLike(sim)
    local isCaution = sim.raceFlagType == ac.FlagType.Caution

    -- ===== HEADER PHIL: bloco preto + SERIE gigante italic =====
    ui.drawRectFilled(vec2(0, 0), vec2(W, logoH), draw.PHIL_BG)
    draw.textF(draw.FONT_HEAD, 0, 2 * s, cfg.series or 'RACE TV', 30 * s, draw.WHITE, ui.Alignment.Center, W, 48 * s)

    -- ===== TIMER azul royal =====
    local clockTxt = draw.sessionClock(sim)
    -- volta atual / total na corrida
    local sess = ac.getSession(sim.currentSessionIndex or 0)
    if not quali and sess and sess.laps and sess.laps > 0 then
      local lead = list[1]
      local lap = lead and (lead.car.lapCount or 0) or 0
      clockTxt = tostring(lap) .. '/' .. tostring(sess.laps)
    end
    if isCaution then
      local blink = math.floor(pulse * 1.5) % 2 == 0
      ui.drawRectFilled(vec2(0, logoH), vec2(W, logoH + clockH), blink and draw.YELLOW or draw.PHIL_BLUE)
      local tc = blink and rgbm.from0255(15, 5, 50, 255) or draw.WHITE
      draw.textF(draw.FONT_HEAD, 0, logoH, blink and 'YELLOW FLAG' or clockTxt, 15 * s, tc, ui.Alignment.Center, W, clockH)
    else
      ui.drawRectFilled(vec2(0, logoH), vec2(W, logoH + clockH), draw.PHIL_BLUE)
      draw.textF(draw.FONT_HEAD, 0, logoH, clockTxt, 15 * s, draw.WHITE, ui.Alignment.Center, W, clockH)
    end

    -- ===== LINHAS =====
    local leaderEntry = list[1]
    local prevEntry = nil
    -- clip da área de linhas (linhas em voo não vazam)
    ui.pushClipRect(vec2(0, logoH + clockH), vec2(W, logoH + clockH + n * rowH))
    for r = 1, n do
      local e = list[r]
      local car = e.car
      local targetY = logoH + clockH + (r - 1) * rowH
      -- animação suave de troca de posição (estilo CMRT/F1)
      local ry = rowY[e.idx]
      if ry == nil then ry = targetY end
      ry = anim.damp(ry, targetY, 10, M._dt or 0.016)
      rowY[e.idx] = ry
      local isFoc = (e.idx == focused)
      local isP1 = (r == 1)
      local white = isP1 or isFoc

      if white then
        ui.drawRectFilled(vec2(0, ry), vec2(W, ry + rowH), draw.WHITE)
      else
        ui.drawRectFilled(vec2(0, ry), vec2(W, ry + rowH), (r % 2 == 0) and draw.PHIL_ROW2 or draw.PHIL_ROW)
      end
      local ink = white and draw.PHIL_BG or draw.WHITE
      local sub = white and rgbm.from0255(40, 40, 60, 255) or draw.PHIL_GRAY

      -- POS
      draw.textF(draw.FONT_NUM, 6 * s, ry, tostring(e.pos), 15 * s, ink, ui.Alignment.Center, 22 * s, rowH)

      -- quadrado marca (inicial da marca/carro, estilo logo box PHIL)
      local okC, cn = pcall(ac.getCarName, e.idx)
      local initial = '·'
      if okC and cn and #tostring(cn) > 0 then initial = tostring(cn):sub(1, 1):upper() end
      local boxC = white and draw.PHIL_BG or draw.driverColor(e.idx)
      ui.drawRectFilled(vec2(30 * s, ry + 5 * s), vec2(48 * s, ry + rowH - 5 * s), boxC)
      draw.textF(draw.FONT_HEAD, 30 * s, ry, initial, 12 * s, draw.WHITE, ui.Alignment.Center, 18 * s, rowH)

      -- NOME
      local okN, nm = pcall(ac.getDriverName, e.idx)
      local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 17) or '---'
      -- status PIT / OUT
      local status = nil
      if car.isInPit then
        local spd = car.speedKmh or 0
        status = (spd and spd < 5) and 'OUT' or 'PIT'
      end
      local nameW = status and 128 * s or 158 * s
      draw.textF(draw.FONT_BOLD, 52 * s, ry, dname, 13.5 * s, ink, ui.Alignment.Start, nameW, rowH)

      -- direita: quali = BEST | corrida = GAP (ou PIT/OUT box)
      if status then
        if status == 'PIT' then
          ui.drawRectFilled(vec2(W - 30 * s, ry + 5 * s), vec2(W - 6 * s, ry + rowH - 5 * s), draw.RED)
          draw.textF(draw.FONT_HEAD, W - 30 * s, ry, 'P', 12 * s, draw.WHITE, ui.Alignment.Center, 24 * s, rowH)
        else
          draw.textF(draw.FONT_SEMI, W - 66 * s, ry, 'OUT', 12 * s, sub, ui.Alignment.End, 60 * s, rowH)
        end
      elseif quali then
        local b = car.bestLapTimeMs or 0
        draw.textF(draw.FONT_SEMI, W - 96 * s, ry, draw.fmtLap(b), 12.5 * s, sub, ui.Alignment.End, 90 * s, rowH)
      else
        local gapStr = 'LEADER'
        if r > 1 then
          local ga = prevEntry and estimateGap(prevEntry, e, trackLen) or nil
          local gl = estimateGap(leaderEntry, e, trackLen)
          if ga and ga <= 90 then gapStr = draw.fmtSec(ga)
          elseif gl and gl <= 90 then gapStr = draw.fmtSec(gl)
          else gapStr = '+1 LAP' end
        end
        draw.textF(draw.FONT_SEMI, W - 96 * s, ry, gapStr, 12.5 * s, sub, ui.Alignment.End, 90 * s, rowH)
      end
      prevEntry = e
    end
    ui.popClipRect()

    -- ===== FOOTER azul: MELHOR VOLTA / serie =====
    local fy = logoH + clockH + n * rowH
    ui.drawRectFilled(vec2(0, fy), vec2(W, fy + footH), draw.PHIL_BLUE)
    local sessBest = nil
    for _, e in ipairs(list) do
      local b = e.car.bestLapTimeMs or 0
      if b and b > 0 and (not sessBest or b < sessBest) then sessBest = b end
    end
    local ftxt = quali and ('BEST ' .. draw.fmtLap(sessBest or 0)) or 'MELHOR VOLTA'
    draw.textF(draw.FONT_TXT, 0, fy, ftxt, 10.5 * s, draw.WHITE, ui.Alignment.Center, W, footH)

    -- borda fina cyan estilo PHIL
    ui.drawRect(vec2(0.5, 0.5), vec2(W - 0.5, H - 0.5), rgbm.from0255(90, 200, 255, 200), 1.5)
  end)
  if not ok then ac.debug('PHIL Tower', err) end
end

return M
