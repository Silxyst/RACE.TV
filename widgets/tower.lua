-- ========================================
-- ENDURO TV // widgets/tower.lua
-- Timing Tower solida estilo WEC/IMSA/NLS
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
    local W = 300 * s
    local headH = 30 * s
    local rowH = 26 * s
    local maxRows = cfg.towerRows or 12
    local H = headH + maxRows * rowH + 22 * s

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

    -- HEADER: serie + sessao, cor de bandeira se caution
    local sessTxt = draw.sessionLabel(sim)
    local isCaution = sim.raceFlagType == ac.FlagType.Caution
    local h1, h2, hTxt, hCol
    if isCaution then
      local blink = math.floor(pulse * 1.5) % 2 == 0
      hTxt = blink and 'YELLOW FLAG' or sessTxt
      h1 = draw.YELLOW
      h2 = draw.darken(draw.YELLOW, 0.65)
      hCol = rgbm.from0255(15, 5, 50, 255)
    else
      hTxt = (cfg.series or 'ENDURO TV') .. '  •  ' .. sessTxt
      h1 = cfg.brand1
      h2 = cfg.brand2
      hCol = draw.WHITE
    end
    draw.solidBar(0, 0, W, headH, h1)
    -- sombra gradiente inferior do header
    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), h1, draw.darken(h1, 0.55), draw.darken(h1, 0.55), h1)
    draw.textF(draw.FONT_HEAD, 8 * s, 1 * s, hTxt, 15 * s, hCol, ui.Alignment.Start, W - 16 * s, headH - 2 * s)

    local leaderEntry = list[1]
    local prevEntry = nil
    for r = 1, math.min(maxRows, #list) do
      local e = list[r]
      local car = e.car
      local ry = headH + (r - 1) * rowH
      local isFoc = (e.idx == focused)
      local alt = (r % 2 == 0)

      draw.rowBg(0, ry, W, rowH, alt)
      if isFoc then
        ui.drawRectFilled(vec2(0, ry), vec2(4 * s, ry + rowH), cfg.brand1)
      end
      -- battle: borda fina vermelha
      local gapAhead = prevEntry and estimateGap(prevEntry, e, trackLen) or nil
      if gapAhead and gapAhead < 1.0 and r > 1 then
        local bl = 0.55 + 0.45 * math.sin(pulse * 6)
        ui.drawRect(vec2(0.5, ry + 0.5), vec2(W - 0.5, ry + rowH - 0.5), rgbm(1, 0.2, 0.25, bl), 1)
      end

      -- POS (branco bold italic, P1 com fundo brand)
      if r == 1 then
        ui.drawRectFilled(vec2(4 * s, ry), vec2(34 * s, ry + rowH), cfg.brand1)
        draw.textF(draw.FONT_NUM, 4 * s, ry, tostring(e.pos), 16 * s, draw.WHITE, ui.Alignment.Center, 30 * s, rowH)
      else
        draw.textF(draw.FONT_NUM, 4 * s, ry, tostring(e.pos), 16 * s, draw.WHITE, ui.Alignment.Center, 30 * s, rowH)
      end

      -- Nome (condensado uppercase)
      local okN, nm = pcall(ac.getDriverName, e.idx)
      local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 16) or '---'
      local nameCol = isFoc and draw.WHITE or draw.GRAY
      draw.textF(draw.FONT_BOLD, 36 * s, ry, dname, 14 * s, nameCol, ui.Alignment.Start, 150 * s, rowH)

      -- Tyre dot quadrado estilo TV
      if cfg.showTyre then
        local comp = car.tyreCompound or car.compound
        local tc = draw.tyreColor(comp)
        ui.drawRectFilled(vec2(188 * s, ry + 8 * s), vec2(196 * s, ry + rowH - 8 * s), tc)
      end

      -- Gap
      local gapStr = 'LEADER'
      if r > 1 then
        local gl = estimateGap(leaderEntry, e, trackLen)
        if gapAhead and gapAhead <= 90 then gapStr = draw.fmtSec(gapAhead)
        elseif gl and gl <= 90 then gapStr = draw.fmtSec(gl)
        else gapStr = '+1 LAP' end
      end
      draw.textF(draw.FONT_SEMI, 200 * s, ry, gapStr, 13 * s, draw.GRAY, ui.Alignment.End, 94 * s, rowH)
      prevEntry = e
    end

    -- FOOTER: contagem (navy chapado)
    local fy = headH + math.min(maxRows, #list) * rowH
    ui.drawRectFilled(vec2(0, fy), vec2(W, fy + 22 * s), draw.NAVY)
    draw.textF(draw.FONT_TXT, 8 * s, fy, tostring(#list) .. ' CARS', 11 * s, draw.WHITE, ui.Alignment.Start, 120 * s, 22 * s)
    local okF, fn = pcall(ac.getDriverName, focused)
    draw.textF(draw.FONT_TXT, 130 * s, fy, 'FOCUS P' .. tostring((ac.getCar(focused) or {}).racePosition or '-'), 11 * s, draw.GRAY, ui.Alignment.End, W - 138 * s, 22 * s)
  end)
  if not ok then ac.debug('ETV Tower', err) end
end

return M
