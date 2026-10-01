-- RACE TV v10 // Faixa inferior do piloto em glass.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local intro = 0
local lastFocus = -2
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local f = sim and sim.focusedCar or 0
  if f ~= lastFocus then lastFocus = f intro = 0 end
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 end

function M.main()
  local sim = ac.getSim()
  if not sim then return end
  local foc = sim.focusedCar or 0
  local car = ac.getCar(foc)
  if not car then return end
  local cfg = config.get()
  local k = draw.fit(cfg.scale, 460, 92, 'TV Onboard Bar')
  local W, H = 460 * k, 92 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p
  local slide = (1 - p) * -30 * k

  local okN, nm = pcall(ac.getDriverName, foc)
  local raw = (okN and nm and #tostring(nm) > 0) and tostring(nm) or 'DRIVER'
  local parts = {}
  for w in string.gmatch(raw, '%S+') do parts[#parts + 1] = w end
  local first = parts[1] or ''
  local last = parts[#parts] or ''
  if #parts == 1 then last = parts[1] first = '' end
  local number, team = require('core.branding').driver(foc)
  local code = require('core.classes').short(foc)
  local carName = draw.truncate((team .. (number ~= '' and (' · #' .. number) or '')
    .. (code ~= '' and (' · ' .. code) or '')):upper(), 42)
  local pos = tostring(car.racePosition or '-')
  local best = draw.fmtLap(car.bestLapTimeMs or 0)
  local col = draw.driverColor(foc)

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(slide, 0, W, H, col, alpha)
  -- pílula de posição
  draw.pill(slide + 12 * k, 12 * k, 56 * k, 48 * k, draw.fade(col, alpha))
  local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
  draw.textF(draw.FONT_NUM, slide + 12 * k, 12 * k, pos, 30 * k,
    draw.fade(lum > 0.65 and draw.PHIL_BG or draw.WHITE, alpha), ui.Alignment.Center, 56 * k, 48 * k)
  -- nome com clip próprio
  ui.pushClipRect(vec2(slide + 78 * k, 8 * k), vec2(slide + W - 12 * k, 66 * k), true)
  if #first > 0 then
    draw.textF(draw.FONT_BOLD, slide + 78 * k, 10 * k, first:upper(), 14 * k,
      draw.fade(draw.WHITE, alpha), ui.Alignment.Start, W - 90 * k, 20 * k)
    draw.textF(draw.FONT_HEAD, slide + 78 * k, 28 * k, last:upper(), 23 * k,
      draw.fade(draw.WHITE, alpha), ui.Alignment.Start, W - 90 * k, 30 * k)
  else
    draw.textF(draw.FONT_HEAD, slide + 78 * k, 18 * k, last:upper(), 24 * k,
      draw.fade(draw.WHITE, alpha), ui.Alignment.Start, W - 90 * k, 34 * k)
  end
  ui.popClipRect()
  -- faixa inferior
  ui.drawRectFilled(vec2(slide, H - 22 * k), vec2(slide + W, H), rgbm(0, 0, 0, 0.35 * alpha))
  draw.pill(slide + W - 108 * k, H - 19 * k, 96 * k, 14 * k, draw.fade(draw.WHITE, alpha))
  draw.textF(draw.FONT_HEAD, slide + W - 108 * k, H - 19 * k, 'ONBOARD', 9.5 * k,
    draw.fade(draw.PHIL_BG, alpha), ui.Alignment.Center, 96 * k, 14 * k)
  draw.textF(draw.FONT_TXT, slide + 80 * k, H - 20 * k, carName .. '  ·  BEST ' .. best, 10.5 * k,
    draw.fade(draw.GRAY, alpha), ui.Alignment.Start, W - 200 * k, 16 * k)
  ui.popClipRect()
end
return M
