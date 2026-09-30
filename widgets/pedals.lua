-- ========================================
-- VELOCITY SLASH // widgets/pedals.lua
-- Pedals slim + steering: prova de pilotagem para live
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')

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
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 440 * s, 130 * s
    draw.slashPanel(0, 0, W, H, cfg, { slash = 20 * s })
    draw.header(0, 0, W, cfg, 'INPUTS // PROOF', 0)

    -- Sempre inputs do jogador (0): gas/brake/steer reais
    local car = ac.getCar(0)
    if not car then return end
    local gas = draw.clamp(car.gas or 0, 0, 1)
    local brake = draw.clamp(car.brake or 0, 0, 1)
    local clutch = draw.clamp(car.clutch or 0, 0, 1)
    local steer = draw.clamp(car.steer or 0, -1, 1)

    local y0 = 58 * s
    -- labels + barras
    local function pedalRow(label, frac, color, row)
      local ly = y0 + row * 24 * s
      draw.text(14 * s, ly, label, 12 * s, draw.dim(1), ui.Alignment.Start, 44 * s, 18 * s)
      draw.hbar(58 * s, ly + 3 * s, (W - 150 * s), 12 * s, frac, color, rgbm(1, 1, 1, 0.10), 3)
      draw.text(W - 84 * s, ly, string.format('%.0f%%', frac * 100), 12.5 * s, draw.white(1), ui.Alignment.End, 70 * s, 18 * s)
    end

    pedalRow('THR', gas, rgbm(0.15, 0.95, 0.45, 1), 0)
    pedalRow('BRK', brake, rgbm(1, 0.22, 0.28, 1), 1)
    -- steering como barra bipolar + indicador
    local sy = y0 + 2 * 24 * s
    draw.text(14 * s, sy, 'STR', 12 * s, draw.dim(1), ui.Alignment.Start, 44 * s, 18 * s)
    local sw = (W - 150 * s)
    local sx = 58 * s
    ui.drawRectFilled(vec2(sx, sy + 3 * s), vec2(sx + sw, sy + 15 * s), rgbm(1, 1, 1, 0.10), 3)
    -- centro
    ui.drawLine(vec2(sx + sw / 2, sy + 3 * s), vec2(sx + sw / 2, sy + 15 * s), rgbm(1, 1, 1, 0.35), 1)
    local cx = sx + sw / 2 + (sw / 2) * steer
    ui.drawRectFilled(vec2(cx - 3 * s, sy + 1 * s), vec2(cx + 3 * s, sy + 17 * s), draw.accent(cfg, 1), 2)
    local deg = math.floor(math.abs(steer) * 450)
    draw.text(W - 84 * s, sy, (steer < 0 and 'L ' or steer > 0 and 'R ' or '') .. tostring(deg) .. '°', 12.5 * s, draw.white(1), ui.Alignment.End, 70 * s, 18 * s)
  end)
  if not ok then ac.debug('VS Pedals', err) end
end

return M
