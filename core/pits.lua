-- Count a serviced pit-box visit after leaving, not a drive-through or initial spawn.
local M = {}
local states = {}
function M.update(dt)
  local sim = ac.getSim()
  if not sim then return end
  for i = 0, sim.carsCount - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected then
      local state = states[i]
      if not state then
        state = { stops = 0, lastLap = car.lapCount, inBox = car.isInPit, seconds = 0, leftSpawn = false }
        states[i] = state
      end
      if car.isInPit then
        if not state.inBox then
          state.seconds = 0
          state.visit = state.leftSpawn and sim.isSessionStarted
        end
        state.seconds = state.seconds + (dt or 0)
      elseif state.inBox then
        if state.visit and state.seconds >= 1 then state.stops = state.stops + 1 end
        state.seconds, state.visit = 0, false
      end
      if not car.isInPit and car.speedKmh > 5 then state.leftSpawn = true end
      state.inBox, state.lastLap = car.isInPit, car.lapCount
    else states[i] = nil end
  end
end
function M.get(idx) return states[idx] and states[idx].stops or 0 end
function M.on_session_start() states = {} end
function M.init() end
return M
