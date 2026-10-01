package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
audit = { errors = {}, logs = {}, texts = {}, draws = {}, windows = {},
  clip = 0, fonts = 0, mapCalls = 0, focusChanges = 0, audioStarts = 0, checkOverflow = true }
function vec2(x, y) return { x = x or 0, y = y or 0 } end
function vec3(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end
local function color(r, g, b, a)
  assert(a and a >= 0 and a <= 1, 'Invalid alpha: ' .. tostring(a))
  return { r = r, g = g, b = b, mult = a }
end
rgbm = setmetatable({ from0255 = function(r, g, b, a) return color(r / 255, g / 255, b / 255, a or 1) end },
  { __call = function(_, r, g, b, a) return color(r, g, b, a) end })
local stores = {}
ac = {
  CameraMode = { Cockpit = 0, Car = 1, Drivable = 2, Track = 3, Helicopter = 4, OnBoardFree = 5, Free = 6, Start = 9 },
  DrivableCamera = { Chase = 0, Chase2 = 1, Bonnet = 2, Bumper = 3, Dash = 4 },
  FolderID = { ACAppsLua = 1029, ContentCars = 1031, Root = 4 },
  SessionType = { Practice = 0, Qualify = 1, Race = 2 }, FlagType = { None = 0, Caution = 2, Finished = 13 },
}
sim = { carsCount = 0, focusedCar = 0, currentSessionIndex = 0, currentSessionTime = 60000, sessionTimeLeft = 600000,
  windowWidth = 1920, windowHeight = 1080, cameraMode = 3, driveableCameraMode = 0,
  raceFlagType = 0, trackLengthM = 5000, isOnlineRace = false, driverNamesShown = true,
  isSessionStarted = true, isSessionFinished = false, isPaused = false, isReplayActive = false,
  roadGrip = 0.98, roadTemperature = 32, ambientTemperature = 24, timeHours = 14, timeMinutes = 30,
  leaderLapCount = 3, raceFlagType = 0 }
-- Match the real error from the user's CSP log: state_sim has no uiScale member.
setmetatable(sim, { __index = function(_, field) error('state_sim has no member named ' .. field) end })
uiInfo = { uiScale = 1 }
session = { type = 2, laps = 10 }
cars, names, models, compounds = {}, {}, {}, {}
function ac.getSim() return sim end
function ac.getUI() return uiInfo end
function ac.getSession() return session end
function ac.getCar(i) return cars[i] end
function ac.getCarName(i) return models[i] or '' end
function ac.getCarID(i) return models[i] or '' end
function ac.getDriverName(i) return names[i] or '' end
function ac.getDriverNationCode(i) return 'BRA' end
function ac.getTyresName(i) return compounds[i] end
function ac.getTrackID() return 'test_track' end
function ac.getTrackLayout() return audit.layout or '' end
function ac.getSessionName() return 'Test Session' end
function ac.getDriverNumber(i) return 10 + (i or 0) end
function ac.getGapBetweenCars(a, b)
  if cars[a] == nil or cars[b] == nil then return nil end
  local pa = cars[a].lapCount + cars[a].splinePosition
  local pb = cars[b].lapCount + cars[b].splinePosition
  return (pa - pb) * 90
end
function ac.getFolder() return root:match('^(.*)/[^/]+$') end
function io.fileExists(path) return assetExists(path) end
function ac.debug(key, text) audit.errors[#audit.errors + 1] = tostring(key) .. ': ' .. tostring(text) end
function ac.log(text) audit.logs[#audit.logs + 1] = tostring(text) end
function ac.focusCar(i) audit.focusChanges = audit.focusChanges + 1 sim.focusedCar = i end
function ac.storage(key, default)
  if stores[key] == nil then stores[key] = default end
  return { get = function() return stores[key] end, set = function(_, value)
    audit.storeWrites = (audit.storeWrites or 0) + 1
    stores[key] = value
  end }
end
function audit.store(key, value) ac.storage(key, value):set(value) end
function ac.onChatMessage(fn) audit.chatCallback = fn end
function audit.chat(message, sender)
  if audit.chatCallback then audit.chatCallback(message, sender or -1, 0) end
end
function ac.onRelease(fn) audit.release = fn end
function ac.onSessionStart(fn) audit.restart = fn end
function ac.load() return 0 end
function ac.ControlButton(id)
  return { pressed = function()
    if audit.hotkey == id then audit.hotkey = nil return true end
    return false
  end, control = function() end }
end
ac.AudioEvent = { fromFile = function()
  return { start = function() audit.audioStarts = audit.audioStarts + 1 end, stop = function() end,
    dispose = function() end, volume = 1 }
end }
function ac.trackCoordinateToWorld(v)
  audit.mapCalls = audit.mapCalls + 1
  if audit.noMap then return nil end
  return vec3(math.cos(v.z * math.pi * 2) * 1000, 0, math.sin(v.z * math.pi * 2) * 750)
end
local function window(def)
  local win = { title = def.title, name = 'MOCK_' .. def.title,
    w = def.width, h = def.height, x = 0, y = 0, _visible = false, redirected = false }
  function win:valid() return audit.windows[self.title] == self end
  function win:visible() return self._visible end
  function win:setVisible(value)
    local changed = self._visible ~= value
    self._visible = value
    local callback = value and def.show or def.hide
    if changed and callback and callback ~= '' and script[callback] then script[callback](0) end
    return self
  end
  function win:size()
    local report = audit.sizeReportFactor or 1
    return vec2(self.w * report, self.h * report)
  end
  function win:position() return vec2(self.x, self.y) end
  function win:redirectLayer2() return self.redirected and 1 or 0, self._visible end
  function win:resize(v)
    self.resizeCalls = (self.resizeCalls or 0) + 1
    local function apply()
      self.w, self.h = v.x, v.y
      if self.title == 'TV Tower' and audit.towerMaxHeight then self.h = math.min(self.h, audit.towerMaxHeight) end
      if self._visible and def.show ~= '' then
        if audit.resizeEmitsHideShow and def.hide ~= '' then script[def.hide](0) end
        if audit.resizeEmitsShow or audit.resizeEmitsHideShow then script[def.show](0) end
      end
    end
    if audit.deferResize then self.pendingResize = apply else apply() end
  end
  function win:move(v) self.x, self.y = v.x, v.y end
  return win
end
for _, def in ipairs(windowDefinitions) do audit.windows[def.title] = window(def) end
function audit.settleSizes()
  for _, win in pairs(audit.windows) do
    if win.pendingResize then local apply = win.pendingResize win.pendingResize = nil apply() end
  end
end
function ac.getAppWindows()
  local result = {}
  for _, win in pairs(audit.windows) do result[#result + 1] = win end
  return result
end
function ac.accessAppWindow(name)
  for _, win in pairs(audit.windows) do if win.name == name then return win end end
end
ui = { Alignment = { Start = 0, End = 1, Center = 2 }, CornerFlags = { Left = 1, Right = 2 },
  ImageFit = { Fit = 2 },
  Icons = { Settings = 1, Close = 2 },
  ButtonFlags = { PressedOnClick = 4, NoNavFocus = 0x2000 }, MouseCursor = { Hand = 7 },
  WindowFlags = { NoInputs = 0xc0200, NoBackground = 0x80, NoScrollbar = 8, NoScrollWithMouse = 16, NoSavedSettings = 0x100 },
  StyleVar = { WindowPadding = 15, ItemSpacing = 19 },
  StyleColor = { Button = 1, ButtonHovered = 2, ButtonActive = 3 } }
local cursor = vec2(0, 0)
local function finite(x) return type(x) == 'number' and x == x and math.abs(x) < math.huge end
local function rect(a, b)
  assert(finite(a.x) and finite(a.y) and finite(b.x) and finite(b.y), 'Non-finite geometry')
  assert(a.x <= b.x + 0.01 and a.y <= b.y + 0.01, 'Inverted rectangle')
  if audit.current and audit.clip == 0 and audit.checkOverflow then
    assert(b.x <= audit.current.w + 1 and b.y <= audit.current.h + 1,
      'Widget overflows window: ' .. audit.current.title .. ' (' .. b.x .. ',' .. b.y .. ') vs (' .. audit.current.w .. ',' .. audit.current.h .. ')')
  end
end
function ui.pushClipRect(a, b) rect(a, b) audit.clip = audit.clip + 1 end
function ui.popClipRect() audit.clip = audit.clip - 1 assert(audit.clip >= 0, 'Clip underflow') end
function ui.pushDWriteFont(font) assert(font) audit.fonts = audit.fonts + 1 end
function ui.popDWriteFont() audit.fonts = audit.fonts - 1 assert(audit.fonts >= 0, 'Font underflow') end
function ui.measureDWriteText(text, size) return vec2(#text * size * 0.53, size * 0.85) end
function ui.setCursor(pos) cursor = pos end
function ui.dwriteDrawTextClipped(text, size, a, b, align, valign, wrap, col)
  rect(a, b)
  audit.texts[#audit.texts + 1] = { text = text, x = a.x, y = a.y, width = b.x - a.x, size = size, color = col, container = audit.current and audit.current.title }
end
function ui.dwriteText(text, size, col)
  audit.texts[#audit.texts + 1] = { text = text, x = cursor.x, y = cursor.y, size = size, color = col, container = audit.current and audit.current.title }
end
function ui.drawRectFilled(a, b, col)
  rect(a, b)
  audit.draws[#audit.draws + 1] = { a = a, b = b, color = col, container = audit.current and audit.current.title }
end
function ui.drawRectFilledMultiColor(a, b, ...) rect(a, b) end
function ui.drawRect(a, b, ...) rect(a, b) end
function ui.drawLine(a, b, ...) assert(finite(a.x) and finite(b.x)) end
function ui.drawCircle(...) end
function ui.drawCircleFilled(...) end
function ui.drawImage(path, a, b, ...) rect(a, b) audit.images = audit.images or {} audit.images[#audit.images+1] = path end
function ui.isImageReady() return true end
function ui.beginOutline() end
function ui.endOutline(...) end
function ui.onDriverNameTag(_, _, cb, opts) audit.tagCallback, audit.tagSize = cb, opts.tagSize end
function ui.windowSize() return vec2(audit.current.w, audit.current.h) end
function ui.windowPos() return audit.current:position() end
function ui.checkbox(label)
  if audit.checkboxClick == label then audit.checkboxClick = nil return true end
  return false
end
function ui.radioButton(label)
  if audit.radioClick == label then audit.radioClick = nil return true end
  return false
end
function ui.inputText(label, text)
  if audit.inputs and audit.inputs[label] ~= nil then
    local value = audit.inputs[label] audit.inputs[label] = nil return value
  end
  return text
end
function ui.slider(label, value)
  if audit.sliders and audit.sliders[label] ~= nil then
    local nextValue = audit.sliders[label] audit.sliders[label] = nil return nextValue
  end
  return value
end
function ui.button(label)
  if audit.buttonClick == label then audit.buttonClick = nil return true end
  return false
end
function ui.pushStyleColor(...) end
function ui.popStyleColor(...) end
function ui.colorButton(label, color)
  if audit.colorButtonClick == label then audit.colorButtonClick = nil return true end
  return false
end
function ui.text(text) audit.texts[#audit.texts + 1] = { text = text, container = audit.current and audit.current.title } end
function ui.textColored(text, color) audit.texts[#audit.texts + 1] = { text = text, color = color } end
function ui.textWrapped(...) end
function ui.separator() end
function ui.sameLine() end
function ui.dummy(size) assert(size.x >= 0 and size.y >= 0) end
function ui.invisibleButton(label, size, flags)
  rect(cursor, vec2(cursor.x + size.x, cursor.y + size.y))
  audit.buttons = audit.buttons or {}
  audit.buttons[#audit.buttons + 1] = { id = label, x = cursor.x, y = cursor.y, w = size.x, h = size.y }
  audit.lastItem = label
  if audit.current._visible and audit.clickId == label then
    if not audit.repeatClick then audit.clickId = nil end
    return true
  end
  return false
end
function ui.itemHovered() return audit.hoverId == audit.lastItem and audit.current._visible end
function ui.setMouseCursor(cursorId) audit.mouseCursor = cursorId end
function ui.setTooltip(text) audit.tooltip = text end
script = {}

-- Opens a window like the CSP app bar would, then renders its content.
-- First pass lets winsize auto-resize; second pass checks for overflow.
local function drawPass(def)
  audit.current = audit.windows[def.title]
  audit.texts, audit.draws, audit.buttons = {}, {}, {}
  assert(type(script[def.main]) == 'function', 'Missing CSP callback: script.' .. def.main)
  local beforeResize = audit.current.resizeCalls
  script[def.main](1 / 60)
  assert(audit.current.resizeCalls == beforeResize, def.title .. ' resized inside its drawing callback')
  assert(audit.clip == 0 and audit.fonts == 0, 'Leaked UI stack: ' .. def.title)
  assert(#audit.errors == 0, table.concat(audit.errors, '\n'))
end
audit.paint = drawPass

function audit.render(def)
  local win = audit.windows[def.title]
  if not win._visible then
    win:setVisible(true) -- fires FUNCTION_ON_SHOW, like opening in the app bar
    assert(win:visible(), 'Window did not open: ' .. def.title)
  end
  audit.checkOverflow = false
  drawPass(def)
  audit.checkOverflow = true
  drawPass(def)
end

-- A window hidden from the main screen (e.g. OBS Apps Redirection) still
-- renders its content to the redirect layer. Visibility must not gate drawing.
function audit.renderRedirected(def)
  local win = audit.windows[def.title]
  win._visible = false
  win.redirected = true
  audit.checkOverflow = false
  drawPass(def)
  audit.checkOverflow = true
  drawPass(def)
  assert(#audit.draws + #audit.texts > 0, 'Redirected window drew nothing: ' .. def.title)
end

function audit.grid(count)
  cars, names, models, compounds = {}, {}, {}, {}
  sim.carsCount, sim.focusedCar = count, 0
  for i = 0, count - 1 do
    local car = {}
    for k, v in pairs(carDefaults) do car[k] = v end
    car.index, car.isConnected, car.isActive, car.physicsAvailable = i, true, true, true
    car.racePosition, car.lapCount, car.splinePosition = i + 1, 2, 0.8 - i * 0.001
    car.speedKmh, car.rpm, car.rpmLimiter = 180, 5000, 7500
    car.gas, car.brake, car.gear, car.steer, car.steerLock = 0.5, 0.1, 4, 10, 450
    car.bestLapTimeMs, car.previousLapTimeMs, car.lapTimeMs = 90000 + i * 100, 92000, 30000
    car.performanceMeter, car.currentSector = -0.1, 1
    car.currentSplits = { [0] = 30000, [1] = 0, [2] = 0 }
    car.bestSplits = { [0] = 30500, [1] = 31000, [2] = 32000 }
    car.bestLapSplits, car.lastSplits = car.bestSplits, car.bestSplits
    car.wheels = { [0] = { tyreVirtualKM = 2 } }
    car.position, car.look, car.distanceToCamera = vec3(i * 5, 0, 0), vec3(0, 0, 1), 30
    setmetatable(car, { __index = function(_, key) error('Unknown ac.StateCar field: ' .. key) end })
    cars[i], names[i], models[i], compounds[i] = car, 'PILOT_' .. string.format('%02d', i + 1), 'test_gt3', 'M'
  end
end
