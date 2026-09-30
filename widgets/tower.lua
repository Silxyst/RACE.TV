-- ========================================
-- VELOCITY SLASH // widgets/tower.lua
-- Timing Tower broadcast com gaps estimados + battle highlight
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ac = ac
local ui = ui
local rgbm = rgbm
local vec2 = vec2
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
  local leaderCar, car = leaderEntry.car, entry.car
  if not leaderCar or not car then return nil end
  local lp = carProgress(leaderCar)
  local cp = carProgress(car)
  local diff = lp - cp
  if diff < 0 then diff = 0 end
  if diff > 1.5 then return nil end -- volta completa, mostra VOLTA
  local kmh = car.speedKmh or 120
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
    local W, H = 340 * s, 580 * s
    local x, y = 0, 0
    draw.slashPanel(x, y, W, H, cfg, { slash = 22 * s })
    draw.header(x, y, W, cfg, 'TIMING TOWER', pulse * 4)

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

    local maxRows = cfg.towerRows or 10
    local rowH = 34 * s
    local startY = y + 52 * s
    local leaderEntry = list[1]

    -- session label
    local sess = ac.getSession(sim.currentSessionIndex or 0)
    local sessName = 'RACE'
    if sess and sess.type then
      local t = sess.type
      -- ac.SessionType: 0 practice? mapear generico
      if t == ac.SessionType.Qualify then sessName = 'QUALIFY'
      elseif t == ac.SessionType.Practice then sessName = 'PRACTICE'
      elseif t == ac.SessionType.Race then sessName = 'RACE'
      else sessName = tostring(t):upper() end
    end
    draw.text(x + 12 * s, startY - 20 * s, sessName .. '  •  ' .. tostring(#list) .. ' CARS', 12 * s, draw.dim(1), ui.Alignment.Start, 200 * s, 16 * s)

    local prevEntry = nil
    for r = 1, math.min(maxRows, #list) do
      local e = list[r]
      local car = e.car
      local ry = startY + (r - 1) * (rowH + 4 * s)
      local isFoc = (e.idx == focused)
      local gapLeader = estimateGap(leaderEntry, e, trackLen)
      local gapAhead = prevEntry and estimateGap(prevEntry, e, trackLen) or nil
      local isBattle = (gapAhead and gapAhead < 1.0) or (r > 1 and gapLeader and gapLeader < 1.5 and r <= 3)

      -- fundo linha
      local bgA = isFoc and 0.55 or 0.32
      local bgc = isFoc and rgbm(1, 1, 1, 0.10 * cfg.opacity) or rgbm(1, 1, 1, 0.045 * cfg.opacity)
      ui.drawRectFilled(vec2(x + 8 * s, ry), vec2(x + W - 8 * s, ry + rowH), bgc, 5 * s)
      if isFoc then
        ui.drawRectFilled(vec2(x + 8 * s, ry), vec2(x + 12 * s, ry + rowH), draw.accent(cfg, 1), 2)
      end
      if isBattle then
        local bl = 0.35 + 0.35 * math.sin(pulse * 6)
        ui.drawRect(vec2(x + 8 * s, ry), vec2(x + W - 8 * s, ry + rowH), rgbm(1, 0.25, 0.4, bl), 1.5)
      end

      -- POS
      local posCol = r == 1 and draw.accent(cfg, 1) or draw.white(1)
      if r == 1 then
        ui.drawRectFilled(vec2(x + 14 * s, ry + 5 * s), vec2(x + 38 * s, ry + rowH - 5 * s), draw.accent(cfg, 1), 4 * s)
        posCol = rgbm(0, 0, 0, 1)
      end
      draw.text(x + 14 * s, ry + 1 * s, tostring(e.pos), 17 * s, posCol, ui.Alignment.Center, 24 * s, rowH - 2 * s)

      -- Nome
      local dname = '---'
      local okN, nm = pcall(ac.getDriverName, e.idx)
      if okN and nm and #tostring(nm) > 0 then dname = tostring(nm) end
      draw.text(x + 44 * s, ry + 1 * s, draw.shortName(dname), 14.5 * s, draw.white(1), ui.Alignment.Start, 130 * s, rowH - 2 * s)

      -- tyre dot
      if cfg.showTyre then
        local comp = car.tyreCompound or car.compound or car.tyreShortName
        local tc = draw.tyreColor(comp)
        ui.drawCircleFilled(vec2(x + 178 * s, ry + rowH * 0.5), 4.5 * s, tc, 10)
      end

      -- Gap
      local gapStr = 'LEADER'
      if r > 1 then
        if gapAhead and gapAhead <= 90 then gapStr = draw.fmtSec(gapAhead)
        elseif gapLeader and gapLeader <= 90 then gapStr = draw.fmtSec(gapLeader)
        else gapStr = '+1 LAP' end
      end
      local gapCol = isBattle and rgbm(1, 0.35, 0.5, 1) or draw.dim(1)
      draw.text(x + W - 118 * s, ry + 1 * s, gapStr, 13.5 * s, gapCol, ui.Alignment.End, 100 * s, rowH - 2 * s)

      prevEntry = e
    end

    -- footer: focused
    local okF, fname = pcall(ac.getDriverName, focused)
    local flabel = 'FOCUS: ' .. draw.shortName(okF and fname or 'YOU')
    draw.text(x + 12 * s, y + H - 22 * s, flabel, 11 * s, draw.accent(cfg, 1), ui.Alignment.Start, (W - 24 * s), 16 * s)
  end)
  if not ok then ac.debug('VS Tower', err) end
end

return M
