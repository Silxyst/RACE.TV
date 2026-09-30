-- ========================================
-- ENDURO TV // widgets/pedals.lua
-- Inputs solidos (thr/brk/clutch/steer) estilo pit wall
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')
local cams = require('core.cams')
local winfit = require('core.winfit')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm

local isVisible = false
function M.init() end
function M.update(dt) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

function M.main()
  if not isVisible then return end
  if not cams.gate('TV Inputs') then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = draw.fit(cfg.scale, 300, 132)
    local W, H = 300 * s, 132 * s
    local headH = 24 * s

    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)
    draw.textF(draw.FONT_HEAD, 8 * s, 0, 'INPUTS', 13 * s, draw.WHITE, ui.Alignment.Start, W - 16 * s, headH)
    ui.drawRectFilled(vec2(0, headH), vec2(W, H), draw.DARK)

    local car = ac.getCar(0)
    if not car then return end
    local gas = draw.clamp(car.gas or 0, 0, 1)
    local brake = draw.clamp(car.brake or 0, 0, 1)
    local steer = draw.clamp(car.steer or 0, -1, 1)

    local function bar(label, frac, col, row)
      local y = headH + 10 * s + row * 26 * s
      draw.textF(draw.FONT_TXT, 8 * s, y, label, 11 * s, draw.GRAY, ui.Alignment.Start, 36 * s, 16 * s)
      ui.drawRectFilled(vec2(46 * s, y + 2 * s), vec2(W - 56 * s, y + 14 * s), rgbm.from0255(40, 40, 52, 255))
      ui.drawRectFilled(vec2(46 * s, y + 2 * s), vec2(46 * s + (W - 102 * s) * frac, y + 14 * s), col)
      draw.textF(draw.FONT_SEMI, W - 52 * s, y, string.format('%.0f', frac * 100), 12 * s, draw.WHITE, ui.Alignment.End, 44 * s, 16 * s)
    end

    bar('THR', gas, rgbm.from0255(0, 200, 80, 255), 0)
    bar('BRK', brake, rgbm.from0255(225, 6, 0, 255), 1)

    -- STR bipolar
    local y = headH + 10 * s + 2 * 26 * s
    draw.textF(draw.FONT_TXT, 8 * s, y, 'STR', 11 * s, draw.GRAY, ui.Alignment.Start, 36 * s, 16 * s)
    local bx, bw = 46 * s, W - 102 * s
    ui.drawRectFilled(vec2(bx, y + 2 * s), vec2(bx + bw, y + 14 * s), rgbm.from0255(40, 40, 52, 255))
    ui.drawRectFilled(vec2(bx + bw / 2 - 1, y), vec2(bx + bw / 2 + 1, y + 16 * s), rgbm.from0255(120, 120, 140, 255))
    local cx = bx + bw / 2 + (bw / 2) * steer
    ui.drawRectFilled(vec2(cx - 3 * s, y), vec2(cx + 3 * s, y + 16 * s), draw.WHITE)
    local deg = math.floor(math.abs(steer) * 450)
    draw.textF(draw.FONT_SEMI, W - 52 * s, y, (steer < -0.02 and 'L' or steer > 0.02 and 'R' or '-') .. ' ' .. tostring(deg), 12 * s, draw.WHITE, ui.Alignment.End, 44 * s, 16 * s)
    winfit.fit('TV Inputs', W, H)
  end)
  if not ok then ac.debug('ETV Pedals', err) end
end

return M
