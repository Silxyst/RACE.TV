-- ========================================
-- RACE TV v5 // widgets/tower.lua
-- PHIL TV + FSH/ACTV: fit na janela, scroll de páginas, setas ▲▼,
-- roxo overall-best, progresso de sessão, clip de nomes.
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
local prevPos = {}
local arrowT = {}
local arrowDir = {}
local dtCur = 0.016

function M.init() end
function M.update(dt)
  dt = dt or 0.016
  dtCur = dt
  pulse = pulse + dt
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() rowY = {} prevPos = {} arrowT = {} arrowDir = {} end

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
    -- BASE de referência; k encaixa na janela real (fix escala)
    local BASE_W = 290
    local logoH_u, clockH_u, footH_u, rowH_u = 52, 26, 22, 27
    local maxRowsCfg = cfg.towerRows or 8

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
    if #list == 0 then return end

    -- quantas linhas cabem na janela?
    local ws = ui.windowSize()
    local winW, winH = ws.x, ws.y
    local rowsFit = math.max(4, math.floor((winH - logoH_u - clockH_u - footH_u) / rowH_u))
    local rows = math.max(4, math.min(maxRowsCfg, #list, rowsFit))
    local Hunit = logoH_u + clockH_u + rows * rowH_u + footH_u
    local k = draw.fit(cfg.scale, BASE_W, Hunit)
    local W = BASE_W * k
    local logoH, clockH, footH, rowH = logoH_u * k, clockH_u * k, footH_u * k, rowH_u * k
    local H = Hunit * k

    -- setas de troca de posição (Turismos: 5s)
    for _, e in ipairs(list) do
      local pp = prevPos[e.idx]
      if pp ~= nil and pp ~= e.pos then
        arrowT[e.idx] = 5.0
        arrowDir[e.idx] = e.pos < pp -- número menor = ganhou posição
      end
      prevPos[e.idx] = e.pos
      if arrowT[e.idx] then arrowT[e.idx] = math.max(0, arrowT[e.idx] - dtCur) end
    end

    -- scroll de páginas (WEC/NLS): líderes sempre + página rotativa
    local pages, page = 1, 0
    local view = list
    if #list > rows then
      local rest = {}
      for i = 2, #list do rest[#rest + 1] = list[i] end
      local perPage = rows - 1
      pages = math.max(1, math.ceil(#rest / perPage))
      page = math.floor(Time / 8) % pages
      view = { list[1] }
      for i = 1, perPage do
        local e = rest[page * perPage + i]
        if e then view[#view + 1] = e end
      end
    end
    local n = #view

    local quali = draw.isQualiLike(sim)
    local isCaution = sim.raceFlagType == ac.FlagType.Caution

    -- overall best (roxo ACTV/WEC)
    local sessBest = nil
    for _, e in ipairs(list) do
      local b = e.car.bestLapTimeMs or 0
      if b and b > 0 and (not sessBest or b < sessBest) then sessBest = b end
    end

    -- ===== HEADER =====
    ui.drawRectFilled(vec2(0, 0), vec2(W, logoH), draw.PHIL_BG)
    draw.textF(draw.FONT_HEAD, 0, 2 * k, cfg.series or 'RACE TV', 30 * k, draw.WHITE, ui.Alignment.Center, W, 48 * k)

    local clockTxt = draw.sessionClock(sim)
    local sess = ac.getSession(sim.currentSessionIndex or 0)
    local lapTotal = (sess and sess.laps) or 0
    if not quali and lapTotal and lapTotal > 0 then
      clockTxt = tostring(list[1].car.lapCount or 0) .. '/' .. tostring(lapTotal)
    end
    if isCaution then
      local blink = math.floor(pulse * 1.5) % 2 == 0
      ui.drawRectFilled(vec2(0, logoH), vec2(W, logoH + clockH), blink and draw.YELLOW or draw.PHIL_BLUE)
      local tc = blink and rgbm.from0255(15, 5, 50, 255) or draw.WHITE
      draw.textF(draw.FONT_HEAD, 0, logoH, blink and 'YELLOW FLAG' or clockTxt, 15 * k, tc, ui.Alignment.Center, W, clockH)
    else
      ui.drawRectFilled(vec2(0, logoH), vec2(W, logoH + clockH), draw.PHIL_BLUE)
      draw.textF(draw.FONT_HEAD, 0, logoH, clockTxt, 15 * k, draw.WHITE, ui.Alignment.Center, W, clockH)
    end
    -- progresso de sessão (WEC DrawSessionProgress): voltas ou tempo
    do
      local frac = 0
      if not quali and lapTotal and lapTotal > 0 then
        frac = draw.clamp((list[1].car.lapCount or 0) / lapTotal, 0, 1)
      elseif sim.sessionTimeLeft and sim.sessionTimeLeft > 0 and sim.currentSessionTime then
        local tot = sim.sessionTimeLeft + sim.currentSessionTime * 1000
        if tot > 0 then frac = draw.clamp(1 - sim.sessionTimeLeft / tot, 0, 1) end
      end
      ui.drawRectFilled(vec2(0, logoH + clockH - 3 * k), vec2(W * frac, logoH + clockH), rgbm(1, 1, 1, 0.55))
    end

    -- ===== LINHAS =====
    local leaderEntry = list[1]
    local prevEntry = nil
    ui.pushClipRect(vec2(0, logoH + clockH), vec2(W, logoH + clockH + n * rowH))
    for r = 1, n do
      local e = view[r]
      local car = e.car
      local targetY = logoH + clockH + (r - 1) * rowH
      local ry = rowY[e.idx]
      if ry == nil then ry = targetY end
      ry = anim.damp(ry, targetY, 9, dtCur)
      rowY[e.idx] = ry
      local isFoc = (e.idx == focused)
      local isP1 = (e.pos == 1)
      local white = isP1 or isFoc

      if white then
        ui.drawRectFilled(vec2(0, ry), vec2(W, ry + rowH), draw.WHITE)
      else
        ui.drawRectFilled(vec2(0, ry), vec2(W, ry + rowH), (r % 2 == 0) and draw.PHIL_ROW2 or draw.PHIL_ROW)
      end
      local ink = white and draw.PHIL_BG or draw.WHITE
      local sub = white and rgbm.from0255(40, 40, 60, 255) or draw.PHIL_GRAY

      -- POS + seta ▲▼ (Turismos)
      draw.textF(draw.FONT_NUM, 6 * k, ry, tostring(e.pos), 15 * k, ink, ui.Alignment.Center, 22 * k, rowH)
      local at = arrowT[e.idx] or 0
      if at > 0 then
        local up = arrowDir[e.idx]
        local a = math.min(1, at / 0.4)
        local acol = up and rgbm.from0255(0, 220, 90, a) or rgbm.from0255(255, 60, 70, a)
        draw.textF(draw.FONT_HEAD, 26 * k, ry - 6 * k, up and '▲' or '▼', 9 * k, acol, ui.Alignment.Start, 12 * k, 12 * k)
      end

      -- quadrado marca
      local okC, cn = pcall(ac.getCarName, e.idx)
      local initial = '·'
      if okC and cn and #tostring(cn) > 0 then initial = tostring(cn):sub(1, 1):upper() end
      local boxC = white and draw.PHIL_BG or draw.driverColor(e.idx)
      ui.drawRectFilled(vec2(38 * k, ry + 5 * k), vec2(54 * k, ry + rowH - 5 * k), boxC)
      draw.textF(draw.FONT_HEAD, 38 * k, ry, initial, 11 * k, draw.WHITE, ui.Alignment.Center, 16 * k, rowH)

      -- NOME com clip (fix overlap)
      local gapX = W - 92 * k
      ui.pushClipRect(vec2(58 * k, ry), vec2(gapX, ry + rowH))
      local okN, nm = pcall(ac.getDriverName, e.idx)
      local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or '---'
      draw.textF(draw.FONT_BOLD, 58 * k, ry, dname, 13 * k, ink, ui.Alignment.Start, gapX - 58 * k + 30 * k, rowH)
      ui.popClipRect()

      -- direita
      local status = nil
      if car.isInPit then
        local spd = car.speedKmh or 0
        status = (spd and spd < 5) and 'OUT' or 'PIT'
      end
      if status then
        if status == 'PIT' then
          ui.drawRectFilled(vec2(W - 30 * k, ry + 5 * k), vec2(W - 6 * k, ry + rowH - 5 * k), draw.RED)
          draw.textF(draw.FONT_HEAD, W - 30 * k, ry, 'P', 12 * k, draw.WHITE, ui.Alignment.Center, 24 * k, rowH)
        else
          draw.textF(draw.FONT_SEMI, W - 66 * k, ry, 'OUT', 12 * k, sub, ui.Alignment.End, 60 * k, rowH)
        end
      elseif quali then
        local b = car.bestLapTimeMs or 0
        local bc = draw.sectorColor(b, sessBest, nil)
        if b <= 0 then bc = sub end
        draw.textF(draw.FONT_SEMI, W - 92 * k, ry, draw.fmtLap(b), 12 * k, bc, ui.Alignment.End, 86 * k, rowH)
      else
        local gapStr = 'LEADER'
        if e.pos > 1 then
          local ga = prevEntry and estimateGap(prevEntry, e, trackLen) or nil
          local gl = estimateGap(leaderEntry, e, trackLen)
          if ga and ga <= 90 then gapStr = draw.fmtSec(ga)
          elseif gl and gl <= 90 then gapStr = draw.fmtSec(gl)
          else gapStr = '+1 LAP' end
        end
        draw.textF(draw.FONT_SEMI, W - 92 * k, ry, gapStr, 12 * k, sub, ui.Alignment.End, 86 * k, rowH)
      end
      prevEntry = e
    end
    ui.popClipRect()

    -- ===== FOOTER =====
    local fy = logoH + clockH + n * rowH
    ui.drawRectFilled(vec2(0, fy), vec2(W, fy + footH), draw.PHIL_BLUE)
    local ftxt = quali and ('BEST ' .. draw.fmtLap(sessBest or 0)) or 'MELHOR VOLTA'
    if pages > 1 then ftxt = ftxt .. '  •  ' .. tostring(page + 1) .. '/' .. tostring(pages) end
    draw.textF(draw.FONT_TXT, 0, fy, ftxt, 10.5 * k, draw.WHITE, ui.Alignment.Center, W, footH)

    ui.drawRect(vec2(0.5, 0.5), vec2(W - 0.5, H - 0.5), rgbm.from0255(90, 200, 255, 200), 1.5)
  end)
  if not ok then ac.debug('PHIL Tower', err) end
end

return M
