-- Compact broadcast environment strip: flag, grip, temps and local time.
-- Every field is optional; missing game data renders as em dash, never errors.
local M = {}
local function field(fn)
  local ok, value = pcall(fn)
  if ok then return value end
end
function M.flag()
  local okRp, rp = pcall(require, 'core.rp')
  if okRp and rp and rp.flag and rp.flag.text then return rp.flag.text, rp.flag.style end
  local sim = ac.getSim()
  if not sim then return 'SESSION', nil end
  local finished = field(function() return sim.isSessionFinished end)
  if finished then return 'CHEQUERED', 'white' end
  local flag = field(function() return sim.raceFlagType end)
  if flag == 13 then return 'CHEQUERED', 'white' end
  if flag == 2 then return 'YELLOW', 'yellow' end
  if flag == 1 then return 'GREEN', 'green' end
  local session = ac.getSession and field(function() return ac.getSession(sim.currentSessionIndex or 0) end)
  local laps = session and session.laps or 0
  if laps and laps > 0 then
    local leader = field(function() return sim.leaderLapCount end) or 0
    return string.format('LAP %d/%d', math.min(leader + 1, laps), laps), nil
  end
  local left = field(function() return sim.sessionTimeLeft end)
  if type(left) == 'number' then
    if left <= 0 then return 'OVERTIME', 'yellow' end
    local total = math.ceil(left / 1000)
    return string.format('%02d:%02d', math.floor(total / 60), total % 60), nil
  end
  return 'SESSION', nil
end
function M.strip()
  local sim = ac.getSim()
  if not sim then return nil end
  local function fmt(value, suffix)
    if type(value) ~= 'number' or value ~= value then return '—' end
    return string.format('%.0f%s', value, suffix or '')
  end
  local grip = field(function() return sim.roadGrip end)
  local track = field(function() return sim.roadTemperature end)
  local air = field(function() return sim.ambientTemperature end)
  local hours = field(function() return sim.timeHours end)
  local minutes = field(function() return sim.timeMinutes end)
  local clock = nil
  if type(hours) == 'number' and type(minutes) == 'number' then
    clock = string.format('%02d:%02d', math.floor(hours) % 24, math.floor(minutes) % 60)
  end
  local gripTxt = type(grip) == 'number' and fmt(grip * 100, '%') or '—'
  return string.format('GRIP %s · PISTA %s · AR %s%s',
    gripTxt,
    type(track) == 'number' and fmt(track, '°') or '—',
    type(air) == 'number' and fmt(air, '°') or '—',
    clock and (' · ' .. clock) or '')
end
return M
