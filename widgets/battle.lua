-- ========================================
-- RACE TV v3 // widgets/battle.lua
-- Replica PHIL TV: 2 cards de batalha lado a lado
-- Card = faixa colorida + nome | navy + POS + volta atual + best + S1 S2 S3
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
local pulse = 0
function M.init() end
function M.update(dt) pulse = pulse + (dt or 0.016) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

local function carProgress(car)
  local lap = car.lapCount or 0
  local sp = car.splinePosition or 0
  if type(lap) ~= 'number' then lap = 0 end
  if type(sp) ~= 'number' then sp = 0 end
  return lap + sp
end

local function gapBetween(aEntry, bEntry, trackLen)
  if not aEntry or not bEntry then return nil end
  if aEntry.idx == bEntry.idx then return 0 end
  local d = carProgress(aEntry.car) - carProgress(bEntry.car)
  -- positivo = a na frente
  local ad = math.abs(d)
  if ad > 1.5 then return nil end
  if ad < 0.0001 then return 0 end
  local behind = d < 0 and aEntry or bEntry
  local kmh = behind.car.speedKmh or 110
  if type(kmh) ~= 'number' or kmh < 50 then kmh = 110 end
  return ad * (trackLen or 4500) / (kmh / 3.6)
end

local function fmtCurrent(ms)
  if not ms or ms <= 0 then return '--:--. -' end
  local m = math.floor(ms / 60000)
  local s = (ms - m * 60000) / 1000
  return string.format('%d:%04.1f', m, s)
end

local function activeSector(car)
  local sp = car.splinePosition or 0
  if sp < 0.33 then return 1 elseif sp < 0.66 then return 2 else return 3 end
end

local function drawCard(x, y, cw, ch, entry, gapVsOther, isLeft)
  local car = entry.car
  local okN, nm = pcall(ac.getDriverName, entry.idx)
  local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or '---'
  local col = draw.driverColor(entry.idx)
  local dark = draw.darken(col, 0.6)
  local topH = 26
  local s = 1 -- card interno sem escala extra (janela ja escala? usamos px direto *cfg fora)

  -- faixa colorida + nome
  ui.drawRectFilledMultiColor(vec2(x, y), vec2(x + cw, y + topH), col, dark, dark, col)
  -- texto escuro se cor clara
  local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
  local ink = lum > 0.65 and draw.PHIL_BG or draw.WHITE
  draw.textF(draw.FONT_HEAD, x, y, dname, 15, ink, ui.Alignment.Center, cw, topH)

  -- corpo navy
  ui.drawRectFilled(vec2(x, y + topH), vec2(x + cw, y + ch), draw.PHIL_BG)
  local pos = tostring(car.racePosition or '-')
  local cur = fmtCurrent(car.lapTimeMs or 0)
  local best = draw.fmtLap(car.bestLapTimeMs or 0)
  -- se tem gap e é o de trás, mostra gap grande; senão volta atual
  local big = cur
  if gapVsOther and gapVsOther > 0.05 and gapVsOther < 90 then
    -- este card está atrás? gap positivo = outro na frente
    big = '+' .. string.format('%.3f', gapVsOther)
  end

  draw.textF(draw.FONT_NUM, x + 8, y + topH + 4, pos, 26, draw.WHITE, ui.Alignment.Center, 40, 40)
  draw.textF(draw.FONT_TXT, x + 8, y + topH + 38, 'POSIÇÃO', 9, draw.PHIL_GRAY, ui.Alignment.Center, 40, 12)
  draw.textF(draw.FONT_NUM, x + 52, y + topH + 6, big, 30, (big:sub(1,1) == '+') and draw.PHIL_YEL or draw.WHITE, ui.Alignment.Start, cw - 180, 44)
  draw.textF(draw.FONT_SEMI, x + cw - 122, y + topH + 10, best, 13, draw.GRAY, ui.Alignment.End, 114, 18)
  draw.textF(draw.FONT_TXT, x + cw - 122, y + topH + 28, 'MELHOR VLT', 8.5, draw.PHIL_GRAY, ui.Alignment.End, 114, 12)

  -- S1 S2 S3
  local sy = y + ch - 16
  local segW = (cw - 16) / 3
  local act = activeSector(car)
  for k = 1, 3 do
    local sx = x + 8 + (k - 1) * segW
    draw.textF(draw.FONT_TXT, sx, sy - 12, 'S' .. k, 9, (k == act) and draw.WHITE or draw.PHIL_GRAY, ui.Alignment.Center, segW, 12)
    local bc = (k == act) and col or rgbm.from0255(60, 60, 80, 255)
    ui.drawRectFilled(vec2(sx + 6, sy + 2), vec2(sx + segW - 6, sy + 5), bc)
  end
  -- borda colorida
  ui.drawRect(vec2(x + 0.5, y + 0.5), vec2(x + cw - 0.5, y + ch - 0.5), col, 1.2)
end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local sc = cfg.scale
    -- layout base 640x118 em escala 1; aplicamos escala via coordenadas
    local baseW, baseH = 640, 118
    local W, H = baseW * sc, baseH * sc
    -- Como a janela tem tamanho fixo, desenhamos proporcional com fator k
    -- (assumimos janela 660x130; se escala mudar, só aumenta fonte)
    local k = sc
    local cw, ch = 312 * k, 112 * k
    local gap = 8 * k

    local sim = ac.getSim()
    if not sim then return end
    local list = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local car = ac.getCar(i)
      if car and car.isConnected ~= false then
        list[#list + 1] = { idx = i, car = car, pos = car.racePosition or 99 }
      end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b) return a.pos < b.pos end)
    local byIdx = {}
    for _, e in ipairs(list) do byIdx[e.idx] = e end

    local focIdx = sim.focusedCar or 0
    local foc = byIdx[focIdx] or list[1]
    -- AUTO-DIRECTOR: briga mais próxima da pista (<1.2s) vence o focado
    local trackLen = sim.trackLengthM or 4500
    local function pairGap(a, b)
      local dd = carProgress(a.car) - carProgress(b.car)
      if math.abs(dd) > 1.5 or math.abs(dd) < 0.0001 then return nil end
      local behind = dd > 0 and b or a
      local kmh = behind.car.speedKmh or 110
      if type(kmh) ~= 'number' or kmh < 50 then kmh = 110 end
      return math.abs(dd) * trackLen / (kmh / 3.6)
    end
    local showA, showB = foc, nil
    do
      local r = nil
      for i, e in ipairs(list) do
        if e.idx == foc.idx then r = list[i - 1] or list[i + 1] break end
      end
      showB = r or list[1]
      if showB.idx == foc.idx then showB = list[2] or list[1] end
    end
    if cfg.autoBattle and #list >= 2 then
      local bestG, bestPair = 1.2, nil
      for i = 2, #list do
        local g = pairGap(list[i - 1], list[i])
        if g and g < bestG then bestG = g bestPair = { list[i - 1], list[i] } end
      end
      if bestPair then showA, showB = bestPair[1], bestPair[2] end
    end
    local foc2, rival = showA, showB
    -- gap entre os dois exibidos (positivo = rival na frente)
    local d = carProgress(rival.car) - carProgress(foc2.car)
    local gapF = nil
    if math.abs(d) < 1.5 and math.abs(d) > 0.0001 then
      local behind = d > 0 and foc2 or rival
      local kmh = behind.car.speedKmh or 110
      if kmh < 50 then kmh = 110 end
      gapF = math.abs(d) * trackLen / (kmh / 3.6)
    elseif d == 0 then gapF = 0 end

    -- card esq = focado (gap se atrás), card dir = rival (sempre volta)
    -- reposiciona: se rival na frente, ordem [rival][focado]? PHIL mostra P1 esq? Na img1: LEO (P?) esq + GEORGE (P1) dir.
    -- Vamos mostrar: esq = quem está na frente, dir = quem está atrás (gap no da direita? na img gap está na esq...)
    -- Simplificar: esq = focado, dir = rival (igual onboard cockpit img5).
    local gapFoc = (d > 0.0001) and gapF or nil
    local gapRiv = (d < -0.0001) and gapF or nil
    -- trava escala de fonte: drawCard usa px fixos; multiplicamos coords por k manualmente:
    -- (implementação simples: chama com coordenadas escaladas e fontes fixas*k via string? nossas fontes aceitam size float)
    -- Para não reescrever, aplicamos k dentro: temporário via escala de ui? Não há. Fazemos cards com k:
    local function drawCardK(x, y, entry, gapO)
      -- wrapper que escala: copiamos lógica com k aplicado
      local car = entry.car
      local okN, nm = pcall(ac.getDriverName, entry.idx)
      local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or '---'
      local col = draw.driverColor(entry.idx)
      local dark = draw.darken(col, 0.6)
      local topH = 26 * k
      local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
      local ink = lum > 0.65 and draw.PHIL_BG or draw.WHITE
      ui.drawRectFilledMultiColor(vec2(x, y), vec2(x + cw, y + topH), col, dark, dark, col)
      draw.textF(draw.FONT_HEAD, x, y, dname, 15 * k, ink, ui.Alignment.Center, cw, topH)
      ui.drawRectFilled(vec2(x, y + topH), vec2(x + cw, y + ch), draw.PHIL_BG)
      local pos = tostring(car.racePosition or '-')
      local cur = fmtCurrent(car.lapTimeMs or 0)
      local best = draw.fmtLap(car.bestLapTimeMs or 0)
      local big = cur
      if gapO and gapO > 0.05 and gapO < 90 then big = '+' .. string.format('%.3f', gapO) end
      draw.textF(draw.FONT_NUM, x + 8 * k, y + topH + 4 * k, pos, 26 * k, draw.WHITE, ui.Alignment.Center, 40 * k, 40 * k)
      draw.textF(draw.FONT_TXT, x + 8 * k, y + topH + 38 * k, 'POSIÇÃO', 9 * k, draw.PHIL_GRAY, ui.Alignment.Center, 40 * k, 12 * k)
      draw.textF(draw.FONT_NUM, x + 52 * k, y + topH + 6 * k, big, 30 * k, (big:sub(1, 1) == '+') and draw.PHIL_YEL or draw.WHITE, ui.Alignment.Start, (cw - 180 * k), 44 * k)
      draw.textF(draw.FONT_SEMI, x + cw - 122 * k, y + topH + 10 * k, best, 13 * k, draw.GRAY, ui.Alignment.End, 114 * k, 18 * k)
      draw.textF(draw.FONT_TXT, x + cw - 122 * k, y + topH + 28 * k, 'MELHOR VLT', 8.5 * k, draw.PHIL_GRAY, ui.Alignment.End, 114 * k, 12 * k)
      local sy = y + ch - 16 * k
      local segW = (cw - 16 * k) / 3
      local sp = car.splinePosition or 0
      local act = sp < 0.33 and 1 or (sp < 0.66 and 2 or 3)
      for kk = 1, 3 do
        local sx = x + 8 * k + (kk - 1) * segW
        draw.textF(draw.FONT_TXT, sx, sy - 12 * k, 'S' .. kk, 9 * k, (kk == act) and draw.WHITE or draw.PHIL_GRAY, ui.Alignment.Center, segW, 12 * k)
        ui.drawRectFilled(vec2(sx + 6 * k, sy + 2 * k), vec2(sx + segW - 6 * k, sy + 5 * k), (kk == act) and col or rgbm.from0255(60, 60, 80, 255))
      end
      ui.drawRect(vec2(x + 0.5, y + 0.5), vec2(x + cw - 0.5, y + ch - 0.5), col, 1.2)
    end

    drawCardK(0, 0, foc2, gapFoc)
    drawCardK(cw + gap, 0, rival, gapRiv)
    _ = W; _ = H
  end)
  if not ok then ac.debug('PHIL Battle', err) end
end

return M
