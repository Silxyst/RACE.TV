-- Real Penalty integration through lobby chat (ac.onChatMessage).
-- RP announces warnings/penalties/safety car as "RP: ..." messages. We parse
-- them read-only (never consume chat) into tower badges, alerts and flag state.
-- Everything is optional: without RP messages the module stays silent.
local M = { penalties = {}, flag = nil, time = 0, active = false }
local drivers = require('core.drivers')

local function notify(title, detail, color, sound)
  local ok, alert = pcall(require, 'widgets.alert')
  if ok and alert and alert.notify then
    local okCall = pcall(alert.notify, title, detail, color, sound)
    if not okCall then pcall(alert.notify, title, detail, color) end
  end
end

local function findDriver(msg)
  local sim = ac.getSim()
  if not sim then return nil end
  local best, bestLen = nil, 3
  for i = 0, (sim.carsCount or 0) - 1 do
    local ok, name = pcall(ac.getDriverName, i)
    if ok and name and #tostring(name) >= 3 then
      name = tostring(name):lower()
      if #name > bestLen and msg:find(name, 1, true) then best, bestLen = i, #name end
    end
  end
  return best
end

local function numberNear(msg, words)
  for _, word in ipairs(words) do
    local at = msg:find(word, 1, true)
    if at then
      local n = msg:match('(%d+)', at)
      if n then return tonumber(n) end
    end
  end
  return msg:match('(%d+)%s*s') and tonumber(msg:match('(%d+)%s*s'))
end

local function classify(msg)
  if msg:find('disqualif', 1, true) then return 'DSQ', 'DQ', nil end
  if msg:find('stop', 1, true) or msg:find('sg%d') or msg:find('[^%w]sg[^%w]') then
    local n = numberNear(msg, { 'go', 'stop', 'sg' })
    return 'SG', n and ('SG' .. math.min(n, 99)) or 'SG', n
  end
  if (msg:find('drive', 1, true) and msg:find('through', 1, true))
    or msg:find('drivethrough', 1, true) or msg:find('[^%w]dt[^%w]') then
    return 'DT', 'DT', nil
  end
  if msg:find('time penalty', 1, true) or msg:find('time-penalty', 1, true)
    or (msg:find('penalty', 1, true) and msg:find('sec', 1, true)) then
    local n = numberNear(msg, { 'penalty', 'sec', '+' })
    return 'TIME', n and ('+' .. math.min(n, 999)) or '+5', n
  end
  if msg:find('warn', 1, true) or msg:find('cut', 1, true) then
    local n, total = msg:match('(%d+)%s*/%s*(%d+)')
    return 'WARN', (n and ('W' .. math.min(tonumber(n), 99)) or 'WARN'), n and tonumber(n)
  end
end

local FLAG_WORDS = {
  { { 'virtual safety car', 'virtual-safety-car' }, 'VSC', 'yellow' },
  { { 'full course yellow', 'full-course-yellow' }, 'FCY', 'yellow' },
  { { 'safety car deployed', 'safety car in', 'safety-car', ' sc ' }, 'SAFETY CAR', 'yellow' },
}
local function checkFlag(msg)
  for _, entry in ipairs(FLAG_WORDS) do
    for _, word in ipairs(entry[1]) do
      if msg:find(word, 1, true) then return entry[2], entry[3] end
    end
  end
  if msg:find('green flag', 1, true) or msg:find('track clear', 1, true)
    or msg:find('safety car out', 1, true) or msg:find('fcY over', 1, true)
    or msg:find('fcy over', 1, true) then return 'GREEN', 'green' end
end

local function penaltyColor(kind)
  local draw = require('core.draw')
  if kind == 'WARN' then return draw.YELLOW end
  return draw.RED
end

local function onMessage(message, sender)
  if type(message) ~= 'string' then return end
  local msg = message:lower()
  if not (msg:find('rp:', 1, true) or msg:find('real penalty', 1, true)) then return end
  M.active = true
  local flagText, flagStyle = checkFlag(msg)
  if flagText then
    if flagText == 'GREEN' then
      M.flag = nil
      notify('GREEN FLAG', 'PISTA LIVRE', require('core.draw').GREEN)
    else
      M.flag = { text = flagText, style = flagStyle, untilTime = M.time + 180 }
      notify(flagText, 'REDUZA · SEM ULTRAPASSAR', require('core.draw').YELLOW)
    end
    return
  end
  local kind, label = classify(msg)
  if not kind then return end
  local idx = findDriver(msg)
  local detail = message:gsub('^%s*[Rr][Pp]:?%s*', ''):sub(1, 60)
  if idx == nil then
    notify(kind == 'WARN' and 'RP AVISO' or 'RP PENALIDADE', detail, penaltyColor(kind))
    return
  end
  if not drivers.valid(idx) then return end
  M.penalties[idx] = { kind = kind, label = label, key = drivers.key(idx),
    untilTime = (kind == 'WARN' or kind == 'DSQ') and nil or (M.time + 600), seenLane = false }
  notify(kind == 'WARN' and 'RP AVISO' or 'RP PENALIDADE',
    (drivers.name(idx) ~= '' and drivers.name(idx) .. ' · ' or '') .. label, penaltyColor(kind),
    kind == 'WARN' and nil or 'fastest.wav')
end

function M.penalty(idx)
  local entry = M.penalties[idx]
  if not entry then return nil end
  if not drivers.valid(idx, entry.key) then M.penalties[idx] = nil return nil end
  if entry.untilTime and M.time > entry.untilTime then M.penalties[idx] = nil return nil end
  return entry
end

function M.update(dt)
  M.time = M.time + math.max(0, dt or 0)
  local dirty = false
  for idx, entry in pairs(M.penalties) do
    if not drivers.valid(idx, entry.key) then M.penalties[idx] = nil dirty = true
    elseif entry.untilTime and M.time > entry.untilTime then M.penalties[idx] = nil dirty = true
    elseif (entry.kind == 'DT' or entry.kind == 'SG') then
      -- Cumprido ao atravessar o pitlane (drive-through) ou parar no box.
      local car = ac.getCar(idx)
      if car and car.isConnected then
        if car.isInPitlane or car.isInPit then entry.seenLane = true
        elseif entry.seenLane then M.penalties[idx] = nil dirty = true end
      end
    end
  end
  if M.flag and M.time > (M.flag.untilTime or 0) then M.flag = nil end
end

function M.init()
  pcall(function()
    if ac.onChatMessage then ac.onChatMessage(function(message, sender) onMessage(message, sender) end) end
  end)
end

function M.on_session_start()
  M.penalties, M.flag, M.time = {}, nil, 0
end
return M
