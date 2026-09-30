-- ========================================
-- ENDURO TV // widgets/radar.lua
-- Spotter box solida (proximidade 60m)
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
local math = math

local isVisible = false
local pulse = 0
function M.init() end
function M.update(dt) pulse = pulse + (dt or 0.016) end
function M.on_open() isVisible = true end
function M.on_close() isVisible = false end
function M.on_session_start() end

local function dist3(a, b)
  if not a or not b or not a.position or not b.position then return nil end
  local dx = (a.position.x or 0) - (b.position.x or 0)
  local dy = (a.position.y or 0) - (b.position.y or 0)
  local dz = (a.position.z or 0) - (b.position.z or 0)
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.main()
  if not isVisible then return end
  if not cams.gate('TV Spotter') then return end
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = draw.fit(cfg.scale, 190, 210)
    local W, H = 190 * s, 210 * s
    local headH = 24 * s

    ui.drawRectFilledMultiColor(vec2(0, 0), vec2(W, headH), cfg.brand1, draw.darken(cfg.brand1, 0.55), draw.darken(cfg.brand1, 0.55), cfg.brand1)
    draw.textF(draw.FONT_HEAD, 8 * s, 0, 'SPOTTER', 13 * s, draw.WHITE, ui.Alignment.Start, W - 16 * s, headH)
    ui.drawRectFilled(vec2(0, headH), vec2(W, H), draw.DARK)

    local sim = ac.getSim()
    if not sim then return end
    local me = ac.getCar(0)
    if not me or not me.position then
      draw.textF(draw.FONT_TXT, 0, headH + 70 * s, 'NO DATA', 12 * s, draw.GRAY, ui.Alignment.Center, W, 20 * s)
      return
    end

    local cx, cy = W / 2, headH + 82 * s
    local R = 66 * s
    ui.drawCircle(vec2(cx, cy), R, rgbm.from0255(90, 90, 110, 255), 40, 1)
    ui.drawCircle(vec2(cx, cy), R * 0.55, rgbm.from0255(70, 70, 90, 255), 32, 1)
    ui.drawCircleFilled(vec2(cx, cy), 4 * s, draw.WHITE, 10)
    -- frente
    draw.textF(draw.FONT_TXT, cx - 30 * s, cy - R - 16 * s, 'FRONT', 9 * s, draw.GRAY, ui.Alignment.Center, 60 * s, 12 * s)

    local maxD = 60
    local n = 0
    for i = 0, (sim.carsCount or 1) - 1 do
      if i ~= 0 then
        local c = ac.getCar(i)
        if c and c.isConnected ~= false and c.position then
          local d = dist3(me, c)
          if d and d < maxD then
            n = n + 1
            local dx = (c.position.x or 0) - (me.position.x or 0)
            local dz = (c.position.z or 0) - (me.position.z or 0)
            local rx, rz = dx, dz
            if me.look and me.look.x and me.look.z then
              local fx, fz = me.look.x, me.look.z
              local fl = math.sqrt(fx * fx + fz * fz)
              if fl > 0.01 then
                fx, fz = fx / fl, fz / fl
                local fwd = dx * fx + dz * fz
                local right = dx * (-fz) + dz * fx
                rx, rz = right, -fwd
              end
            end
            local l = math.sqrt(rx * rx + rz * rz)
            if l < 0.5 then l = 0.5 end
            local rr = math.min(R, (l / maxD) * R)
            local nx = cx + (rx / l) * rr
            local ny = cy + (rz / l) * rr
            local col = draw.WHITE
            if d < 8 then
              local bl = 0.5 + 0.5 * math.sin(pulse * 8)
              col = rgbm(1, 0.25 + 0.3 * bl, 0.35, 1)
            elseif d < 18 then col = rgbm.from0255(255, 200, 40, 255) end
            ui.drawCircleFilled(vec2(nx, ny), (d < 8 and 4.5 or 3) * s, col, 8)
          end
        end
      end
    end
    local msg = n == 0 and 'CLEAR' or tostring(n) .. ' CLOSE'
    draw.textF(draw.FONT_SEMI, 0, H - 22 * s, msg, 12 * s, n == 0 and rgbm.from0255(0, 200, 80, 255) or rgbm.from0255(255, 80, 90, 255), ui.Alignment.Center, W, 18 * s)
    winfit.fit('TV Spotter', W, H)
  end)
  if not ok then ac.debug('ETV Radar', err) end
end

return M
