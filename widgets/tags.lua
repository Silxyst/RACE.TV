-- ========================================
-- RACE TV v5 // widgets/tags.lua
-- GT7 3-box (pos+flag+nome) + outline + smoothstep fade + adjacência.
-- via ui.onDriverNameTag. Sem janela — registrado pelo main.
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ui = ui
local vec2 = vec2
local rgbm = rgbm
local math = math

local registered = false
local MAXD = 220
local TAG_W, TAG_H = 1024, 190
local carVis = {}
local nameCache = {}

local function shortName(n)
  local parts = {}
  for w in tostring(n):gmatch('%S+') do parts[#parts + 1] = w end
  if #parts <= 1 then return tostring(n) end
  return parts[1]:sub(1, 1) .. '. ' .. table.concat(parts, ' ', 2)
end

local function flagPath(idx)
  local ok, code = pcall(ac.getDriverNationCode, idx)
  if ok and code and #tostring(code) > 0 then
    return '/content/gui/NationFlags/' .. string.upper(tostring(code)) .. '.png'
  end
  return nil
end

local function tagDraw(car)
  if not car or not car.isConnected then return end
  local cfg = config.get()
  if not cfg.showTags then return end
  if car.isInPit and (car.speedKmh or 0) < 5 then return end
  local dist = car.distanceToCamera or 0
  if dist <= 0 or dist > MAXD then return end

  -- adjacência (GT7 onlyAdjacent): só ±1 posição do focado
  local adj = 1
  if cfg.tagsAdjacent then
    adj = carVis[car.index] or 0
    if adj <= 0.02 then return end
  end

  local okN, nm = pcall(ac.getDriverName, car.index)
  local raw = (okN and nm and #tostring(nm) > 0) and tostring(nm) or ''
  if raw == '' then return end
  local display = shortName(raw):upper()
  local pos = tostring(car.racePosition or '')

  -- fade GT7: smoothstep por distância
  local t = draw.clamp(1 - dist / MAXD, 0, 1)
  t = math.pow(t, 0.9)
  if t < 0.30 then return end
  local alpha = draw.smoothstep(0.30, 0.55, t) * adj
  if alpha <= 0.02 then return end

  local FS = 30
  ui.pushDWriteFont(draw.FONT_BOLD)
  local ns = ui.measureDWriteText(display, FS)
  local ps = ui.measureDWriteText(pos, FS)
  ui.popDWriteFont()

  local padX, padY, flagGap = 16, 8, 12
  local flagW = 44
  local fp = flagPath(car.index)
  local posW = ps.x + padX * 2
  local flagSegW = fp and (flagW + flagGap * 2) or 0
  local nameW = math.min(560, ns.x + padX * 2)
  local contentH = math.max(ns.y, ps.y, fp and flagW * 0.66 or 0)
  local totalH = contentH + padY * 2
  local totalW = posW + flagSegW + nameW
  local cx = TAG_W / 2
  local x0 = cx - totalW / 2
  local y0 = (TAG_H - totalH) / 2
  local radius = 10

  -- 1) POS (esq)
  ui.drawRectFilled(vec2(x0, y0), vec2(x0 + posW, y0 + totalH),
    rgbm(0, 0, 0, 1 * alpha), radius, ui.CornerFlags.Left)
  -- 2) FLAG (meio)
  local nx = x0 + posW
  if fp then
    ui.drawRectFilled(vec2(nx, y0), vec2(nx + flagSegW, y0 + totalH),
      rgbm(0, 0, 0, 0.62 * alpha))
    local fh = flagW * 0.66
    local fx = nx + (flagSegW - flagW) / 2
    local fy = y0 + (totalH - fh) / 2
    pcall(ui.drawImage, fp, vec2(fx, fy), vec2(fx + flagW, fy + fh), rgbm(1, 1, 1, alpha))
    nx = nx + flagSegW
  end
  -- 3) NOME (dir)
  ui.drawRectFilled(vec2(nx, y0), vec2(nx + nameW, y0 + totalH),
    rgbm(0.07, 0.07, 0.10, 0.55 * alpha), radius, ui.CornerFlags.Right)
  -- risca da cor do piloto
  local col = draw.driverColor(car.index)
  ui.drawRectFilled(vec2(nx, y0 + totalH - 5), vec2(nx + nameW, y0 + totalH),
    rgbm(col.r, col.g, col.b, alpha))

  ui.pushDWriteFont(draw.FONT_NUM)
  ui.setCursor(vec2(x0 + (posW - ps.x) / 2, y0 + (totalH - ps.y) / 2))
  ui.dwriteText(pos, FS, rgbm(1, 1, 1, alpha))
  ui.popDWriteFont()

  ui.pushDWriteFont(draw.FONT_BOLD)
  ui.setCursor(vec2(nx + (nameW - math.min(ns.x, nameW - padX * 2)) / 2, y0 + (totalH - ns.y) / 2))
  ui.beginOutline()
  ui.dwriteText(display, FS, rgbm(1, 1, 1, alpha))
  ui.endOutline(rgbm(0, 0, 0, 0.85 * alpha), 2)
  ui.popDWriteFont()

  -- pedais progressivos sob a tag (THR verde / BRK vermelho)
  -- player + IA animam; oponentes online podem não transmitir inputs (limite do AC)
  if cfg.pedalTags then
    local gas = draw.clamp(car.gas or 0, 0, 1)
    local brk = draw.clamp(car.brake or 0, 0, 1)
    local bw = totalW
    local bx = cx - bw / 2
    local by = y0 + totalH + 8
    local bh = 10
    -- THR
    ui.drawRectFilled(vec2(bx, by), vec2(bx + bw, by + bh), rgbm(0, 0, 0, 0.62 * alpha))
    if gas > 0.01 then
      ui.drawRectFilled(vec2(bx, by), vec2(bx + bw * gas, by + bh), rgbm(0.15, 0.95, 0.35, alpha))
    end
    -- BRK
    local by2 = by + bh + 4
    ui.drawRectFilled(vec2(bx, by2), vec2(bx + bw, by2 + bh), rgbm(0, 0, 0, 0.62 * alpha))
    if brk > 0.01 then
      ui.drawRectFilled(vec2(bx, by2), vec2(bx + bw * brk, by2 + bh), rgbm(1, 0.15, 0.2, alpha))
    end
  end
end

function M.init() end
function M.update(dt)
  dt = dt or 0.016
  if not registered then
    local ok = pcall(ui.onDriverNameTag, true, rgbm(1, 1, 1, 0), tagDraw,
      { distanceMultiplier = math.ceil(MAXD / 10), tagSize = vec2(TAG_W, TAG_H) })
    if ok then registered = true end
  end
  -- fade de adjacência (GT7 moveTowards)
  local cfg = config.get()
  if cfg.tagsAdjacent then
    local sim = ac.getSim()
    local foc = sim and ac.getCar(sim.focusedCar or 0) or nil
    local fp = foc and foc.racePosition or nil
    local maxD = dt / 0.35
    for i = 0, (sim and sim.carsCount or 1) - 1 do
      local car = ac.getCar(i)
      local tgt = 0
      if car and car.isConnected and fp and car.racePosition then
        local d = car.racePosition - fp
        if d == 1 or d == -1 or i == (sim.focusedCar or 0) then tgt = 1 end
      end
      carVis[i] = draw.moveTowards(carVis[i] or 0, tgt, maxD)
    end
  end
  _ = nameCache
end
function M.on_session_start() end
function M.on_open() end
function M.on_close() end

return M
