-- RACE TV v10 // Minimap em glass com pulso no focado.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local pts = {}
local minX, maxX, minZ, maxZ = 0, 0, 0, 0
local trackKey = nil
local attempted = false
local pulse, intro = 0, 0

function M.init() end
function M.update(dt)
  dt = dt or 0.016
  pulse = pulse + dt
  intro = math.min(1, intro + dt * 2.6)
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() trackKey = nil attempted = false intro = 0 end

local function currentTrack()
  return (ac.getTrackID() or '') .. '/' .. (ac.getTrackLayout() or '')
end

local function rebuild()
  pts = {}
  trackKey = currentTrack()
  attempted = true
  local firstX, firstZ = nil, nil
  for i = 0, 120 do
    local t = i / 120
    local okW, w = pcall(ac.trackCoordinateToWorld, vec3(0, 0, t))
    if okW and w and w.x == w.x and w.z == w.z and math.abs(w.x) < 1e8 and math.abs(w.z) < 1e8 then
      if not firstX then firstX, firstZ = w.x, w.z minX, maxX, minZ, maxZ = w.x, w.x, w.z, w.z end
      if w.x < minX then minX = w.x end
      if w.x > maxX then maxX = w.x end
      if w.z < minZ then minZ = w.z end
      if w.z > maxZ then maxZ = w.z end
      pts[#pts + 1] = { x = w.x, z = w.z }
    end
  end
  if #pts < 10 or (maxX - minX < 1 and maxZ - minZ < 1) then pts = {} end
end

function M.main()
  local sim = ac.getSim()
  if not sim then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 230, 230, 'TV Map')
  local W, H = 230 * k, 230 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'PISTA', 12 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 100 * k, 18 * k)
  local okT, tn = pcall(ac.getTrackID)
  if okT and tn and tn ~= '' then
    draw.textF(draw.FONT_TXT, W - 132 * k, 8 * k, draw.truncate(tostring(tn):upper(), 18), 9 * k,
      draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.End, 120 * k, 18 * k)
  end

  local key = currentTrack()
  if key ~= trackKey or not attempted then rebuild() end
  local pad = 16 * k
  local top = 30 * k
  local bw, bh = W - pad * 2, H - top - pad * 2

  if #pts < 10 then
    draw.textF(draw.FONT_TXT, 0, top + bh / 2 - 10 * k, 'MAPA N/A', 12 * k,
      draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Center, W, 20 * k)
    ui.popClipRect()
    return
  end

  local spanX = math.max(1, maxX - minX)
  local spanZ = math.max(1, maxZ - minZ)
  local sc = math.min(bw / spanX, bh / spanZ)
  local ox = pad + (bw - spanX * sc) / 2
  local oy = top + pad + (bh - spanZ * sc) / 2
  local function proj(x, z)
    return vec2(ox + (x - minX) * sc, oy + (z - minZ) * sc)
  end

  local dx, dz = pts[1].x - pts[#pts].x, pts[1].z - pts[#pts].z
  local closed = math.sqrt(dx * dx + dz * dz) < math.max(spanX, spanZ) * 0.1
  local segments = closed and #pts or #pts - 1
  for i = 1, segments do
    local a = pts[i]
    local b = pts[(i % #pts) + 1]
    ui.drawLine(proj(a.x, a.z), proj(b.x, b.z), rgbm(0, 0, 0, 0.85 * alpha), 7 * k)
  end
  for i = 1, segments do
    local a = pts[i]
    local b = pts[(i % #pts) + 1]
    ui.drawLine(proj(a.x, a.z), proj(b.x, b.z), rgbm(1, 1, 1, 0.9 * alpha), 2.5 * k)
  end

  local focused = sim.focusedCar or 0
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected and not car.isHidingLabels and car.position then
      local q = proj(car.position.x or 0, car.position.z or 0)
      q.x, q.y = math.max(pad, math.min(W - pad, q.x)), math.max(top, math.min(H - pad, q.y))
      if i == focused then
        local pr = 5.5 * k + ((pulse * 14) % (6 * k))
        ui.drawCircle(q, pr, rgbm(1, 1, 1, math.max(0, 0.55 - pr / (14 * k)) * alpha), 12, 1.5)
        ui.drawCircleFilled(q, 4.5 * k, draw.fade(draw.driverColor(i), alpha), 10)
      elseif (car.racePosition or 99) == 1 then
        ui.drawCircleFilled(q, 3.5 * k, draw.fade(draw.PHIL_YEL, alpha), 8)
      else
        ui.drawCircleFilled(q, 2.8 * k, rgbm(1, 1, 1, 0.8 * alpha), 8)
      end
    end
  end
  ui.popClipRect()
end
return M
