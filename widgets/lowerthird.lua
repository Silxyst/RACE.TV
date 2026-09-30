-- ========================================
-- VELOCITY SLASH // widgets/lowerthird.lua
-- Lower-third broadcast: piloto focado + pos + carro + canal
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm
local math = math

local isVisible = false
local pulse = 0
local lastFocus = -1
local slideT = 1 -- 0..1 animacao

function M.init() end
function M.update(dt)
  pulse = pulse + (dt or 0.016)
  local sim = ac.getSim()
  local f = sim and sim.focusedCar or 0
  if f ~= lastFocus then
    lastFocus = f
    slideT = 0
  end
  if slideT < 1 then slideT = math.min(1, slideT + (dt or 0.016) * 3) end
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() slideT = 0 end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 580 * s, 140 * s
    -- slide-in
    local off = (1 - slideT) * -60 * s
    local x, y = off, 0
    draw.slashPanel(x, y, W, H, cfg, { slash = 30 * s, barW = 6 * s })

    local sim = ac.getSim()
    if not sim then return end
    local foc = sim.focusedCar or 0
    local car = ac.getCar(foc)
    if not car then return end

    local okN, nm = pcall(ac.getDriverName, foc)
    local dname = (okN and nm and #tostring(nm) > 0) and tostring(nm) or 'DRIVER'
    local okC, cn = pcall(ac.getCarName, foc)
    local carName = (okC and cn and #tostring(cn) > 0) and tostring(cn) or ''
    local pos = car.racePosition or '-'

    -- POS box
    ui.drawRectFilled(vec2(x + 14 * s, y + 18 * s), vec2(x + 72 * s, y + H - 18 * s), draw.accent(cfg, 1), 6 * s)
    draw.text(x + 14 * s, y + 30 * s, 'P' .. tostring(pos), 30 * s, rgbm(0, 0, 0, 1), ui.Alignment.Center, 58 * s, 44 * s)
    local sess = ac.getSession(sim.currentSessionIndex or 0)
    local tag = 'ON TRACK'
    if car.isInPit then tag = 'IN PIT'
    elseif (car.speedKmh or 0) < 3 then tag = 'STANDBY' end
    draw.text(x + 14 * s, y + H - 44 * s, tag, 10.5 * s, rgbm(0, 0, 0, 0.85), ui.Alignment.Center, 58 * s, 16 * s)

    -- Nome grande
    draw.text(x + 84 * s, y + 20 * s, dname:upper(), 26 * s, draw.white(1), ui.Alignment.Start, 380 * s, 34 * s)
    draw.text(x + 84 * s, y + 54 * s, carName:upper(), 14 * s, draw.accent(cfg, 1), ui.Alignment.Start, 380 * s, 20 * s)

    -- linha + canal
    ui.drawLine(vec2(x + 84 * s, y + 78 * s), vec2(x + W - 20 * s, y + 78 * s), rgbm(1, 1, 1, 0.15), 1)
    -- LIVE + canal
    local pl = 0.6 + 0.4 * math.sin(pulse * 5)
    ui.drawCircleFilled(vec2(x + 90 * s, y + H - 28 * s), 5 * s, rgbm(1, 0.2, 0.25, pl), 12)
    draw.text(x + 102 * s, y + H - 38 * s, string.upper(cfg.channel or 'STREAM') .. '  •  LIVE TIMING', 13 * s, draw.dim(1), ui.Alignment.Start, 340 * s, 20 * s)

    -- best lap canto
    local best = car.bestLapTimeMs or 0
    draw.text(x + W - 170 * s, y + H - 38 * s, 'BEST ' .. draw.fmtLap(best), 13 * s, draw.white(0.95), ui.Alignment.End, 150 * s, 20 * s)
  end)
  if not ok then ac.debug('VS Lower', err) end
end

return M
