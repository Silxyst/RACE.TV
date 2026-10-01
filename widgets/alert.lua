local M = {}
local config, draw, anim = require('core.config'), require('core.draw'), require('core.anim')
local current, timer, initialized = nil, 0, false
local queue, sounds, pb, pbNames = {}, {}, {}, {}
local lastBest, lastFlag
local function event(title, detail, color, sound)
  if #queue < 4 then queue[#queue + 1] = { title = title, detail = detail, color = color, sound = sound } end
end
function M.notify(title, detail, color, sound)
  event(title, detail, color or require('core.draw').YELLOW, sound)
end
local function play(file)
  local cfg = config.get()
  if not cfg.sound or not file then return end
  if not sounds[file] then
    local ok, audio = pcall(ac.AudioEvent.fromFile,
      { filename = 'apps/lua/Streamer Hud/assets/' .. file, use3D = false, loop = false }, false)
    if ok then sounds[file] = audio end
  end
  local audio = sounds[file]
  if audio then audio.volume = cfg.volume audio:stop() audio:start() end
end
function M.init() end
function M.on_open() end
function M.on_close() end
function M.on_session_start()
  queue, pb, pbNames = {}, {}, {}
  current, timer, lastBest, lastFlag, initialized = nil, 0, nil, nil, false
  for _, audio in pairs(sounds) do audio:stop() end
end
function M.on_release()
  for _, audio in pairs(sounds) do audio:dispose() end
  sounds = {}
end
function M.update(dt)
  local sim = ac.getSim()
  if not sim then return end
  local best, owner
  for _, row in ipairs(require('core.data').list) do
    local value = row.car.bestLapTimeMs
    if value > 0 and (not best or value < best) then best, owner = value, row.idx end
  end
  if initialized and best and (not lastBest or best < lastBest - 1) then
    event('FASTEST LAP', draw.fullName(ac.getDriverName(owner), 28) .. '  ' .. draw.fmtLap(best), draw.PURPLE, 'fastest.wav')
  end
  if best then lastBest = math.min(lastBest or best, best) end
  local focus, car = sim.focusedCar, ac.getCar(sim.focusedCar)
  if car and car.bestLapTimeMs > 0 then
    local name = ac.getDriverName(focus) or ''
    if pbNames[focus] ~= name then pb[focus] = nil pbNames[focus] = name end
    local value = car.bestLapTimeMs
    if pb[focus] and value < pb[focus] - 1 and (not lastBest or math.abs(value - lastBest) > 1) then
      event('PERSONAL BEST', draw.fullName(ac.getDriverName(focus), 28) .. '  ' .. draw.fmtLap(value), draw.GREEN, 'pb.wav')
    end
    pb[focus] = value
  end
  local caution = sim.raceFlagType == ac.FlagType.Caution
  if initialized and caution ~= lastFlag then
    -- Flags take priority over lap notifications, but those remain queued.
    if current then table.insert(queue, 1, current) end
    current = { title = caution and 'YELLOW FLAG' or 'GREEN FLAG',
      detail = caution and 'REDUZA A VELOCIDADE · SEM ULTRAPASSAR' or 'PISTA LIVRE',
      color = caution and draw.YELLOW or draw.GREEN, sound = 'green.wav' }
    timer = 0
    play(current.sound)
  end
  lastFlag, initialized = caution, true
  timer = timer + dt
  if current and timer >= 5.6 then current = nil end
  if not current and #queue > 0 then current = table.remove(queue, 1) timer = 0 play(current.sound) end
end
function M.main()
  if not current then return end
  local k = draw.fit(config.get().scale, 460, 80, 'TV Alert')
  local progress, alpha, slide = anim.popup(timer, 5, 0.3, 0.3)
  if alpha <= 0.001 then return end
  local W, y = 460 * k, slide * k
  ui.pushClipRect(vec2(0, 0), vec2(W, 56 * k), true)
  ui.pushClipRect(vec2(W * (1 - progress) / 2, y), vec2(W * (1 + progress) / 2, y + 56 * k), true)
  ui.drawRectFilled(vec2(0, y), vec2(W, y + 56 * k), draw.surface(0.92 * alpha), 8)
  local color = rgbm(current.color.r, current.color.g, current.color.b, alpha)
  ui.drawRectFilled(vec2(0, y + 4 * k), vec2(6 * k, y + 52 * k), color, 3)
  ui.drawRect(vec2(0.5, y + 0.5), vec2(W - 0.5, y + 56 * k - 0.5), rgbm(1, 1, 1, 0.09 * alpha))
  draw.textF(draw.FONT_HEAD, 16 * k, y + 4 * k, current.title, 17 * k, color, ui.Alignment.Start, W - 32 * k, 24 * k)
  draw.textF(draw.FONT_TXT, 16 * k, y + 28 * k, current.detail, 12 * k,
    rgbm(1, 1, 1, alpha), ui.Alignment.Start, W - 32 * k, 22 * k)
  ui.popClipRect()
  ui.popClipRect()
end
return M
