-- RACE TV v10 // Starting Grid em glass com entrada escalonada.
local M = {}
local config, draw, data, anim = require('core.config'), require('core.draw'), require('core.data'), require('core.anim')
local intro, wasShown, timer = 0, false, 0
function M.init() end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 timer = 0 wasShown = false end
function M.update(dt)
  dt = dt or 0.016
  timer = timer + dt
  local sim = ac.getSim()
  local show = sim and not data.quali(sim) and not sim.isSessionStarted
  if show and not wasShown then intro = 0 end
  if show then intro = math.min(1, intro + dt * 1.6) end
  wasShown = show
end
function M.main()
  if not wasShown or #data.list == 0 then return end
  local cfg = config.get()
  local rows = math.min(10, #data.list)
  local pages = math.ceil(#data.list / rows)
  local page = math.floor(timer / 6) % pages
  local k = draw.fit(cfg.scale, 680, 78 + rows * 34, 'TV Lineup')
  local W, H = 680 * k, 418 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.logo(14*k, 10*k, 36*k, 36*k, alpha)
  draw.textF(draw.FONT_HEAD, 0, 8 * k, 'STARTING GRID', 30 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Center, W, 40 * k)
  draw.textF(draw.FONT_TXT, 0, 48 * k, cfg.series .. '  ·  ' .. (page + 1) .. '/' .. pages, 11 * k,
    draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Center, W, 18 * k)
  for slot = 1, rows do
    local row = data.list[page * rows + slot]
    if row then
      local rp = anim.ease_out_quart(draw.clamp(intro * 1.4 - (slot - 1) * 0.05, 0, 1))
      local ry = (74 + (slot - 1) * 34) * k
      local rx = (1 - rp) * 30 * k
      ui.drawRectFilled(vec2(rx, ry), vec2(rx + W, ry + 30 * k),
        rgbm(1, 1, 1, (slot % 2 == 0 and 0.05 or 0.025) * rp * alpha), 6)
      local cc = require('core.classes').get(row.idx).color
      ui.drawRectFilled(vec2(rx + 10 * k, ry + 6 * k), vec2(rx + 14 * k, ry + 24 * k), draw.fade(cc, rp * alpha))
      draw.textF(draw.FONT_NUM, rx + 20 * k, ry, 'P' .. row.pos, 16 * k,
        draw.fade(draw.WHITE, rp * alpha), ui.Alignment.Start, 56 * k, 30 * k)
      draw.textF(draw.FONT_HEAD, rx + 84 * k, ry, draw.fullName(ac.getDriverName(row.idx), 34), 16 * k,
        draw.fade(draw.WHITE, rp * alpha), ui.Alignment.Start, 350 * k, 30 * k)
      local number, team = require('core.branding').driver(row.idx)
      draw.textF(draw.FONT_TXT, rx + 440 * k, ry, draw.truncate((team .. (number ~= '' and (' · #' .. number) or '')):upper(), 24), 10.5 * k,
        draw.fade(draw.PHIL_GRAY, rp * alpha), ui.Alignment.End, 222 * k, 30 * k)
    end
  end
  ui.popClipRect()
end
return M
