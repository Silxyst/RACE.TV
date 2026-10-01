-- Keep finish snapshots independent from mutable/reused ac.StateCar indices.
local M = { rows = {}, available = false, final = false }
local data, drivers = require('core.data'), require('core.drivers')
local observed = {}
local function snapshot(row)
  local number, team = require('core.branding').driver(row.idx)
  return { idx = row.idx, key = drivers.key(row.idx), name = drivers.name(row.idx),
    number = number, team = team,
    pos = row.rank or row.pos, best = row.car.bestLapTimeMs, laps = row.car.lapCount,
    terminal = row.car.isRaceFinished or row.car.isRetired,
    status = row.car.isRetired and 'DNF' or (row.car.isRaceFinished and 'FINISHED' or 'RUNNING') }
end
function M.update()
  local sim = ac.getSim()
  if not sim or data.quali(sim) then M.available, M.final = false, false return end
  local ok, finished = pcall(function() return sim.isSessionFinished end)
  finished = ok and finished == true
  local leader = data.list[1]
  if finished or (leader and leader.car.isRaceFinished)
    or (ac.FlagType.Finished and sim.raceFlagType == ac.FlagType.Finished) then M.available = true end
  for _, row in ipairs(data.list) do
    local old = observed[row.idx]
    if not old or not old.terminal then observed[row.idx] = snapshot(row) end
  end
  local rows, allFinished = {}, #data.list > 0
  for _, value in pairs(observed) do
    if not value.terminal then
      local active = data.byIndex[value.idx]
      if not active or not drivers.valid(value.idx, value.key) then value.status = 'DISCONNECTED' end
      allFinished = false
    end
    rows[#rows + 1] = value
  end
  table.sort(rows, function(a, b)
    if a.pos ~= b.pos then return a.pos < b.pos end
    return a.idx < b.idx
  end)
  -- Guarantee a unique 1..N display sequence even if snapshots were taken
  -- while the game reported duplicated race positions.
  for i, value in ipairs(rows) do value.pos = i end
  M.rows, M.final = rows, finished or allFinished
end
function M.on_session_start() observed = {} M.rows = {} M.available, M.final = false, false end
return M
