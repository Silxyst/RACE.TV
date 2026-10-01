-- Tyre age is observed since app/session start. Virtual KM detects same-compound swaps.
local M = {}
local info = {}
local function compound(idx)
  local name = ac.getTyresName(idx)
  return name and name ~= '' and name or nil
end
function M.update()
  local sim = ac.getSim()
  if not sim then return end
  for i = 0, sim.carsCount - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected then
      local comp, lap = compound(i), car.lapCount
      local km = car.physicsAvailable and car.wheels[0].tyreVirtualKM or nil
      local cur = info[i]
      if not cur or cur.comp ~= comp or lap < cur.lastLap
        or (km and cur.km and km + 0.1 < cur.km) then
        cur = { comp = comp, sinceLap = lap }
        info[i] = cur
      end
      cur.lastLap, cur.km = lap, km
    else info[i] = nil end
  end
end
function M.get(idx)
  local cur = info[idx]
  if not cur or not cur.comp then return '?', nil, nil end
  local c, letter = cur.comp:upper(), '?'
  if c:find('INTER') or c == 'I' then letter = 'I'
  elseif c:find('WET') or c:find('RAIN') or c == 'W' then letter = 'W'
  elseif c:find('SOFT') or c == 'S' or c == 'SS' then letter = 'S'
  elseif c:find('MEDIUM') or c == 'M' then letter = 'M'
  elseif c:find('HARD') or c == 'H' then letter = 'H'
  else letter = c end
  return letter, math.max(0, cur.lastLap - cur.sinceLap), cur.comp
end
function M.on_session_start() info = {} end
function M.init() end
return M
