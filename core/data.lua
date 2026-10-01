-- Shared, deterministic standings and gap handling for tower/battle/grid/director.
local M = { list = {}, byIndex = {}, time = 0 }
local timing = require('core.timing')

function M.quali(sim)
  local session = sim and ac.getSession(sim.currentSessionIndex)
  return session and session.type ~= ac.SessionType.Race
end

function M.progress(car) return (car.lapCount or 0) + (car.splinePosition or 0) end

function M.update(dt)
  M.time = M.time + math.max(0, dt or 0)
  local sim = ac.getSim()
  local list, byIndex = {}, {}
  if sim then
    for i = 0, sim.carsCount - 1 do
      local car = ac.getCar(i)
      if car and car.isConnected and car.isActive and not car.isHidingLabels then
        local row = { idx = i, car = car, pos = car.racePosition }
        list[#list + 1], byIndex[i] = row, row
      end
    end
    local quali = M.quali(sim)
    table.sort(list, function(a, b)
      if quali then
        local ta, tb = a.car.bestLapTimeMs, b.car.bestLapTimeMs
        if ta > 0 and tb <= 0 then return true end
        if tb > 0 and ta <= 0 then return false end
        if ta > 0 and tb > 0 and ta ~= tb then return ta < tb end
      else
        local pa, pb = a.pos, b.pos
        if pa <= 0 then pa = math.huge end
        if pb <= 0 then pb = math.huge end
        if pa ~= pb then return pa < pb end
      end
      return a.idx < b.idx
    end)
    for rank, row in ipairs(list) do
      row.rank = rank
      -- AC can report duplicated/skipped racePosition values (ex: P2 twice,
      -- missing P13 at the finish). Display must always be a unique 1..N
      -- sequence following the sorted order; raw value kept for debugging.
      row.rawPos = row.pos
      row.pos = rank
    end
  end
  M.list, M.byIndex = list, byIndex
  if sim then timing.update(sim, list) end
end

-- Crossing timestamps take priority; estimate only while references accumulate.
function M.gap(front, back)
  if not front or not back or front.idx == back.idx then return nil end
  local diff = M.progress(front.car) - M.progress(back.car)
  if diff <= 0 or diff >= 1 then return nil end
  local measured = timing.gap(front, back)
  if measured then return measured, 'PASSAGEM' end
  if back.car.speedKmh < 5 then return nil end
  local sim = ac.getSim()
  if not sim or sim.trackLengthM <= 0 then return nil end
  return diff * sim.trackLengthM / math.max(18, back.car.speedKmh / 3.6), 'ESTIMADO'
end

function M.gapText(front, back)
  if not front or not back then return '---' end
  local laps = math.floor(M.progress(front.car) - M.progress(back.car))
  if laps >= 1 then return '+' .. laps .. ' LAP' end
  local seconds = M.gap(front, back)
  if not seconds then return '---' end
  return string.format('+%.2f', seconds)
end

function M.battle(excludeIndex)
  local best, pair = 1.5, nil
  for i = 2, #M.list do
    local a, b = M.list[i - 1], M.list[i]
    if a.idx ~= excludeIndex and b.idx ~= excludeIndex
      and not a.car.isInPitlane and not b.car.isInPitlane
      and not a.car.isRaceFinished and not b.car.isRaceFinished then
      local gap = M.gap(a, b)
      if gap and gap < best then best, pair = gap, { a, b } end
    end
  end
  return pair
end

function M.on_session_start() M.list = {} M.byIndex = {} M.time = 0 timing.on_session_start() end
return M
