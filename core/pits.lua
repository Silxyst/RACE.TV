-- ========================================
-- RACE TV // core/pits.lua
-- Contador de paradas (ACTV pit_stops_count).
-- Conta entradas no pit após a 1ª volta completa (ignora spawn).
-- ========================================
local M = {}

local stops = {}
local wasInPit = {}
local lastKey = nil

function M.update()
  local sim = ac.getSim()
  if not sim then return end
  local key = (ac.getTrackID and ac.getTrackID() or '') .. '#' .. tostring(sim.currentSessionIndex or 0)
  if key ~= lastKey then stops = {} wasInPit = {} lastKey = key end
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    if car then
      local inp = car.isInPit == true
      if inp and not wasInPit[i] then
        if (car.lapCount or 0) >= 1 then
          stops[i] = (stops[i] or 0) + 1
        end
      end
      wasInPit[i] = inp
    end
  end
end

function M.get(idx) return stops[idx] or 0 end
function M.on_session_start() stops = {} wasInPit = {} lastKey = nil end
function M.init() end

return M
