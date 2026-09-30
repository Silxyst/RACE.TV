-- ========================================
-- RACE TV v3 // widgets/tags.lua
-- Tags broadcast acima dos carros (estilo PHIL: navy + nome + pos)
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

local function tagDraw(car)
  if not car or not car.isConnected then return end
  if car.isInPit and (car.speedKmh or 0) < 5 then return end
  local dist = car.distanceToCamera or 0
  if dist <= 0 or dist > MAXD then return end
  local cfg = config.get()
  if not cfg.showTags then return end

  local okN, nm = pcall(ac.getDriverName, car.index)
  local name = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 18) or ''
  if name == '' then return end
  local pos = tostring(car.racePosition or '')
  local alpha = math.max(0, math.min(1, 1.15 - dist / MAXD))
  if alpha < 0.05 then return end

  -- mede com fonte bold 22px
  ui.pushDWriteFont(draw.FONT_BOLD)
  local ns = ui.measureDWriteText(name, 22)
  local ps = ui.measureDWriteText(pos, 22)
  ui.popDWriteFont()

  local tagW, tagH = 1024, 120
  local cx = tagW / 2
  local nameW = math.min(620, ns.x + 60)
  local posW = ps.x + 70
  local totalW = nameW + posW + 14
  local x0 = cx - totalW / 2
  local y0 = (tagH - 64) / 2

  -- sombra
  ui.drawRectFilled(vec2(x0 + 4, y0 + 5), vec2(x0 + totalW + 4, y0 + 69), rgbm(0, 0, 0, 0.45 * alpha))
  -- pos box navy
  ui.drawRectFilled(vec2(x0, y0), vec2(x0 + posW, y0 + 64), rgbm(10, 10, 22, alpha))
  -- nome box navy claro
  ui.drawRectFilled(vec2(x0 + posW + 6, y0), vec2(x0 + totalW, y0 + 64), rgbm(20, 22, 48, alpha))
  -- linha brand embaixo do nome
  local col = draw.driverColor(car.index)
  ui.drawRectFilled(vec2(x0 + posW + 6, y0 + 58), vec2(x0 + totalW, y0 + 64), rgbm(col.r, col.g, col.b, alpha))

  ui.pushDWriteFont(draw.FONT_NUM)
  ui.setCursor(vec2(x0 + (posW - ps.x) / 2, y0 + (64 - ps.y) / 2))
  ui.dwriteText(pos, 24, rgbm(1, 1, 1, alpha))
  ui.popDWriteFont()

  ui.pushDWriteFont(draw.FONT_BOLD)
  ui.setCursor(vec2(x0 + posW + 6 + (nameW - ns.x) / 2, y0 + (64 - ns.y) / 2))
  ui.dwriteText(name, 22, rgbm(1, 1, 1, alpha))
  ui.popDWriteFont()
end

function M.init() end
function M.update(dt)
  if not registered then
    local ok = pcall(ui.onDriverNameTag, true, rgbm(1, 1, 1, 0), tagDraw,
      { distanceMultiplier = math.ceil(MAXD / 10), tagSize = vec2(1024, 120) })
    if ok then registered = true end
  end
end
function M.on_session_start() end
function M.on_open() end
function M.on_close() end

return M
