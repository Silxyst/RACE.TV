-- RACE TV v12 // Flags: bandeira gigante para o broadcast.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim, env = require('core.anim'), require('core.env')
local time, intro = 0, 0
local W0, H0 = 460, 84
function M.init() end
function M.update(dt)
  dt = dt or 0.016
  time = time + dt
  intro = math.min(1, intro + dt * 2.6)
end
function M.on_open() end
function M.on_close() end
function M.on_session_start() time, intro = 0, 0 end

function M.main()
  local sim = ac.getSim()
  if not sim then return end
  local cfg = config.get()
  local k = cfg.scale
  local W, H = W0 * k, H0 * k
  local alpha = anim.ease_out_quart(intro)

  local flag, style = env.flag()
  local base = style == 'yellow' and draw.YELLOW
    or (style == 'green' and draw.GREEN or (style == 'white' and draw.WHITE or cfg.brand1))
  local show = true
  if style == 'yellow' then show = math.floor(time * 1.5) % 2 == 0 end

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, base, alpha)
  local bg = show and draw.fade(base, alpha) or draw.surface(0.92 * alpha)
  ui.drawRectFilled(vec2(0, 0), vec2(W, H), bg, 8)
  local ink = (style == 'yellow' or style == 'white') and draw.PHIL_BG or draw.WHITE
  if not show then ink = draw.WHITE end
  draw.textF(draw.FONT_HEAD, 0, 10 * k, show and flag or 'CAUTION', 34 * k,
    draw.fade(ink, alpha), ui.Alignment.Center, W, 46 * k)
  local strip = env.strip()
  if strip then
    draw.textF(draw.FONT_TXT, 0, H - 26 * k, strip, 11 * k,
      draw.fade(show and ink or draw.GRAY, alpha), ui.Alignment.Center, W, 20 * k)
  end
  ui.popClipRect()
end
return M
