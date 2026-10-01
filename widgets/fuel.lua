-- RACE TV v12 // Fuel: litros, consumo e autonomia do focado.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')
local intro = 0
local W0, H0 = 300, 118
function M.init() end
function M.update(dt) intro = math.min(1, intro + (dt or 0.016) * 2.6) end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 end

local function num(value)
  if type(value) == 'number' and value == value then return value end
end
function M.main()
  local sim = ac.getSim()
  local car = sim and ac.getCar(sim.focusedCar)
  if not car then return end
  local cfg = config.get()
  local k = cfg.scale
  local W, H = W0 * k, H0 * k
  local alpha = anim.ease_out_quart(intro)

  local fuel, maxFuel, perLap = num(car.fuel), num(car.maxFuel), num(car.fuelPerLap)
  local laps = (fuel and perLap and perLap > 0.001) and fuel / perLap or nil
  local low = (laps and laps < 3) or (fuel and maxFuel and maxFuel > 0 and fuel < 5)
  local bcol = low and draw.RED or draw.GREEN

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, low and draw.RED or cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'FUEL', 13 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 100 * k, 20 * k)
  local okN, nm = pcall(ac.getDriverName, sim.focusedCar or 0)
  local who = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 16) or ''
  if who ~= '' then
    draw.textF(draw.FONT_TXT, W - 172 * k, 8 * k, who, 10 * k, draw.fade(draw.PHIL_GRAY, alpha),
      ui.Alignment.End, 160 * k, 20 * k)
  end
  if not fuel or not maxFuel or maxFuel <= 0 then
    draw.textF(draw.FONT_SEMI, 12 * k, 44 * k, 'SEM DADOS', 20 * k,
      draw.fade(draw.GRAY, alpha), ui.Alignment.Start, 200 * k, 30 * k)
  else
    draw.textF(draw.FONT_NUM, 12 * k, 34 * k, string.format('%.1f', fuel), 38 * k,
      draw.fade(draw.WHITE, alpha), ui.Alignment.Start, 130 * k, 46 * k)
    draw.textF(draw.FONT_TXT, 12 * k, 80 * k, 'LITROS', 10 * k,
      draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Start, 130 * k, 16 * k)
    local info = (perLap and perLap > 0.001) and string.format('%.1f/VOLTA', perLap) or 'CONSUMO ---'
    draw.textF(draw.FONT_SEMI, 150 * k, 40 * k, info, 12 * k,
      draw.fade(draw.GRAY, alpha), ui.Alignment.Start, 140 * k, 22 * k)
    draw.textF(draw.FONT_SEMI, 150 * k, 64 * k,
      laps and string.format('AUTONOMIA %.1f VOLTAS', laps) or 'AUTONOMIA ---', 12 * k,
      draw.fade(low and draw.RED or draw.GREEN, alpha), ui.Alignment.Start, 140 * k, 22 * k)
    local frac = draw.clamp(fuel / maxFuel, 0, 1)
    ui.drawRectFilled(vec2(12 * k, H - 16 * k), vec2(W - 12 * k, H - 8 * k),
      rgbm(1, 1, 1, 0.10 * alpha), 3)
    if frac > 0.003 then
      ui.drawRectFilled(vec2(12 * k, H - 16 * k), vec2(12 * k + (W - 24 * k) * frac, H - 8 * k),
        draw.fade(bcol, alpha), 3)
    end
  end
  ui.popClipRect()
end
return M
