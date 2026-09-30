-- ========================================
-- RACE TV // widgets/map.lua
-- Minimap da pista (FSHTV Map): centerline via trackCoordinateToWorld
-- + dots dos carros. Cache por pista.
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
local pts = {} -- {{x, z}}
local minX, maxX, minZ, maxZ = 0, 0, 0, 0
local trackKey = nil

function M.init() end
function M.update(dt) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

local function rebuild()
  pts = {}
  local ok, tid = pcall(ac.getTrackID)
  trackKey = (ok and tid) or '?'
  local firstX, firstZ = nil, nil
  for i = 0, 120 do
    local t = i / 120
    local okW, w = pcall(ac.trackCoordinateToWorld, vec3(0, 0, t))
    if okW and w and w.x then
      if not firstX then firstX, firstZ = w.x, w.z minX, maxX, minZ, maxZ = w.x, w.x, w.z, w.z end
      if w.x < minX then minX = w.x end
      if w.x > maxX then maxX = w.x end
      if w.z < minZ then minZ = w.z end
      if w.z > maxZ then maxZ = w.z end
      pts[#pts + 1] = { x = w.x, z = w.z }
    end
  end
  if #pts < 10 then pts = {} end
end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local k = draw.fit(cfg.scale, 230, 230)
    local W, H = 230 * k, 230 * k
    local headH = 24 * k

    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)
    draw.textF(draw.FONT_HEAD, 8 * k, 0, 'TRACK', 13 * k, draw.WHITE, ui.Alignment.Start, W - 16 * k, headH)
    ui.drawRectFilled(vec2(0, headH), vec2(W, H), draw.PHIL_BG)

    local okT, tid = pcall(ac.getTrackID)
    local key = (okT and tid) or '?'
    if key ~= trackKey or #pts == 0 then rebuild() end
    local sim = ac.getSim()
    if not sim then return end
    local pad = 18 * k
    local bw, bh = W - pad * 2, H - headH - pad * 2

    if #pts < 10 then
      draw.textF(draw.FONT_TXT, 0, headH + bh / 2, 'MAP N/A', 12 * k, draw.PHIL_GRAY, ui.Alignment.Center, W, 20 * k)
      return
    end

    local spanX = math.max(1, maxX - minX)
    local spanZ = math.max(1, maxZ - minZ)
    local sc = math.min(bw / spanX, bh / spanZ)
    local ox = pad + (bw - spanX * sc) / 2
    local oy = headH + pad + (bh - spanZ * sc) / 2
    local function proj(x, z)
      return vec2(ox + (x - minX) * sc, oy + (z - minZ) * sc)
    end

    -- pista: contorno escuro + linha branca
    for i = 1, #pts do
      local a = pts[i]
      local b = pts[(i % #pts) + 1]
      ui.drawLine(proj(a.x, a.z), proj(b.x, b.z), rgbm(0, 0, 0, 0.9), 7 * k)
    end
    for i = 1, #pts do
      local a = pts[i]
      local b = pts[(i % #pts) + 1]
      ui.drawLine(proj(a.x, a.z), proj(b.x, b.z), rgbm(1, 1, 1, 0.92), 3 * k)
    end

    -- carros
    local focused = sim.focusedCar or 0
    for i = 0, (sim.carsCount or 1) - 1 do
      local car = ac.getCar(i)
      if car and car.isConnected ~= false and car.position then
        local p = proj(car.position.x or 0, car.position.z or 0)
        if i == focused then
          ui.drawCircleFilled(p, 5.5 * k, draw.driverColor(i), 10)
          ui.drawCircle(p, 7.5 * k, draw.WHITE, 12, 1.5)
        elseif (car.racePosition or 99) == 1 then
          ui.drawCircleFilled(p, 4 * k, draw.PHIL_YEL, 8)
        else
          ui.drawCircleFilled(p, 3 * k, rgbm(1, 1, 1, 0.85), 8)
        end
      end
    end
  end)
  if not ok then ac.debug('TV Map', err) end
end

return M
