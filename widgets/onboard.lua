-- RACE TV v10 // Barra superior do piloto em glass.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim = require('core.anim')

local lastF = -2
local intro = 0
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  intro = math.min(1, intro + dt * 2.6)
  local sim = ac.getSim()
  local f = sim and sim.focusedCar or 0
  if f ~= lastF then lastF = f intro = 0 end
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
  local k = draw.fit(cfg.scale, 480, 52, 'TV Onboard Top')
  local W, H = 480 * k, 52 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p
  local slide = (1 - p) * -24 * k

  local okN, nm = pcall(ac.getDriverName, foc)
  local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 24) or 'DRIVER'
  local number, customTeam = require('core.branding').driver(foc)
  local code = require('core.classes').short(foc)
  local team = draw.truncate((customTeam .. (number ~= '' and (' · #' .. number) or '')
    .. (code ~= '' and (' · ' .. code) or '')):upper(), 40)
  local pos = tostring(car.racePosition or '-')
  local col = draw.driverColor(foc)
  local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
  local ink = lum > 0.65 and draw.PHIL_BG or draw.WHITE

  local posW, labW = 58 * k, 78 * k
  local nw = W - posW - labW
  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  -- base
  ui.drawRectFilled(vec2(slide, 0), vec2(slide + W, H), draw.surface(0.92 * alpha), 7)
  -- bloco de posição
  ui.drawRectFilled(vec2(slide, 0), vec2(slide + posW, H), draw.fade(col, alpha), 7)
  draw.textF(draw.FONT_NUM, slide, 6 * k, pos, 28 * k, draw.fade(ink, alpha),
    ui.Alignment.Center, posW, 38 * k)
  -- nome com clip próprio
  ui.pushClipRect(vec2(slide + posW + 6 * k, 0), vec2(slide + posW + nw - 6 * k, H), true)
  draw.textF(draw.FONT_HEAD, slide + posW + 6 * k, 4 * k, dname, 19 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, nw - 12 * k, 26 * k)
  draw.textF(draw.FONT_TXT, slide + posW + 6 * k, H - 18 * k, team, 9.5 * k,
    draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Start, nw - 12 * k, 15 * k)
  ui.popClipRect()
  -- selo onboard
  draw.pill(slide + posW + nw + 8 * k, 12 * k, labW - 16 * k, H - 24 * k, draw.fade(draw.WHITE, alpha))
  if not draw.logo(slide + posW + nw + 8*k, 12*k, labW-16*k, H-24*k, alpha) then
    draw.textF(draw.FONT_HEAD, slide + posW + nw + 8 * k, 12 * k, 'PILOTO', 10 * k,
      draw.fade(draw.PHIL_BG, alpha), ui.Alignment.Center, labW - 16 * k, H - 24 * k)
  end
  -- filete inferior
  ui.drawRectFilled(vec2(slide, H - 3 * k), vec2(slide + W, H), draw.fade(col, alpha), 2)
  ui.popClipRect()
end
return M
