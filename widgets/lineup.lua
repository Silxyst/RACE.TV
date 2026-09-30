-- ========================================
-- RACE TV // widgets/lineup.lua
-- STARTING GRID automático (WEC lineup): aparece no pré-race,
-- some sozinho quando o líder abre a volta 2.
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')
local anim = require('core.anim')
local cams = require('core.cams')
local winfit = require('core.winfit')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm
local math = math

local isVisible = false
local intro = 0

function M.init() end
function M.update(dt) intro = intro + (dt or 0.016) end
function M.on_open() isVisible = true intro = 0 end
function M.on_close() isVisible = false end
function M.on_session_start() intro = 0 end

function M.main()
  if not isVisible then return end
  if not cams.gate('TV Lineup') then return end
  local ok, err = pcall(function()
    local sim = ac.getSim()
    if not sim then return end
    -- só no pré-race: sessão de corrida e líder ainda na volta 0
    local sess = ac.getSession(sim.currentSessionIndex or 0)
    local isRace = sess and sess.type == ac.SessionType.Race
    if not isRace then return end
    local list = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local car = ac.getCar(i)
      if car and car.isConnected ~= false then
        list[#list + 1] = { idx = i, car = car, pos = car.racePosition or 99 }
      end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b) return a.pos < b.pos end)
    if (list[1].car.lapCount or 0) >= 1 then return end -- já largou: esconde

    local cfg = config.get()
    local k = draw.fit(cfg.scale, 680, 480)
    local W, H = 680 * k, 480 * k
    local headH = 64 * k
    local rowH = 30 * k
    local maxRows = math.max(4, math.min(12, math.floor((H - headH - 30 * k) / rowH)))

    -- reveal
    local a = anim.ease_out_quart(draw.clamp(intro / 0.5, 0, 1))
    local cw = W * math.max(0.01, a)
    ui.pushClipRect(vec2((W - cw) / 2, 0), vec2((W + cw) / 2, H))

    ui.drawRectFilled(vec2(0, 0), vec2(W, headH), draw.PHIL_BG)
    draw.textF(draw.FONT_HEAD, 0, 6 * k, 'STARTING GRID', 34 * k, draw.WHITE, ui.Alignment.Center, W, 44 * k)
    draw.textF(draw.FONT_TXT, 0, headH - 20 * k, (cfg.series or ''), 12 * k, draw.PHIL_GRAY, ui.Alignment.Center, W, 16 * k)

    for r = 1, math.min(maxRows, #list) do
      local e = list[r]
      local ry = headH + 8 * k + (r - 1) * (rowH + 4 * k)
      if ry + rowH > H then break end
      ui.drawRectFilled(vec2(0, ry), vec2(W, ry + rowH), (r % 2 == 0) and draw.PHIL_ROW2 or draw.PHIL_ROW)
      local cc = require('core.classes').get(e.idx).color
      ui.drawRectFilled(vec2(0, ry), vec2(4 * k, ry + rowH), cc)
      draw.textF(draw.FONT_NUM, 12 * k, ry, 'P' .. e.pos, 17 * k, draw.WHITE, ui.Alignment.Start, 60 * k, rowH)
      local okN, nm = pcall(ac.getDriverName, e.idx)
      draw.textF(draw.FONT_HEAD, 80 * k, ry, draw.fullName((okN and nm) or 'DRIVER', 26), 17 * k, draw.WHITE, ui.Alignment.Start, W - 160 * k, rowH)
      local okC, cn = pcall(ac.getCarName, e.idx)
      draw.textF(draw.FONT_TXT, W - 220 * k, ry, ((okC and cn) or ''):upper():sub(1, 24), 11 * k, draw.PHIL_GRAY, ui.Alignment.End, 212 * k, rowH)
    end
    ui.popClipRect()
    winfit.fit('TV Lineup', W, H)
  end)
  if not ok then ac.debug('TV Lineup', err) end
end

return M
