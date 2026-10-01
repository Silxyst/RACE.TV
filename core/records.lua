-- All-time lap records per track/layout, observed from live timing.
local M = { ms = nil, name = '', track = '' }
local function trackKey()
  local track = ac.getTrackID and ac.getTrackID() or ''
  local layout = ac.getTrackLayout and ac.getTrackLayout() or ''
  local okT, tid = pcall(function() return ac.getTrackID() end)
  if okT and tid then track = tid end
  local okL, lay = pcall(function() return ac.getTrackLayout() end)
  if okL and lay then layout = lay end
  return (tostring(track) .. '/' .. tostring(layout)):gsub('%W', '_')
end
local function store()
  return ac.storage('ETV_rec_' .. M.track, '')
end
local function load()
  M.ms, M.name = nil, ''
  local raw = tostring(store():get() or '')
  local ms, name = raw:match('^(%d+)\t(.*)$')
  ms = tonumber(ms)
  if ms and ms > 0 and ms <= 3600000 then M.ms, M.name = ms, name or '' end
end
function M.update()
  if M.track == '' then
    M.track = trackKey()
    load()
  end
  local data = require('core.data')
  for _, row in ipairs(data.list) do
    local best = row.car.bestLapTimeMs
    if best and best > 0 and best <= 3600000 and (not M.ms or best < M.ms - 1) then
      local ok, nm = pcall(ac.getDriverName, row.idx)
      M.ms = best
      M.name = (ok and nm and #tostring(nm) > 0) and tostring(nm) or ''
      store():set(best .. '\t' .. M.name)
    end
  end
end
function M.text()
  if not M.ms then return nil end
  local draw = require('core.draw')
  return 'RECORDE ' .. draw.fullName(M.name ~= '' and M.name or 'PISTA', 20) .. '  ' .. draw.fmtLap(M.ms)
end
function M.on_session_start() M.track = '' load() end
return M
