-- Manual broadcast controls. Driver identities prevent stale index reuse.
local M = {}
local data, drivers = require('core.data'), require('core.drivers')
local favoriteStore = ac.storage('ETV_favorites', '')
local favorites, slots, histories = {}, {}, {}
local buttons, serial, dispatched = {}, 0, {}
local comparisons = { samples = {}, time = 0 }
for key in tostring(favoriteStore:get() or ''):gmatch('[^\n]+') do favorites[key] = true end
M.hotkeys = {
  { 'TV_FOCUS_LEADER', 'Focar líder', function() M.leader() end },
  { 'TV_FOCUS_PREVIOUS', 'Piloto anterior', function() M.adjacent(-1) end },
  { 'TV_FOCUS_NEXT', 'Próximo piloto', function() M.adjacent(1) end },
  { 'TV_FAVORITE_TOGGLE', 'Favoritar piloto atual', function() M.toggleFavorite(ac.getSim().focusedCar) end },
  { 'TV_FAVORITE_NEXT', 'Próximo favorito', function() M.nextFavorite() end },
  { 'TV_COMPARE_A', 'Atual para comparação A', function() M.choose('A', ac.getSim().focusedCar) end },
  { 'TV_COMPARE_B', 'Atual para comparação B', function() M.choose('B', ac.getSim().focusedCar) end },
  { 'TV_LAYOUT_NEXT', 'Próximo layout salvo', function() require('core.layouts').cycle() end },
}
function M.init()
  for _, entry in ipairs(M.hotkeys) do buttons[entry[1]] = ac.ControlButton(entry[1]) end
end
function M.command(id, callback)
  if dispatched[id] == serial then return false end
  dispatched[id] = serial
  callback()
  return true
end
function M.focus(index, key)
  if not drivers.valid(index, key) then return false end
  ac.focusCar(index)
  return true
end
function M.leader() if data.list[1] then M.focus(data.list[1].idx) end end
function M.adjacent(direction)
  if #data.list == 0 then return end
  local current = data.byIndex[ac.getSim().focusedCar]
  local rank = current and current.rank or 1
  local nextRow = data.list[((rank - 1 + direction) % #data.list) + 1]
  M.focus(nextRow.idx)
end
function M.isFavorite(index) return drivers.valid(index) and favorites[drivers.key(index)] == true end
function M.toggleFavorite(index)
  if not drivers.valid(index) then return end
  local key = drivers.key(index)
  favorites[key] = not favorites[key] or nil
  local list = {}
  for identity in pairs(favorites) do list[#list + 1] = identity end
  table.sort(list)
  favoriteStore:set(table.concat(list, '\n'))
end
function M.favoriteRows()
  local list = {}
  for _, row in ipairs(data.list) do if M.isFavorite(row.idx) then list[#list + 1] = row end end
  return list
end
function M.nextFavorite()
  local list = M.favoriteRows()
  if #list == 0 then return end
  for i, row in ipairs(list) do
    if row.idx == ac.getSim().focusedCar then M.focus(list[i % #list + 1].idx) return end
  end
  M.focus(list[1].idx)
end
function M.choose(slot, index)
  if (slot ~= 'A' and slot ~= 'B') or not drivers.valid(index) then return false end
  local other = slots[slot == 'A' and 'B' or 'A']
  if other and other.idx == index and drivers.valid(other.idx, other.key) then return false end
  slots[slot] = { idx = index, key = drivers.key(index) }
  return true
end
function M.slot(slot)
  local value = slots[slot]
  if value and drivers.valid(value.idx, value.key) and data.byIndex[value.idx] then return data.byIndex[value.idx] end
  slots[slot] = nil
end
function M.pair()
  local a, b = M.slot('A'), M.slot('B')
  if a and b and a.idx ~= b.idx then return { a, b } end
end
function M.clearComparison() slots = {} comparisons = { samples = {}, time = 0 } end
function M.laps(index) return histories[index] and histories[index].laps or {} end
function M.average(index)
  local list, total = M.laps(index), 0
  local count = math.min(3, #list)
  if count == 0 then return nil end
  for i = #list - count + 1, #list do total = total + list[i] end
  return total / count
end
function M.trackPair(dt, a, b)
  if not a or not b then comparisons = { samples = {}, time = 0 } return end
  local key = drivers.key(a.idx) .. '|' .. drivers.key(b.idx)
  if comparisons.key ~= key then comparisons = { key = key, samples = {}, time = 1 } end
  comparisons.time = comparisons.time + dt
  if comparisons.time >= 1 then
    comparisons.time = 0
    local front, back = a, b
    if front.rank > back.rank then front, back = back, front end
    local gap = data.gap(front, back)
    if gap then
      local samples = comparisons.samples
      samples[#samples + 1] = gap
      if #samples > 11 then table.remove(samples, 1) end
    else comparisons.samples = {} end
  end
end
function M.trend()
  local samples = comparisons.samples
  if #samples >= 3 then return samples[1] - samples[#samples] end
end
function M.update(dt)
  serial, dispatched = serial + 1, {}
  local seen = {}
  for _, row in ipairs(data.list) do
    local index, key, car = row.idx, drivers.key(row.idx), row.car
    seen[index] = true
    local state = histories[index]
    if not state or state.key ~= key or car.lapCount < state.count then
      state = { key = key, count = car.lapCount, laps = {} }
      histories[index] = state
    end
    if car.lapCount > state.count then
      if car.lapCount == state.count + 1 and car.previousLapTimeMs > 0 then
        state.laps[#state.laps + 1] = car.previousLapTimeMs
        if #state.laps > 5 then table.remove(state.laps, 1) end
      end
      state.count = car.lapCount
    end
  end
  for index in pairs(histories) do if not seen[index] then histories[index] = nil end end
  M.slot('A') M.slot('B')
  for _, entry in ipairs(M.hotkeys) do
    if buttons[entry[1]] and buttons[entry[1]]:pressed() then M.command(entry[1], entry[3]) end
  end
end
function M.on_session_start()
  slots, histories, dispatched = {}, {}, {}
  comparisons = { samples = {}, time = 0 }
end
return M
