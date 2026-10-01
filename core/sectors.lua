-- ========================================
-- RACE TV // core/sectors.lua
-- Best sectors da sessão (estilo LapAlly recomputeBests simplificado)
-- para colorir S1/S2/S3: roxo overall, verde PB, amarelo resto.
-- ========================================
local M = {}

local mpBest = { nil, nil, nil } -- multiplayer best por setor 1..3
local scanT = 99

local function splitsOf(car)
  if not car then return nil end
  return car.bestSplits
end

function M.update(dt)
  scanT = (scanT or 99) + (dt or 0.016)
  if scanT < 1.0 then return end
  scanT = 0
  local sim = ac.getSim()
  if not sim then return end
  local nb = { nil, nil, nil }
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    local sp = car and splitsOf(car) or nil
    if sp and car.isConnected then
      for s = 0, 2 do
        local t = sp[s] -- splits indexados em 0 (LapAlly/WEC usam [j-1])
        if t and t > 0 and (not nb[s + 1] or t < nb[s + 1]) then nb[s + 1] = t end
      end
    end
  end
  for i = 1, 3 do
    if nb[i] and (not mpBest[i] or nb[i] < mpBest[i]) then mpBest[i] = nb[i] end
  end
end

-- cor do setor s (1..3) do piloto: time = setor fechado nesta volta (ou best)
function M.color(s, time, personalBest)
  return require('core.draw').sectorColor(time, mpBest[s], personalBest)
end

function M.best(s) return mpBest[s] end

function M.on_session_start() mpBest = { nil, nil, nil } scanT = 99 end
function M.init() end

return M
