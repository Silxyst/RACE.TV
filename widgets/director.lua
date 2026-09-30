-- ========================================
-- RACE TV v5 // widgets/director.lua
-- Auto-director: assistindo + briga próxima = segue a briga sozinho.
-- Só age se você já estiver assistindo (focused ~= 0), nunca pilotando.
-- histerese + dwell 10s para não ficar pulando de câmera.
-- ========================================
local M = {}
local config = require('core.config')

local math = math

local dwell = 0
local currentKey = nil

local function carProgress(car)
  local lap = car.lapCount or 0
  local sp = car.splinePosition or 0
  if type(lap) ~= 'number' then lap = 0 end
  if type(sp) ~= 'number' then sp = 0 end
  return lap + sp
end

function M.init() end
function M.update(dt)
  dt = dt or 0.016
  local cfg = config.get()
  if not cfg.autoDirector then return end
  local sim = ac.getSim()
  if not sim then return end
  if (sim.focusedCar or 0) == 0 then currentKey = nil dwell = 0 return end -- pilotando: não toca
  dwell = dwell + dt

  -- acha par com menor gap
  local list = {}
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected ~= false then
      list[#list + 1] = { idx = i, car = car, pos = car.racePosition or 99 }
    end
  end
  if #list < 2 then return end
  table.sort(list, function(a, b) return a.pos < b.pos end)
  local trackLen = sim.trackLengthM or 4500
  local bestG, bestFront = 1.5, nil
  for i = 2, #list do
    local dd = carProgress(list[i - 1].car) - carProgress(list[i].car)
    if math.abs(dd) < 1.5 and math.abs(dd) > 0.0001 then
      local kmh = list[i].car.speedKmh or 110
      if type(kmh) ~= 'number' or kmh < 50 then kmh = 110 end
      local g = math.abs(dd) * trackLen / (kmh / 3.6)
      if g < bestG then bestG, bestFront = g, list[i - 1] end
    end
  end
  if not bestFront then return end
  local key = bestFront.idx
  if key ~= currentKey and dwell >= 10 then
    pcall(ac.focusCar, key)
    currentKey = key
    dwell = 0
  elseif currentKey == nil then
    currentKey = key
  end
end
function M.on_session_start() dwell = 0 currentKey = nil end
function M.on_open() end
function M.on_close() end

return M
