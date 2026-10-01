-- RACE TV v10 // Spotter em glass com anel pulsante.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local pulse, intro = 0, 0
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  pulse = pulse + dt
  intro = math.min(1, intro + dt * 2.6)
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 end

local function dist3(a, b)
  if not a or not b or not a.position or not b.position then return nil end
  local dx = (a.position.x or 0) - (b.position.x or 0)
  local dy = (a.position.y or 0) - (b.position.y or 0)
  local dz = (a.position.z or 0) - (b.position.z or 0)
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.main()
  local sim = ac.getSim()
  local me = sim and ac.getCar(sim.focusedCar)
  if not sim or not me or not me.position then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 190, 210, 'TV Spotter')
  local W, H = 190 * k, 210 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'SPOTTER', 12 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 100 * k, 18 * k)
  local nRing = 0
  for i = 0, (sim.carsCount or 1) - 1 do
    if i ~= sim.focusedCar then
      local c = ac.getCar(i)
      if c and c.isConnected ~= false and c.position and (dist3(me, c) or 999) < 60 then nRing = nRing + 1 end
    end
  end
  local liveDot = (math.floor(pulse * 1.4) % 2 == 0)
  ui.drawCircleFilled(vec2(W - 16 * k, 17 * k), 4 * k,
    nRing > 0 and rgbm(1, 0.3, 0.35, alpha) or rgbm(0.2, 0.85, 0.45, (liveDot and 1 or 0.35) * alpha), 10)

  local cx, cy = W / 2, 34 * k + 78 * k
  local R = 62 * k
  ui.drawCircle(vec2(cx, cy), R, rgbm(0.45, 0.46, 0.55, 0.8 * alpha), 40, 1)
  ui.drawCircle(vec2(cx, cy), R * 0.55, rgbm(0.45, 0.46, 0.55, 0.5 * alpha), 32, 1)
  ui.drawCircle(vec2(cx, cy), R * 0.25, rgbm(0.45, 0.46, 0.55, 0.3 * alpha), 24, 1)
  -- anel pulsante no jogador
  local pr = (pulse * 22) % (R * 0.5)
  ui.drawCircle(vec2(cx, cy), 6 * k + pr, rgbm(1, 1, 1, math.max(0, 0.5 - pr / R) * alpha), 24, 1.5)
  ui.drawCircleFilled(vec2(cx, cy), 4 * k, draw.fade(draw.WHITE, alpha), 10)
  draw.textF(draw.FONT_TXT, cx - 30 * k, cy - R - 15 * k, 'FRENTE', 8 * k,
    draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Center, 60 * k, 12 * k)

  local maxD = 60
  local n = 0
  for i = 0, (sim.carsCount or 1) - 1 do
    if i ~= sim.focusedCar then
      local c = ac.getCar(i)
      if c and c.isConnected ~= false and c.position then
        local d = dist3(me, c)
        if d and d < maxD then
          n = n + 1
          local dx = (c.position.x or 0) - (me.position.x or 0)
          local dz = (c.position.z or 0) - (me.position.z or 0)
          local rx, rz = dx, dz
          if me.look and me.look.x and me.look.z then
            local fx, fz = me.look.x, me.look.z
            local fl = math.sqrt(fx * fx + fz * fz)
            if fl > 0.01 then
              fx, fz = fx / fl, fz / fl
              local fwd = dx * fx + dz * fz
              local right = dx * fz - dz * fx
              rx, rz = right, -fwd
            end
          end
          local l = math.sqrt(rx * rx + rz * rz)
          if l < 0.5 then l = 0.5 end
          local rr = math.min(R, (l / maxD) * R)
          local nx = cx + (rx / l) * rr
          local ny = cy + (rz / l) * rr
          local col = draw.WHITE
          if d < 8 then
            local bl = 0.5 + 0.5 * math.sin(pulse * 8)
            col = rgbm(1, 0.25 + 0.3 * bl, 0.35, alpha)
          elseif d < 18 then col = draw.fade(draw.YELLOW, alpha)
          else col = rgbm(1, 1, 1, 0.85 * alpha) end
          ui.drawCircleFilled(vec2(nx, ny), (d < 8 and 4 * k or 3 * k), col, 8)
        end
      end
    end
  end
  local msg = n == 0 and 'PISTA LIVRE' or (n == 1 and '1 CARRO PERTO' or n .. ' CARROS PERTO')
  local mc = n == 0 and draw.GREEN or draw.RED
  draw.pill(30 * k, H - 26 * k, W - 60 * k, 18 * k, draw.fade(mc, alpha))
  local lum = 0.299 * mc.r + 0.587 * mc.g + 0.114 * mc.b
  draw.textF(draw.FONT_TXT, 30 * k, H - 26 * k, msg, 10 * k,
    draw.fade(lum > 0.6 and draw.PHIL_BG or draw.WHITE, alpha), ui.Alignment.Center, W - 60 * k, 18 * k)
  ui.popClipRect()
end
return M
