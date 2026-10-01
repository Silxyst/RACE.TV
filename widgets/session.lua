-- RACE TV v12 // Session: relógio grande, bandeira e ambiente para o broadcast.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim, env = require('core.anim'), require('core.env')
local intro = 0
local W0, H0 = 460, 120
function M.init() end
function M.update(dt) intro = math.min(1, intro + (dt or 0.016) * 2.6) end
function M.on_open() end
function M.on_close() end
function M.on_session_start() intro = 0 end

function M.main()
  local sim = ac.getSim()
  if not sim then return end
  local cfg = config.get()
  local k = cfg.scale
  local W, H = W0 * k, H0 * k
  local alpha = anim.ease_out_quart(intro)

  local flag, style = env.flag()
  local strip = env.strip()
  local clock = draw.sessionClock(sim)
  local sess = ac.getSession and ac.getSession(sim.currentSessionIndex or 0)
  local laps = sess and sess.laps or 0
  local label = draw.sessionLabel(sim)
  if laps and laps > 0 and not require('core.data').quali(sim) then
    local ok, count = pcall(function() return sim.leaderLapCount end)
    clock = string.format('%d/%d', math.min((ok and count or 0) + 1, laps), laps)
  end

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  local hasLogo = draw.logo(12 * k, 10 * k, 40 * k, 40 * k, alpha)
  draw.textF(draw.FONT_HEAD, (hasLogo and 60 or 12) * k, 8 * k, cfg.series, 22 * k,
    draw.fade(draw.WHITE, alpha), ui.Alignment.Start, W - (hasLogo and 72 or 24) * k, 28 * k)
  draw.textF(draw.FONT_TXT, (hasLogo and 60 or 12) * k, 36 * k, label, 11 * k,
    draw.fade(draw.dim(1), alpha), ui.Alignment.Start, 200 * k, 18 * k)
  draw.textF(draw.FONT_NUM, W - 212 * k, 30 * k, clock, 30 * k,
    draw.fade(draw.WHITE, alpha), ui.Alignment.End, 200 * k, 40 * k)
  draw.flagPill(12 * k, 62 * k, 130 * k, 22 * k, flag, style, alpha)
  if strip then
    draw.textF(draw.FONT_TXT, 150 * k, 62 * k, strip, 11 * k,
      draw.fade(draw.PHIL_GRAY, alpha), ui.Alignment.Start, W - 162 * k, 22 * k)
  end
  local elapsed = math.max(0, sim.currentSessionTime or 0)
  local left = math.max(0, sim.sessionTimeLeft or 0)
  local frac = (elapsed + left > 0) and elapsed / (elapsed + left) or 0
  ui.drawRectFilled(vec2(12 * k, H - 14 * k),
    vec2(12 * k + (W - 24 * k) * draw.clamp(frac, 0, 1), H - 10 * k),
    rgbm(1, 1, 1, 0.45 * alpha))
  ui.popClipRect()
end
return M
