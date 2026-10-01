-- Interpolated crossing timestamps at 80 fixed track references per lap.
-- History is bounded to five laps. Pit/teleport/rewind invalidates observations.
local M = {}
local drivers = require('core.drivers')
local states, now = {}, 0
local POINTS, HISTORY = 80, 400
function M.update(sim, rows)
  now = sim.currentSessionTime / 1000
  local seen = {}
  for _, row in ipairs(rows) do
    local car, index, key = row.car, row.idx, drivers.key(row.idx)
    seen[index] = true
    local progress = car.lapCount + car.splinePosition
    local state = states[index]
    local unavailable = not sim.isSessionStarted or car.isInPitlane or car.isInPit or car.isRetired
      or progress ~= progress or car.splinePosition < 0 or car.splinePosition > 1
    if unavailable then states[index] = nil
    elseif not state or state.key ~= key or now < state.time or progress < state.progress - 0.001 then
      states[index] = { key = key, time = now, progress = progress, crossings = {} }
    elseif now > state.time then
      local advance, elapsed = progress - state.progress, now - state.time
      local velocity = advance * math.max(1, sim.trackLengthM) / elapsed
      if advance > 0.15 or elapsed > 2 or velocity > math.max(140, car.speedKmh / 3.6 * 3 + 20) then
        states[index] = { key = key, time = now, progress = progress, crossings = {} }
      else
        if advance > 0 then
          local first, last = math.floor(state.progress * POINTS) + 1, math.floor(progress * POINTS)
          for point = first, last do
            state.crossings[point] = state.time + elapsed * ((point / POINTS - state.progress) / advance)
            state.last = point
          end
          if state.last then
            for point in pairs(state.crossings) do if point < state.last - HISTORY then state.crossings[point] = nil end end
          end
        end
        state.progress, state.time = progress, now
      end
    end
  end
  for index in pairs(states) do if not seen[index] then states[index] = nil end end
end
function M.gap(front, back)
  if not front or not back or front.idx == back.idx then return nil end
  local a, b = states[front.idx], states[back.idx]
  if not a or not b or not b.last then return nil end
  -- Both cars must have actually crossed the same absolute lap checkpoint.
  for point = b.last, b.last - POINTS, -1 do
    local ta, tb = a.crossings[point], b.crossings[point]
    if ta and tb then
      local value = tb - ta
      if value > 0.005 and value < 180 and now - tb < 20 then return value end
      return nil
    end
  end
end
function M.on_session_start() states, now = {}, 0 end
return M
