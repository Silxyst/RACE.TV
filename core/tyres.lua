-- ========================================
-- RACE TV // core/tyres.lua
-- Tracker de composto + idade em voltas (ACTV "H (3 L)").
-- Reseta a idade quando o composto muda.
-- ========================================
local M = {}

local info = {} -- idx -> {comp, sinceLap}
local lastKey = nil

local function compOf(car)
  local c = car.tyreCompound or car.compound or car.tyreShortName
  if c == nil then return nil end
  return tostring(c)
end

function M.update()
  local sim = ac.getSim()
  if not sim then return end
  local key = (ac.getTrackID and ac.getTrackID() or '') .. '#' .. tostring(sim.currentSessionIndex or 0)
  if key ~= lastKey then info = {} lastKey = key end
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    if car then
      local comp = compOf(car)
      local lap = car.lapCount or 0
      local cur = info[i]
      if not cur then
        info[i] = { comp = comp, sinceLap = lap }
      elseif comp ~= cur.comp then
        info[i] = { comp = comp, sinceLap = lap }
      end
    end
  end
end

-- retorna letra curta + idade; ex: 'M', 5
function M.get(idx)
  local sim = ac.getSim()
  local car = sim and ac.getCar(idx) or nil
  local cur = info[idx]
  local comp = (cur and cur.comp) or (car and compOf(car))
  local letter = '·'
  if comp then
    local c = string.upper(comp)
    if c:find('SOFT') or c == 'S' then letter = 'S'
    elseif c:find('MEDIUM') or c == 'M' then letter = 'M'
    elseif c:find('HARD') or c == 'H' then letter = 'H'
    elseif c:find('WET') or c:find('RAIN') then letter = 'W'
    elseif c:find('INTER') then letter = 'I'
    else letter = c:sub(1, 1) end
  end
  local age = 0
  if car and cur then age = math.max(0, (car.lapCount or 0) - (cur.sinceLap or 0)) end
  return letter, age, comp
end

function M.on_session_start() info = {} lastKey = nil end
function M.init() end

return M
