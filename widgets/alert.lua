-- ========================================
-- RACE TV v4 // widgets/alert.lua
-- Notificação automática (técnica CMRT new_best_sector):
-- FASTEST LAP / YELLOW FLAG com reveal + auto-hide. Top-center.
-- ========================================
local M = {}
local config = require('core.config')
local draw = require('core.draw')
local anim = require('core.anim')

local ac = ac
local ui = ui
local vec2 = vec2
local rgbm = rgbm

local isVisible = false
local showT = 99
local mode = nil -- 'best' | 'pb' | 'flag' | 'green'
local txt1, txt2 = '', ''
local col1 = draw.WHITE
local lastBest = nil
local lastFlag = nil
local lastPB = {}

function M.init() end
function M.update(dt)
  dt = dt or 0.016
  showT = showT + dt
  local sim = ac.getSim()
  if not sim then return end
  -- volta mais rápida da sessão
  local sb, who = nil, nil
  for i = 0, (sim.carsCount or 1) - 1 do
    local c = ac.getCar(i)
    if c and c.isConnected ~= false then
      local b = c.bestLapTimeMs or 0
      if b and b > 0 and (not sb or b < sb) then sb, who = b, i end
    end
  end
  if sb and sb > 0 and (not lastBest or sb < lastBest - 1) then
    if lastBest ~= nil then -- não dispara no load inicial
      local okN, nm = pcall(ac.getDriverName, who)
      mode = 'best'
      txt1 = 'FASTEST LAP'
      txt2 = draw.fullName((okN and nm) or 'DRIVER', 20) .. '  ' .. draw.fmtLap(sb)
      col1 = rgbm.from0255(190, 90, 255, 255)
      showT = 0
    end
    lastBest = sb
  end
  -- personal best do focado (verde LapAlly)
  do
    local foc = sim.focusedCar or 0
    local fc = ac.getCar(foc)
    local pb = fc and fc.bestLapTimeMs or 0
    if pb and pb > 0 and lastPB[foc] and pb < lastPB[foc] - 1 and pb ~= (sb or -1) then
      local okN, nm = pcall(ac.getDriverName, foc)
      mode = 'pb'
      txt1 = 'PERSONAL BEST'
      txt2 = draw.fullName((okN and nm) or 'DRIVER', 20) .. '  ' .. draw.fmtLap(pb)
      col1 = rgbm.from0255(0, 210, 90, 255)
      showT = 0
    end
    if pb and pb > 0 then lastPB[foc] = pb end
  end
  -- flag amarela / verde
  local f = sim.raceFlagType == ac.FlagType.Caution
  if f and not lastFlag then
    mode = 'flag' txt1 = 'YELLOW FLAG' txt2 = 'SLOW DOWN • NO OVERTAKING'
    col1 = draw.YELLOW showT = 0
  elseif not f and lastFlag then
    mode = 'green' txt1 = 'GREEN FLAG' txt2 = 'TRACK CLEAR • RACING'
    col1 = draw.GREEN showT = 0
  end
  lastFlag = f
end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() showT = 99 lastBest = nil lastFlag = nil lastPB = {} end

function M.main()
  if not isVisible then return end
  if showT > 6 then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local k = draw.fit(cfg.scale, 460, 56)
    local W, H = 460 * k, 56 * k
    local clip, alpha, slide = anim.popup(showT, 5, 0.3, 0.3)
    if alpha <= 0.01 then return end
    local y = slide * k
    local cw = W * math.max(0.01, clip)
    ui.pushClipRect(vec2((W - cw) / 2, y), vec2((W + cw) / 2, y + H))
    ui.drawRectFilled(vec2(0, y), vec2(W, y + H), rgbm(8, 8, 18, alpha))
    ui.drawRectFilled(vec2(0, y), vec2(6 * k, y + H), rgbm(col1.r, col1.g, col1.b, alpha))
    draw.textF(draw.FONT_HEAD, 16 * k, y + 2 * k, txt1, 17 * k, rgbm(col1.r, col1.g, col1.b, alpha), ui.Alignment.Start, W - 32 * k, 24 * k)
    draw.textF(draw.FONT_TXT, 16 * k, y + 26 * k, txt2, 12 * k, rgbm(1, 1, 1, alpha), ui.Alignment.Start, W - 32 * k, 20 * k)
    ui.popClipRect()
  end)
  if not ok then ac.debug('TV Alert', err) end
end

return M
