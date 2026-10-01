-- RACE TV v10 // Inputs com barras suavizadas em glass.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local intro = 0
local sGas, sBrk, sStr = 0, 0, 0
local snapped = false
local lastFocus
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if sim and lastFocus ~= sim.focusedCar then snapped = false lastFocus = sim.focusedCar end
  if car then
    local angle = car.steer or 0
    local g = draw.clamp(car.gas or 0, 0, 1)
    local b = draw.clamp(car.brake or 0, 0, 1)
    local s = draw.clamp(angle / math.max(1, car.steerLock), -1, 1)
    if not snapped then sGas, sBrk, sStr, snapped = g, b, s, true end
    sGas = anim.damp(sGas, g, 14, dt)
    sBrk = anim.damp(sBrk, b, 14, dt)
    sStr = anim.damp(sStr, s, 14, dt)
  end
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 sGas, sBrk, sStr = 0, 0, 0 snapped = false lastFocus = nil end

function M.main()
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if not car then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 300, 132, 'TV Inputs')
  local W, H = 300 * k, 132 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'INPUTS', 12 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 120 * k, 18 * k)
  local okN, nm = pcall(ac.getDriverName, sim.focusedCar or 0)
  local who = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 18) or ''
  if who ~= '' then
    draw.textF(draw.FONT_TXT, W - 172 * k, 8 * k, who, 10 * k, draw.fade(draw.PHIL_GRAY, alpha),
      ui.Alignment.End, 160 * k, 18 * k)
  end

  local function bar(label, frac, col, row)
    local y = 32 * k + row * 30 * k
    draw.textF(draw.FONT_TXT, 12 * k, y, label, 11 * k, draw.fade(draw.GRAY, alpha),
      ui.Alignment.Start, 34 * k, 18 * k)
    ui.drawRectFilled(vec2(50 * k, y + 3 * k), vec2(W - 58 * k, y + 15 * k), rgbm(1, 1, 1, 0.10 * alpha), 3)
    if frac > 0.003 then
      ui.drawRectFilled(vec2(50 * k, y + 3 * k), vec2(50 * k + (W - 108 * k) * frac, y + 15 * k),
        draw.fade(col, alpha), 3)
    end
    draw.textF(draw.FONT_SEMI, W - 52 * k, y, string.format('%.0f', frac * 100), 12 * k,
      draw.fade(draw.WHITE, alpha), ui.Alignment.End, 42 * k, 18 * k)
  end

  bar('THR', sGas, draw.GREEN, 0)
  bar('BRK', sBrk, draw.RED, 1)

  -- direção bipolar
  local y = 32 * k + 2 * 30 * k
  draw.textF(draw.FONT_TXT, 12 * k, y, 'STR', 11 * k, draw.fade(draw.GRAY, alpha),
    ui.Alignment.Start, 34 * k, 18 * k)
  local bx, bw = 50 * k, W - 108 * k
  ui.drawRectFilled(vec2(bx, y + 3 * k), vec2(bx + bw, y + 15 * k), rgbm(1, 1, 1, 0.10 * alpha), 3)
  ui.drawRectFilled(vec2(bx + bw / 2 - 1, y + 1 * k), vec2(bx + bw / 2 + 1, y + 17 * k),
    rgbm(1, 1, 1, 0.35 * alpha))
  local cx = bx + bw / 2 + (bw / 2 - 3 * k) * sStr
  ui.drawRectFilled(vec2(cx - 3 * k, y + 1 * k), vec2(cx + 3 * k, y + 17 * k), draw.fade(draw.WHITE, alpha), 2)
  local deg = math.floor(math.abs(car.steer or 0) + 0.5)
  local dir = sStr < -0.02 and 'L ' or (sStr > 0.02 and 'R ' or '')
  draw.textF(draw.FONT_SEMI, W - 52 * k, y, dir .. deg, 12 * k,
    draw.fade(draw.WHITE, alpha), ui.Alignment.End, 42 * k, 18 * k)
  ui.popClipRect()
end
return M
