-- ========================================
-- RACE TV v3 // widgets/onboard.lua
-- Barra superior estilo PHIL: [POS] [NOME colorido + equipe] ONBOARD
-- Top-center da tela.
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

local ac = ac
local ui = ui
local vec2 = vec2

local isVisible = false
local pulse = 0
local lastF = -2
local anim = 1
function M.init() end
function M.update(dt)
  pulse = pulse + (dt or 0.016)
  local sim = ac.getSim()
  local f = sim and sim.focusedCar or 0
  if f ~= lastF then lastF = f anim = 0 end
  if anim < 1 then anim = math.min(1, anim + (dt or 0.016) * 4) end
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() anim = 0 end

function M.main()
  if not isVisible then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local k = draw.fit(cfg.scale, 480, 52)
    local W, H = 480 * k, 52 * k
    local slide = (1 - anim) * -18 * k
    local x, y = slide, 0

    local sim = ac.getSim()
    if not sim then return end
    local foc = sim.focusedCar or 0
    local car = ac.getCar(foc)
    if not car then return end
    local okN, nm = pcall(ac.getDriverName, foc)
    local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 24) or 'DRIVER'
    local okC, cn = pcall(ac.getCarName, foc)
    local team = ((okC and cn) or ''):upper()
    if #team > 22 then team = team:sub(1, 22) end
    local pos = tostring(car.racePosition or '-')
    local col = draw.driverColor(foc)

    local posW, labW = 64 * k, 74 * k
    -- POS box navy
    ui.drawRectFilled(vec2(x, y), vec2(x + posW, y + H), draw.PHIL_BG)
    draw.textF(draw.FONT_NUM, x, y + 2 * k, pos, 30 * k, col, ui.Alignment.Center, posW, 34 * k)
    -- nome bar colorida
    local nx = x + posW
    local nw = W - posW - labW
    local dark = draw.darken(col, 0.7)
    ui.drawRectFilledMultiColor(vec2(nx, y), vec2(nx + nw, y + H), col, dark, dark, col)
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    local ink = lum > 0.65 and draw.PHIL_BG or draw.WHITE
    draw.textF(draw.FONT_HEAD, nx, y + 4 * k, dname, 21 * k, ink, ui.Alignment.Center, nw, 26 * k)
    draw.textF(draw.FONT_TXT, nx, y + H - 16 * k, team, 10 * k, ink, ui.Alignment.Center, nw, 13 * k)
    -- ONBOARD label
    ui.drawRectFilled(vec2(nx + nw, y), vec2(x + W, y + H), draw.PHIL_BG)
    draw.textF(draw.FONT_HEAD, nx + nw, y + 8 * k, 'ONBOARD', 11 * k, draw.WHITE, ui.Alignment.Center, labW, 20 * k)
    -- sublinhado
    ui.drawRectFilled(vec2(nx, y + H - 3 * k), vec2(nx + nw, y + H), draw.PHIL_BG)
  end)
  if not ok then ac.debug('PHIL Onboard', err) end
end

return M
