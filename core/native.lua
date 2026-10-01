-- Official game gaps and numbers, throttled and failure-safe.
-- ac.getGapBetweenCars returns seconds (negative when the main car is ahead).
-- Refresh at most every 2s, like proven broadcast towers do.
local M = { gaps = {}, leader = nil, time = 0, focused = {}, focus = nil }
local INTERVAL = 2.0
local function callable(fn) return type(fn) == 'function' end
function M.update(dt)
  M.time = M.time + math.max(0, dt or 0)
  local sim = ac.getSim()
  if not sim or not callable(ac.getGapBetweenCars) then M.gaps, M.leader = {}, nil return end
  local data = require('core.data')
  if #data.list == 0 then M.gaps, M.leader = {}, nil return end
  local leader = data.list[1].idx
  local focus = sim.focusedCar
  local changed = M.leader ~= leader or M.focus ~= focus
  if changed then M.gaps, M.focused, M.leader, M.focus = {}, {}, leader, focus end
  if not changed and M.time - (M.stamp or -99) < INTERVAL then return end
  M.stamp = M.time
  local fresh, rel = {}, {}
  for _, row in ipairs(data.list) do
    if row.idx == leader then fresh[row.idx] = 0 end
    local ok, value = pcall(ac.getGapBetweenCars, row.idx, leader)
    if ok and type(value) == 'number' and value == value and math.abs(value) < 10000 then
      if row.idx == leader then fresh[row.idx] = 0 else fresh[row.idx] = math.abs(value) end
    end
    if row.idx == focus then rel[row.idx] = 0
    else
      local okF, valueF = pcall(ac.getGapBetweenCars, row.idx, focus)
      if okF and type(valueF) == 'number' and valueF == valueF and math.abs(valueF) < 10000 then
        rel[row.idx] = valueF
      end
    end
  end
  M.gaps, M.focused = fresh, rel
end
-- Signed seconds to the focused car (negative = ahead), or nil without data.
function M.gapToFocused(index)
  local value = M.focused[index]
  if type(value) == 'number' and value == value and math.abs(value) < 10000 then return value end
end
-- Seconds behind the leader, or nil when the game has no data.
function M.gapToLeader(index)
  local value = M.gaps[index]
  if type(value) == 'number' and value >= 0 and value < 10000 then return value end
end
function M.text(index)
  if index == M.leader then return 'LEADER' end
  local value = M.gapToLeader(index)
  if not value then return nil end
  if value < 90 then return string.format('LÍDER +%.2f', value) end
  return string.format('LÍDER +%.1f', value)
end
function M.on_session_start() M.gaps, M.focused, M.leader, M.focus, M.time, M.stamp = {}, {}, nil, nil, 0, nil end
return M
