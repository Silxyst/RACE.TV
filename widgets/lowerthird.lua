-- ========================================
-- ENDURO TV // widgets/lowerthird.lua
-- Onboard bar estilo WEC: numero grande + nome + carro + faixa ONBOARD
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
local lastFocus = -2
local anim = 1

function M.init() end
function M.update(dt)
  pulse = pulse + (dt or 0.016)
  local sim = ac.getSim()
  local f = sim and sim.focusedCar or 0
  if f ~= lastFocus then lastFocus = f anim = 0 end
  if anim < 1 then anim = math.min(1, anim + (dt or 0.016) * 3.2) end
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() anim = 0 end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 460 * s, 92 * s
    local stripH = 20 * s
    -- slide
    local xoff = (1 - anim) * -40 * s
    local x, y = xoff, 0

    local sim = ac.getSim()
    if not sim then return end
    local foc = sim.focusedCar or 0
    local car = ac.getCar(foc)
    if not car then return end

    local okN, nm = pcall(ac.getDriverName, foc)
    local raw = (okN and nm and #tostring(nm) > 0) and tostring(nm) or 'DRIVER'
    local parts = {}
    for w in string.gmatch(raw, '%S+') do parts[#parts + 1] = w end
    local first = parts[1] or ''
    local last = parts[#parts] or ''
    if #parts == 1 then last = parts[1] first = '' end
    local okC, cn = pcall(ac.getCarName, foc)
    local carName = ((okC and cn) or ''):upper()
    if #carName > 30 then carName = carName:sub(1, 30) end
    local pos = tostring(car.racePosition or '-')
    local best = draw.fmtLap(car.bestLapTimeMs or 0)

    -- barra principal brand gradient
    local bh = H - stripH
    ui.drawRectFilledMultiColor(vec2(x, y), vec2(x + W, y + bh), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)

    -- numero POS (esq, gigante italic)
    draw.textF(draw.FONT_NUM, x + 10 * s, y - 2 * s, pos, 52 * s, draw.WHITE, ui.Alignment.Start, 80 * s, bh)
    ui.drawRectFilled(vec2(x + 78 * s, y + 10 * s), vec2(x + 80 * s, y + bh - 10 * s), rgbm(1, 1, 1, 0.5))

    -- nome
    if #first > 0 then
      draw.textF(draw.FONT_BOLD, x + 90 * s, y + 6 * s, first:upper(), 15 * s, draw.WHITE, ui.Alignment.Start, 300 * s, 20 * s)
      draw.textF(draw.FONT_HEAD, x + 90 * s, y + 24 * s, last:upper(), 24 * s, draw.WHITE, ui.Alignment.Start, 300 * s, 28 * s)
    else
      draw.textF(draw.FONT_HEAD, x + 90 * s, y + 14 * s, last:upper(), 26 * s, draw.WHITE, ui.Alignment.Start, 300 * s, 32 * s)
    end
    draw.textF(draw.FONT_TXT, x + 90 * s, y + bh - 22 * s, carName, 11 * s, rgbm(1, 1, 1, 0.9), ui.Alignment.Start, 300 * s, 16 * s)

    -- faixa inferior navy: ONBOARD + serie + best
    ui.drawRectFilled(vec2(x, y + bh), vec2(x + W, y + H), draw.NAVY)
    local sw = 110 * s
    ui.drawRectFilled(vec2(x + W - sw, y + bh), vec2(x + W, y + H), draw.WHITE)
    draw.textF(draw.FONT_HEAD, x + W - sw, y + bh, 'ONBOARD', 12 * s, draw.NAVY, ui.Alignment.Center, sw, stripH)
    draw.textF(draw.FONT_TXT, x + 8 * s, y + bh, (cfg.series or '') .. '  •  BEST ' .. best, 11 * s, draw.WHITE, ui.Alignment.Start, W - sw - 16 * s, stripH)

    -- clip animacao (reveal)
    -- (simples: ja faz slide; sem clip extra para nao quebrar)
  end)
  if not ok then ac.debug('ETV Lower', err) end
end

return M
