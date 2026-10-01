-- Sizes follow content (scale/rows); positions follow a 1080p preset.
-- Windows closed or redirected by the user/CSP are left alone.
local M = {}
local handles = {}
local requested = {}
local resizing = {}
local lastSig = ''
local placePending = false

local PRESETS = {
  ['TV Tower'] = { 24, 130 },
  ['TV Telemetry'] = { 720, 24 },
  ['TV Onboard Top'] = { 720, 104 },
  ['TV Alert'] = { 730, 165 },
  ['TV Battle'] = { 630, 890 },
  ['TV Onboard Bar'] = { 24, 890 },
  ['TV Timing'] = { 1586, 130 },
  ['TV Inputs'] = { 1586, 310 },
  ['TV Spotter'] = { 1696, 740 },
  ['TV Map'] = { 1660, 480 },
  ['TV Lineup'] = { 615, 250 },
  ['TV Narrator'] = { 800, 330 },
  ['TV Results'] = { 615, 250 },
  ['TV Delta'] = { 720, 890 },
  ['TV Relative'] = { 1586, 500 },
  ['TV Fuel'] = { 1586, 640 },
  ['TV Session'] = { 720, 220 },
  ['TV Flags'] = { 720, 350 },
}

function M.window(title)
  local win = handles[title]
  if win and win:valid() then return win end
  handles[title] = nil
  requested[title] = nil
  for _, app in ipairs(ac.getAppWindows() or {}) do
    if app.title == title then
      win = ac.accessAppWindow(app.name)
      if win then handles[title] = win return win end
    end
  end
end

function M.fit(title, w, h)
  local win = M.window(title)
  if not win then return false end
  w, h = math.max(40, math.ceil(w)), math.max(20, math.ceil(h))
  local previous = requested[title]
  -- Native reported sizes can change between AC/OBS passes or settle later.
  -- Send each logical request once, independently of those size reports.
  if previous and previous.win == win and previous.w == w and previous.h == h then return true end
  resizing[title] = true
  local ok, err = pcall(function() win:resize(vec2(w, h)) end)
  resizing[title] = nil
  if not ok then error(err, 0) end
  requested[title] = { win = win, w = w, h = h }
  if require('core.config').get().autoLayout then placePending = true
  else
    local screen, pos = require('core.screen').size(), win:position()
    local x, y = math.max(0, math.min(pos.x, screen.x-w)), math.max(0, math.min(pos.y, screen.y-h))
    if math.abs(pos.x-x) > 0.5 or math.abs(pos.y-y) > 0.5 then win:move(vec2(x, y)) end
  end
  return true
end

function M.size(title)
  local win = M.window(title)
  if not win then return vec2(0, 0) end
  local value = requested[title]
  return value and vec2(value.w, value.h) or win:size()
end

-- Actual native size, which can be smaller than requested when CSP clamps it.
function M.actual(title)
  local win = M.window(title)
  if not win then return nil end
  local ok, size = pcall(function() return win:size() end)
  if ok and size and size.x > 0 and size.y > 0 then return size end
end

local function place(title)
  local win = M.window(title)
  if not win then return end
  local p = PRESETS[title]
  if not p then return end
  local screen = require('core.screen').size()
  local desiredSize = requested[title]
  local size = desiredSize and vec2(desiredSize.w, desiredSize.h) or win:size()
  local target = vec2(
    math.max(0, math.min(p[1] / 1920 * screen.x, screen.x - size.x)),
    math.max(0, math.min(p[2] / 1080 * screen.y, screen.y - size.y)))
  local pos = win:position()
  if math.abs(pos.x - target.x) > 0.5 or math.abs(pos.y - target.y) > 0.5 then
    win:move(target)
  end
end

function M.apply()
  for title in pairs(PRESETS) do place(title) end
end

function M.update()
  local cfg = require('core.config').get()
  local screen = require('core.screen').size()
  local sig = tostring(cfg.autoLayout) .. ':' .. screen.x .. 'x' .. screen.y .. ':' .. cfg.scale
  if sig ~= lastSig or placePending then
    lastSig = sig
    placePending = false
    if cfg.autoLayout then M.apply() end
  end
end

-- Called once in update. Drawing callbacks never change native window sizes.
function M.prepare(windows, cfg)
  for _, entry in ipairs(windows) do
    local w, h = entry.width, entry.height
    if entry.module.size then w, h = entry.module.size(cfg) end
    M.fit(entry.title, w * cfg.scale, h * cfg.scale)
  end
end

function M.on_session_start() lastSig = '' end
function M.isResizing(title) return resizing[title] == true end
function M.reset() handles = {} requested = {} resizing = {} lastSig = '' placePending = false end
return M
