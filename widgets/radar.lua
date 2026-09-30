-- ========================================
-- VELOCITY SLASH // widgets/radar.lua
-- Radar circular de batalhas (proximidade por distancia 3D)
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
  local ok, err = pcall(function()
    local cfg = config.get()
    local s = cfg.scale
    local W, H = 230 * s, 230 * s
    draw.slashPanel(0, 0, W, H, cfg, { slash = 18 * s })
    draw.header(0, 0, W, cfg, 'RADAR', pulse * 4)

    local sim = ac.getSim()
    if not sim then return end
    local me = ac.getCar(0)
    if not me or not me.position then
      draw.text(12 * s, 100 * s, 'SEM DADOS', 13 * s, draw.dim(1), ui.Alignment.Center, W - 24 * s, 20 * s)
      return
    end

    local cx, cy = W / 2, 52 * s + 78 * s
    local R = 72 * s
    -- aneis
    ui.drawCircle(vec2(cx, cy), R, rgbm(1, 1, 1, 0.18), 40, 1.5)
    ui.drawCircle(vec2(cx, cy), R * 0.55, rgbm(1, 1, 1, 0.12), 32, 1)
    ui.drawCircle(vec2(cx, cy), R * 0.25, draw.accent(cfg, 0.5), 24, 1)
    -- frente = cima
    draw.text(cx - 30 * s, cy - R - 20 * s, '▲ FRENTE', 10 * s, draw.dim(1), ui.Alignment.Center, 60 * s, 14 * s)

    -- player no centro (triangulo slash)
    ui.drawCircleFilled(vec2(cx, cy), 5 * s, draw.white(1), 12)
    ui.drawCircleFilled(vec2(cx, cy), 2.5 * s, draw.accent(cfg, 1), 8)

    local maxD = 60 -- metros visiveis
    local count = 0
    for i = 0, (sim.carsCount or 1) - 1 do
      if i ~= 0 then
        local c = ac.getCar(i)
        if c and c.isConnected ~= false and c.position then
          local d = dist3(me, c)
          if d and d < maxD then
            count = count + 1
            -- vetor relativo simplificado: usa diferenca XZ, rotaciona pelo look do player se disponivel
            local dx = (c.position.x or 0) - (me.position.x or 0)
            local dz = (c.position.z or 0) - (me.position.z or 0)
            -- tenta compensar orientacao: se look disponivel, projeta
            local rx, rz = dx, dz
            if me.look and me.look.x and me.look.z then
              local fx, fz = me.look.x, me.look.z
              local fl = math.sqrt(fx * fx + fz * fz)
              if fl > 0.01 then
                fx, fz = fx / fl, fz / fl
                -- frente = (fx,fz); direita = (-fz,fx)? mapear para tela: x=dir, y=-frente
                local fwd = dx * fx + dz * fz
                local right = dx * (-fz) + dz * (fx)
                rx, rz = right, -fwd
              end
            end
            local l = math.sqrt(rx * rx + rz * rz)
            if l < 0.5 then l = 0.5 end
            local k = math.min(1, l / maxD) -- 0 centro, 1 borda? na verdade perto=centro
            -- inverter: perto fica perto do centro
            local rr = (l / maxD) * R
            if rr > R then rr = R end
            local nx = cx + (rx / l) * rr
            local ny = cy + (rz / l) * rr
            local col = rgbm(1, 1, 1, 0.9)
            if d < 8 then
              local bl = 0.5 + 0.5 * math.sin(pulse * 8)
              col = rgbm(1, 0.25 + 0.3 * bl, 0.35, 1)
            elseif d < 18 then col = rgbm(1, 0.8, 0.2, 1) end
            ui.drawCircleFilled(vec2(nx, ny), (d < 8 and 5 or 3.5) * s, col, 10)
          end
        end
      end
    end

    local msg = count == 0 and 'PISTA LIVRE' or tostring(count) .. (count == 1 and ' CARRO PERTO' or ' CARROS PERTO')
    local mc = count == 0 and draw.accent(cfg, 1) or rgbm(1, 0.4, 0.5, 1)
    draw.text(0, H - 26 * s, msg, 11.5 * s, mc, ui.Alignment.Center, W, 18 * s)
  end)
  if not ok then ac.debug('VS Radar', err) end
end

return M
