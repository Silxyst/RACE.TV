local draw, data = require('core.draw'), require('core.data')
local function test(name, fn) fn() print('PASS: ' .. name) end
local function tick(seconds)
  sim.currentSessionTime = sim.currentSessionTime + seconds * 1000
  script.update(seconds)
  assert(#audit.errors == 0, table.concat(audit.errors, '\n'))
end
local function def(title)
  for _, item in ipairs(windowDefinitions) do if item.title == title then return item end end
  error('Unknown window ' .. title)
end
local function textHas(text)
  for _, item in ipairs(audit.texts) do if item.text == text then return true end end
  return false
end
local windows = { 'TV Tower', 'TV Battle', 'TV Onboard Top', 'TV Telemetry', 'TV Inputs',
  'TV Timing', 'TV Onboard Bar', 'TV Spotter', 'TV Map', 'TV Lineup', 'TV Alert', 'TV Narrator', 'TV Results',
  'TV Delta', 'TV Relative', 'TV Fuel', 'TV Session', 'TV Flags' }

test('session clock uses milliseconds', function()
  assert(draw.sessionClock({ sessionTimeLeft = 0, currentSessionTime = 60000 }) == '0:01:00')
end)
test('manifest callbacks exist globally and in script', function()
  for _, item in ipairs(windowDefinitions) do
    for _, key in ipairs({ 'main', 'show', 'hide' }) do
      local name = item[key]
      if name and name ~= '' then
        assert(type(_G[name]) == 'function', 'Missing global: ' .. name)
        assert(type(script[name]) == 'function', 'Missing script callback: ' .. name)
      end
    end
  end
end)
test('all windows render across grids, scales, resolutions and UI scales', function()
  sim.isSessionStarted = false
  for _, count in ipairs({ 0, 1, 6, 20, 40 }) do
    audit.grid(count)
    for _, scale in ipairs({ 0.7, 1, 1.6 }) do
      audit.store('ETV_scale', scale)
      for _, resolution in ipairs({ {1280,720}, {1920,1080}, {3440,1440} }) do
        sim.windowWidth, sim.windowHeight = resolution[1], resolution[2]
        for _, factor in ipairs({ 1, 1.5 }) do
          uiInfo.uiScale = factor
          tick(1 / 60)
          for _, title in ipairs(windows) do audit.render(def(title)) end
          audit.render(def('TV Settings'))
        end
      end
    end
  end
  sim.windowWidth, sim.windowHeight, uiInfo.uiScale = 1920,1080,1
  sim.isSessionStarted = true
  audit.store('ETV_scale', 1)
end)
test('tower auto-resizes from a small window to 1.6x content', function()
  audit.grid(20) tick(0.016)
  audit.store('ETV_scale', 1.6) audit.store('ETV_towerRows', 8)
  local win = audit.windows['TV Tower']
  win.w, win.h = 100, 80
  require('core.winsize').reset()
  tick(0.016)
  audit.render(def('TV Tower'))
  assert(win.w == 640 and win.h > 400)
  audit.store('ETV_scale', 1)
end)
test('tower pagination contains leader/focus once and ordered positions', function()
  audit.grid(40) sim.focusedCar = 7
  audit.store('ETV_scale', 1) audit.store('ETV_towerRows', 10)
  for _ = 1, 180 do tick(0.1) end
  audit.render(def('TV Tower'))
  local namesSeen, positions, leader, focus = {}, {}, 0, 0
  for _, t in ipairs(audit.texts) do
    if t.text:match('^PILOT_') then
      assert(not namesSeen[t.text], 'Duplicate row') namesSeen[t.text] = true
      if t.text == 'PILOT_01' then leader = leader + 1 end
      if t.text == 'PILOT_08' then focus = focus + 1 end
    elseif t.x == 4 and tonumber(t.text) then positions[#positions + 1] = tonumber(t.text) end
  end
  assert(leader == 1 and focus == 1)
  for i = 2, #positions do assert(positions[i] > positions[i-1]) end
end)
test('qualifying sorts by best time rather than race position', function()
  session.type = ac.SessionType.Qualify
  audit.grid(6) cars[5].bestLapTimeMs = 80000 tick(0.016)
  assert(data.list[1].idx == 5 and data.list[1].pos == 1)
  session.type = ac.SessionType.Race
end)
test('missing gaps do not fabricate zero or lap', function()
  audit.grid(2) tick(0.016)
  cars[0].splinePosition = cars[1].splinePosition
  assert(data.gapText(data.list[1], data.list[2]) == '---')
  cars[0].lapCount = 4 cars[1].lapCount = 2
  assert(data.gapText(data.list[1], data.list[2]) == '+2 LAP')
end)
test('same-compound tyre replacement and pit-spawn handling', function()
  audit.grid(2) tick(0.016)
  local tyres, pits = require('core.tyres'), require('core.pits')
  cars[0].lapCount = 5 tick(0.016)
  local _, age = tyres.get(0) assert(age == 3)
  cars[0].wheels[0].tyreVirtualKM = 0 tick(0.016)
  _, age = tyres.get(0) assert(age == 0)
  pits.on_session_start() cars[0].isInPit = true tick(0.1) assert(pits.get(0) == 0)
  cars[0].isInPit = false tick(0.1)
  cars[0].isInPit = true
  for _ = 1, 15 do tick(0.1) end
  cars[0].isInPit = false tick(0.1) assert(pits.get(0) == 1)
end)
test('GT3 manufacturers share a category', function()
  audit.grid(3) models[0] = 'ferrari_gt3' models[1] = 'porsche_gt3' models[2] = 'ginetta_gt4'
  tick(0.016)
  local classes = require('core.classes')
  assert(classes.get(0).key == classes.get(1).key and classes.get(2).key ~= classes.get(1).key)
end)
test('lineup draws before the start and clears after it', function()
  audit.grid(20) sim.isSessionStarted = false tick(0.1)
  audit.render(def('TV Lineup')) assert(textHas('STARTING GRID'))
  sim.isSessionStarted = true tick(0.1)
  audit.render(def('TV Lineup')) assert(not textHas('STARTING GRID'))
end)
test('unavailable map sampled once and reloads after layout change', function()
  audit.noMap = true audit.mapCalls = 0 audit.layout = 'invalid'
  audit.render(def('TV Map')) local calls = audit.mapCalls
  audit.render(def('TV Map')) assert(audit.mapCalls == calls)
  audit.noMap = false audit.layout = 'new'
  audit.render(def('TV Map')) assert(audit.mapCalls > calls)
end)
test('tags and progressive pedals stay inside the virtual texture', function()
  audit.grid(2) tick(0.1)
  names[1] = 'Álvaro Nascimento sobrenome muito muito longo para o quadro'
  assert(audit.tagCallback)
  audit.current = { title = 'TV Tags', w = audit.tagSize.x, h = audit.tagSize.y }
  audit.texts, audit.draws = {}, {}
  audit.tagCallback(cars[1])
  assert(audit.clip == 0 and audit.fonts == 0)
  local green, red = false, false
  for _, d in ipairs(audit.draws) do
    if d.color.g > 0.8 and d.color.r < 0.2 then green = true end
    if d.color.r == 1 and d.color.g < 0.2 then red = true end
  end
  assert(green and red)
end)
test('PB alert has a dark background, detail and audio', function()
  audit.grid(3) sim.focusedCar = 1 audit.restart() tick(0.1)
  cars[1].bestLapTimeMs = 90050 tick(0.1) tick(0.1)
  audit.render(def('TV Alert')) assert(textHas('PERSONAL BEST'))
  local detail, dark = false, false
  for _, t in ipairs(audit.texts) do if t.text:find('PILOT_02') then detail = true end end
  for _, r in ipairs(audit.draws) do if r.color.r < 0.1 and r.color.b < 0.1 then dark = true end end
  assert(detail and dark and audit.audioStarts > 0)
end)
test('session rewind resets trackers', function()
  sim.currentSessionTime = -10000 script.update(0.016)
  assert(require('core.pits').get(0) == 0 and #audit.errors == 0)
end)
test('steering uses degrees and inputs follow the focused car', function()
  audit.grid(3) sim.focusedCar = 1
  cars[1].steer, cars[1].gas = 90, 0.8
  for _ = 1, 30 do tick(0.016) end
  audit.render(def('TV Inputs')) assert(textHas('R 90') and textHas('80'))
end)
test('session change resets sector and classification caches', function()
  audit.grid(2) tick(0.016)
  cars[0].bestSplits[0], cars[1].bestSplits[0] = 50000, 55000
  sim.currentSessionIndex = sim.currentSessionIndex + 1 tick(0.016)
  assert(require('core.sectors').best(1) == 50000)
end)
test('disconnecting the fastest driver does not rebase the record', function()
  audit.grid(3) sim.focusedCar = 1 audit.restart() tick(0.1)
  cars[0].isConnected = false tick(0.1)
  cars[1].bestLapTimeMs = 90050 tick(0.1) tick(0.1)
  audit.render(def('TV Alert'))
  assert(textHas('PERSONAL BEST') and not textHas('FASTEST LAP'))
end)
test('hidden windows keep rendering for OBS Apps Redirection', function()
  audit.grid(6) sim.isSessionStarted = false tick(0.1)
  for _, title in ipairs(windows) do
    if title == 'TV Alert' then
      audit.renderRedirected(def(title)) -- no event queued: renders empty, without errors
    else
      audit.renderRedirected(def(title))
    end
  end
  audit.renderRedirected(def('TV Tower'))
  assert(textHas('PILOT_01'))
  sim.isSessionStarted = true
end)
test('auto-layout positions windows and respects the manual toggle', function()
  audit.grid(6) tick(0.1)
  audit.store('ETV_autoLayout', true)
  local win = audit.windows['TV Tower']
  win.x, win.y = 900, 500
  audit.store('ETV_scale', 1.3)
  tick(0.1)
  assert(math.abs(win.x - 24) < 200 and win.y < 400)
  audit.store('ETV_autoLayout', false)
  win.x, win.y = 900, 500
  tick(0.1)
  assert(win.x == 900 and win.y == 500)
  audit.store('ETV_autoLayout', true)
  audit.store('ETV_scale', 1)
end)
test('UI scaling uses ac.getUI, with no state_sim.uiScale member', function()
  assert(not pcall(function() return sim.uiScale end), 'Mock must reproduce runtime field absence')
  uiInfo.uiScale = 1.5
  local size = require('core.screen').size()
  assert(size.x == sim.windowWidth / 1.5 and size.y == sim.windowHeight / 1.5)
  audit.render(def('TV Telemetry')) assert(textHas('GEAR'))
  uiInfo.uiScale = 1
end)
test('UI-scale getter failure falls back without aborting HUD drawing', function()
  local original = ac.getUI
  ac.getUI = function() error('UI metadata unavailable') end
  local size = require('core.screen').size()
  assert(size.x == sim.windowWidth and size.y == sim.windowHeight)
  audit.render(def('TV Telemetry')) assert(textHas('GEAR'))
  ac.getUI = original
end)
test('settings window renders without errors', function()
  audit.render(def('TV Settings'))
  assert(#audit.errors == 0)
end)
test('tower final page stays full, ordered, unique and the same size', function()
  audit.grid(23) sim.focusedCar = 7
  audit.store('ETV_towerRows', 10) audit.store('ETV_scale', 1)
  audit.restart()
  local win = audit.windows['TV Tower']
  local height
  for frame = 1, 250 do
    tick(0.1)
    if frame % 20 == 0 then
      audit.render(def('TV Tower'))
      height = height or win.h
      assert(win.h == height, 'Tower resized between pages')
      local seen, n = {}, 0
      for _, item in ipairs(audit.texts) do
        if item.text:match('^PILOT_') then
          assert(not seen[item.text], 'Duplicate driver on page')
          seen[item.text], n = true, n + 1
        end
      end
      assert(n == 10 and seen.PILOT_01 and seen.PILOT_08)
    end
  end
end)
test('tower intro does not restart on duplicate show or scaled resize reports', function()
  audit.grid(12) tick(0.1)
  local win = audit.windows['TV Tower']
  audit.resizeEmitsShow = true
  audit.sizeReportFactor = 1.25
  audit.store('ETV_scale', 1.25)
  script.vsTowerShow(0)
  local settledCalls
  for frame = 1, 45 do
    tick(0.1)
    script.vsTowerShow(0) -- some window/layer transitions repeat the notification
    audit.render(def('TV Tower'))
    if frame == 10 then settledCalls = win.resizeCalls end
    if frame > 10 then
      assert(win.resizeCalls == settledCalls, 'Repeated resize request')
      assert(audit.draws[1].color.mult > 0.9, 'Intro alpha reset')
    end
  end
  audit.resizeEmitsShow, audit.sizeReportFactor = false, nil
  audit.store('ETV_scale', 1)
end)
test('tower rendering is read-only for duplicate OBS draw passes', function()
  audit.grid(12) tick(0.1)
  audit.render(def('TV Tower'))
  cars[0].racePosition, cars[7].racePosition = 8, 1
  tick(0.016)
  audit.render(def('TV Tower'))
  local positions = {}
  for _, item in ipairs(audit.texts) do
    if item.text:match('^PILOT_') then positions[item.text] = item.y end
  end
  audit.paint(def('TV Tower'))
  for _, item in ipairs(audit.texts) do
    if item.text:match('^PILOT_') then assert(positions[item.text] == item.y, 'Animation advanced during draw') end
  end
end)
test('preset click applies theme immediately to surfaces and pilot widgets', function()
  audit.grid(6)
  for _ = 1, 10 do tick(0.1) end
  local cfg = require('core.config')
  cfg.setPreset(1)
  local before = {}
  for _, title in ipairs({ 'TV Tower', 'TV Telemetry', 'TV Onboard Top', 'TV Battle' }) do
    audit.render(def(title))
    before[title] = audit.draws[1].color
  end
  audit.radioClick = 'Enduro Blue'
  audit.render(def('TV Settings'))
  assert(cfg.get().preset == 2 and textHas('Tema aplicado: Enduro Blue'))
  for _, title in ipairs({ 'TV Tower', 'TV Telemetry', 'TV Onboard Top', 'TV Battle' }) do
    audit.render(def(title))
    local color = audit.draws[1].color
    assert(math.abs(color.r - before[title].r) + math.abs(color.b - before[title].b) > 0.01, 'Theme did not affect ' .. title)
  end
  cfg.setPreset(3)
  assert(cfg.get().brand1.g > cfg.get().brand1.r)
  cfg.setPreset(1)
end)
test('unknown tyre data and pit-box status do not break the tower', function()
  audit.grid(6) compounds[1] = nil
  require('core.config').setTowerMode(4)
  tick(0.1)
  audit.render(def('TV Tower'))
  cars[1].isInPit = true cars[1].speedKmh = 0
  tick(0.1)
  audit.render(def('TV Tower'))
  assert(textHas('P') and not textHas('OUT'))
  require('core.config').setTowerMode(1)
end)
test('remote delta is unavailable and telemetry shows actual focused inputs', function()
  audit.grid(3) sim.focusedCar = 1
  cars[1].isRemote = true cars[1].gas = 0.8 cars[1].brake = 0.5
  for _ = 1, 15 do tick(0.1) end
  audit.render(def('TV Timing'))
  for _, item in ipairs(audit.texts) do assert(item.text ~= 'LIVE') end
  audit.render(def('TV Telemetry'))
  local throttle, brake = false, false
  for _, item in ipairs(audit.draws) do
    if item.color.g > 0.9 and item.color.r < 0.2 and item.b.x > item.a.x then throttle = true end
    if item.color.r > 0.9 and item.color.g < 0.3 and item.b.x > item.a.x then brake = true end
  end
  assert(throttle and brake)
end)
test('10-20 tower rows remain stable with deferred/clamped CSP resizing', function()
  audit.grid(40) sim.focusedCar = 7
  audit.store('ETV_scale', 1)
  audit.towerMaxHeight, audit.deferResize, audit.resizeEmitsHideShow = 340, true, true
  for _, rows in ipairs({ 10, 11, 12, 15, 20 }) do
    audit.store('ETV_towerRows', rows)
    require('core.winsize').reset()
    audit.restart()
    local settled
    for frame = 1, 210 do
      tick(0.1)
      audit.render(def('TV Tower')) -- paint before the native request settles
      audit.settleSizes()
      if frame == 12 then settled = audit.windows['TV Tower'].resizeCalls end
      if frame > 12 then
        assert(audit.windows['TV Tower'].resizeCalls == settled, 'Resize loop above nine rows')
        assert(audit.draws[1].color.mult > 0.9, 'Tower flashed after a native show event')
        local seen, n = {}, 0
        for _, item in ipairs(audit.texts) do
          if item.text:match('^PILOT_') then assert(not seen[item.text]) seen[item.text] = true n = n + 1 end
        end
        assert(n >= 3 and n <= rows and seen.PILOT_01 and seen.PILOT_08)
      end
    end
  end
  audit.towerMaxHeight, audit.deferResize, audit.resizeEmitsHideShow = nil, false, false
  require('core.winsize').reset()
end)
test('clicking a name below row nine focuses the driver, not the row number', function()
  audit.grid(25) sim.focusedCar = 0
  audit.store('ETV_towerRows', 15) audit.store('ETV_scale', 1.6)
  audit.restart()
  for _ = 1, 8 do tick(0.1) end
  audit.clickId, audit.hoverId = '##race_tv_focus_11', '##race_tv_focus_11'
  local before, mode = audit.focusChanges, sim.cameraMode
  audit.render(def('TV Tower'))
  assert(sim.focusedCar == 11 and audit.focusChanges == before + 1)
  assert(sim.cameraMode == mode and audit.mouseCursor == ui.MouseCursor.Hand)
  assert(audit.tooltip:find('PILOT_12'))
end)
test('tower page clicks and duplicate OBS traversals dispatch only one focus', function()
  audit.grid(40) sim.focusedCar = 0
  audit.store('ETV_towerRows', 10) audit.store('ETV_scale', 1)
  audit.restart()
  for _ = 1, 90 do tick(0.1) end -- second page
  audit.render(def('TV Tower'))
  local button = audit.buttons[#audit.buttons]
  local index = tonumber(button.id:match('(%d+)$'))
  assert(index > 9)
  audit.clickId, audit.repeatClick = button.id, true
  local before = audit.focusChanges
  audit.paint(def('TV Tower'))
  audit.paint(def('TV Tower'))
  assert(sim.focusedCar == index and audit.focusChanges == before + 1)
  audit.clickId, audit.repeatClick = nil, false
end)
test('clicking a removed driver is ignored and redirected-only output receives no input', function()
  audit.grid(15) audit.store('ETV_towerRows', 15)
  audit.restart()
  for _ = 1, 8 do tick(0.1) end
  audit.render(def('TV Tower'))
  local before = audit.focusChanges
  cars[11].isConnected = false -- driver disconnects between update and draw
  audit.clickId = '##race_tv_focus_11'
  audit.paint(def('TV Tower'))
  assert(audit.focusChanges == before)
  cars[11].isConnected = true
  audit.clickId = '##race_tv_focus_11'
  audit.renderRedirected(def('TV Tower'))
  assert(audit.focusChanges == before)
  audit.clickId = nil
end)
test('every widget stays opaque and resize-free with delayed scale changes', function()
  audit.grid(40) sim.focusedCar = 7 sim.isSessionStarted = false
  audit.deferResize, audit.resizeEmitsHideShow = true, true
  for _, scale in ipairs({ 0.7, 1.3, 1.6, 1, 1.6 }) do
    audit.store('ETV_scale', scale) audit.store('ETV_towerRows', 20)
    local settled = {}
    for frame = 1, 30 do
      tick(0.1)
      for _, title in ipairs(windows) do
        audit.render(def(title))
        local win = audit.windows[title]
        if frame == 12 then settled[title] = win.resizeCalls end
        if frame > 12 then
          assert(win.resizeCalls == settled[title], 'Resize churn: ' .. title)
          if title ~= 'TV Alert' and #audit.draws > 0 then
            assert(audit.draws[1].color.mult > 0.89, 'Replayed fade: ' .. title)
          end
        end
      end
      audit.settleSizes()
    end
    assert(audit.windows['TV Tower'].w == math.ceil(400 * scale))
    assert(audit.windows['TV Telemetry'].w == math.ceil(470 * scale))
    assert(audit.windows['TV Tower'].h <= sim.windowHeight)
    audit.render(def('TV Tower'))
    local count = 0
    for _, text in ipairs(audit.texts) do
      if text.text:match('^PILOT_') then count = count + 1 assert(math.abs(text.size - 13 * scale) <= 0.26) end
    end
    assert(count == 20, 'Twenty rows must remain full size at 1080p')
  end
  audit.deferResize, audit.resizeEmitsHideShow = false, false
  sim.isSessionStarted = true audit.store('ETV_scale', 1)
end)
test('font fitting uses a bounded half-pixel size grid', function()
  audit.grid(6) tick(0.1)
  for i = 1, 40 do
    cars[0].speedKmh = i * 7.15
    audit.render(def('TV Telemetry'))
    for _, text in ipairs(audit.texts) do
      if text.size then assert(text.size * 2 == math.floor(text.size * 2), 'Unbounded fractional glyph size') end
    end
  end
end)
test('narrator focus clicks are manual and deduplicated on repeated drawing', function()
  audit.grid(6) audit.restart() tick(0.1)
  audit.render(def('TV Narrator'))
  audit.clickId, audit.repeatClick = '##narrator_next', true
  local before, camera = audit.focusChanges, sim.cameraMode
  audit.paint(def('TV Narrator')) audit.paint(def('TV Narrator'))
  assert(sim.focusedCar == 1 and audit.focusChanges == before + 1 and sim.cameraMode == camera)
  audit.clickId, audit.repeatClick = nil, false
  audit.hotkey = 'TV_FOCUS_LEADER' tick(0.1)
  assert(sim.focusedCar == 0)
end)
test('favorites persist by driver identity and skip disconnected or replaced indices', function()
  audit.grid(6) tick(0.1)
  local control = require('core.control')
  if control.isFavorite(0) then control.toggleFavorite(0) end
  if control.isFavorite(2) then control.toggleFavorite(2) end
  control.toggleFavorite(0) control.toggleFavorite(2)
  control.nextFavorite() assert(sim.focusedCar == 2)
  audit.restart() tick(0.1)
  assert(control.isFavorite(0) and control.isFavorite(2))
  cars[2].isConnected = false tick(0.1)
  control.nextFavorite() assert(sim.focusedCar == 0)
  cars[2].isConnected = true names[2] = 'REPLACEMENT' tick(0.1)
  assert(not control.isFavorite(2))
end)
test('manual comparison stays selected, rejects duplicates and clears replaced drivers', function()
  audit.grid(6) audit.restart() tick(0.1)
  local control = require('core.control')
  assert(control.choose('A', 3) and control.choose('B', 5))
  assert(not control.choose('B', 3))
  for _ = 1, 60 do tick(0.1) end
  audit.render(def('TV Battle'))
  local manual = false
  for _, text in ipairs(audit.texts) do if text.text:find('COMPARAÇÃO MANUAL', 1, true) then manual = true end end
  assert(textHas('PILOT_04') and textHas('PILOT_06') and manual)
  names[5] = 'REPLACEMENT' tick(0.1)
  assert(control.pair() == nil and control.slot('B') == nil)
end)
test('lap comparison records observed laps once and resets on session changes', function()
  audit.grid(3) audit.restart() tick(0.1)
  local control = require('core.control')
  for _, lap in ipairs({ 90000, 91000, 92000, 93000 }) do
    cars[1].previousLapTimeMs = lap cars[1].lapCount = cars[1].lapCount + 1
    tick(0.1) audit.render(def('TV Battle')) audit.paint(def('TV Battle'))
  end
  assert(#control.laps(1) == 4 and control.average(1) == 92000)
  audit.restart() tick(0.1)
  assert(#control.laps(1) == 0 and control.average(1) == nil)
end)
test('crossing gaps stay accurate when speed changes and across the finish line', function()
  audit.grid(2) audit.restart()
  cars[0].lapCount, cars[1].lapCount = 2, 2
  cars[0].splinePosition, cars[1].splinePosition = 0.92, 0.89
  tick(0.1)
  local front, back = 2.92, 2.89
  for _ = 1, 160 do
    front, back = front + 0.001, back + 0.001
    cars[0].lapCount, cars[0].splinePosition = math.floor(front), front % 1
    cars[1].lapCount, cars[1].splinePosition = math.floor(back), back % 1
    tick(0.1)
  end
  local value, source = data.gap(data.byIndex[0], data.byIndex[1])
  assert(source == 'PASSAGEM' and math.abs(value - 3) < 0.01)
  cars[1].speedKmh = 40
  tick(0.1)
  value, source = data.gap(data.byIndex[0], data.byIndex[1])
  assert(source == 'PASSAGEM' and math.abs(value - 3) < 0.01)
  cars[1].isInPitlane = true tick(0.1)
  assert(require('core.timing').gap(data.byIndex[0], data.byIndex[1]) == nil)
  cars[1].isInPitlane = false audit.restart() tick(0.1)
  assert(require('core.timing').gap(data.byIndex[0], data.byIndex[1]) == nil)
end)
test('teleport and replacement invalidate crossing observations', function()
  cars[1].splinePosition = 0.1 tick(0.1)
  assert(require('core.timing').gap(data.byIndex[0], data.byIndex[1]) == nil)
  names[0] = 'REPLACEMENT' tick(0.1)
  assert(require('core.timing').gap(data.byIndex[0], data.byIndex[1]) == nil)
end)
test('results wait for finish and preserve podium and fastest lap after disconnection', function()
  audit.grid(6) audit.restart() tick(0.1)
  local results = require('core.results')
  assert(not results.available)
  audit.render(def('TV Results'))
  cars[0].isRaceFinished = true tick(0.1)
  assert(results.available and not results.final)
  for i = 1, 5 do cars[i].isRaceFinished = true end
  tick(0.1) assert(results.final and #results.rows == 6)
  cars[0].isConnected = false cars[0].racePosition = 99 names[0] = 'REPLACEMENT'
  tick(0.1) audit.renderRedirected(def('TV Results'))
  assert(results.rows[1].name == 'PILOT_01' and results.rows[1].pos == 1)
  assert(textHas('PILOT_01'))
  local fastest = false
  for _, text in ipairs(audit.texts) do if text.text:find('MELHOR VOLTA: PILOT_01', 1, true) then fastest = true end end
  assert(fastest)
  audit.grid(6) audit.restart() tick(0.1)
  assert(not results.available)
end)
test('saved layouts restore scale, rows and normalized positions without changing redirection', function()
  audit.grid(20) audit.restart() tick(0.1)
  local cfg, layouts = require('core.config'), require('core.layouts')
  cfg.setValues({ scale = 1.25, towerRows = 20, autoLayout = false }) tick(0.1)
  local tower = audit.windows['TV Tower']
  tower.x, tower.y, tower.redirected = 220, 18, true
  assert(layouts.save('Corrida'))
  layouts.request('Vertical', true) tick(0.1)
  assert(cfg.get().scale == 0.85 and cfg.get().towerRows == 12)
  audit.deferResize = true
  layouts.request('Corrida') tick(0.1)
  assert(cfg.get().scale == 1.25 and cfg.get().towerRows == 20 and not cfg.get().autoLayout)
  assert(math.abs(tower.x-220) < 0.01 and math.abs(tower.y-18) < 0.01 and tower.redirected)
  audit.settleSizes() audit.deferResize = false
  local calls = tower.resizeCalls
  for _ = 1, 20 do tick(0.1) audit.render(def('TV Tower')) end
  assert(tower.resizeCalls == calls and math.abs(tower.x-220) < 0.01)
  cfg.setValues({ scale = 1, autoLayout = true }) tick(0.1)
end)
test('corrupted layouts fall back and hotkeys/buttons apply profiles on update', function()
  local layouts = require('core.layouts')
  audit.store('ETV_layout_Replay', 'nan|20\nTV Tower|inf|0|1')
  layouts.request('Replay') tick(0.1)
  assert(require('core.config').get().towerRows == 10)
  audit.hotkey = 'TV_LAYOUT_NEXT' tick(0.1) tick(0.1)
  assert(layouts.current() == 'Vertical')
  audit.clickId = '##narrator_results' audit.render(def('TV Narrator')) tick(0.1)
  assert(audit.windows['TV Results']:visible())
  audit.clickId = nil
  require('core.config').setValues({ scale = 1, autoLayout = true }) tick(0.1)
end)
test('custom branding colors, logo and driver metadata apply through the UI', function()
  audit.grid(6) sim.focusedCar = 1 tick(0.1)
  local cfg, branding = require('core.config'), require('core.branding')
  audit.checkboxClick = 'Usar cor personalizada'
  audit.sliders = { Vermelho = 30, Verde = 170, Azul = 230 }
  audit.inputs = { ['Logo PNG/JPG/DDS (caminho)'] = 'icon.png', ['Número do carro'] = '27',
    ['Equipe (vazio usa o modelo do carro)'] = 'Equipe Teste' }
  audit.render(def('TV Settings')) tick(0.1)
  assert(cfg.get().customColor and math.abs(cfg.get().brand1.b - 230/255) < 0.001)
  assert(branding.logo() and branding.logoStatus == 'Logo carregado')
  local number, team = branding.driver(1)
  assert(number == '27' and team == 'Equipe Teste')
  audit.images = {} audit.render(def('TV Onboard Top'))
  assert(#audit.images > 0 and textHas('EQUIPE TESTE · #27 · GT3'))
  names[1] = 'REPLACEMENT'
  number, team = branding.driver(1)
  assert(number == '11' and team ~= 'Equipe Teste')
  cfg.set('logo', 'assets/nonexistent.png') tick(0.1)
  assert(branding.logo() == nil)
  cfg.setPreset(1) cfg.set('logo', '') tick(0.1)
end)
test('unchanged settings do not continuously write persistent storage', function()
  audit.grid(6) tick(0.1) audit.render(def('TV Settings'))
  local before = audit.storeWrites
  for _ = 1, 30 do audit.render(def('TV Settings')) end
  assert(audit.storeWrites == before, 'Repeated storage writes while idle')
end)
test('small viewports paginate twenty-row towers while preserving common width and fonts', function()
  audit.grid(40) sim.focusedCar = 7
  sim.windowWidth, sim.windowHeight, uiInfo.uiScale = 1280, 720, 1.5
  require('core.config').setValues({ scale = 1.6, towerRows = 20, autoLayout = true })
  tick(0.1) audit.render(def('TV Tower'))
  assert(audit.windows['TV Tower'].w == 640 and audit.windows['TV Tower'].h <= 480)
  local seen, rows = {}, 0
  for _, text in ipairs(audit.texts) do
    if text.text:match('^PILOT_') then
      assert(not seen[text.text] and math.abs(text.size-20.8) <= 0.26)
      seen[text.text], rows = true, rows+1
    end
  end
  assert(rows < 20 and seen.PILOT_01 and seen.PILOT_08)
  sim.windowWidth, sim.windowHeight, uiInfo.uiScale = 1920,1080,1
  require('core.config').setValues({ scale = 1, autoLayout = true }) tick(0.1)
end)
test('posicoes duplicadas do jogo viram sequencia unica na torre e resultados', function()
  audit.grid(20) audit.restart() tick(0.1)
  for i = 0, 19 do cars[i].racePosition = math.floor(i / 2) + 1 end
  cars[12].racePosition = 2
  tick(0.1)
  local seen, last = {}, 0
  for _, row in ipairs(data.list) do
    assert(row.pos == row.rank, 'Posicao da torre deve seguir a ordem')
    assert(not seen[row.pos], 'Posicao repetida na classificacao')
    seen[row.pos] = true
    assert(row.pos == last + 1, 'Posicao pulou numero')
    last = last + 1
  end
  cars[0].isRaceFinished = true tick(0.1)
  local results = require('core.results')
  assert(results.available and #results.rows == 20)
  for i, row in ipairs(results.rows) do assert(row.pos == i, 'Resultado deve ser 1..N') end
  audit.render(def('TV Results'))
  local podium, tablePos = {}, {}
  for _, text in ipairs(audit.texts) do
    if text.text == 'P1' or text.text == 'P2' or text.text == 'P3' then podium[#podium+1] = text.text end
    if text.x == 14 and tonumber(text.text) then tablePos[#tablePos+1] = tonumber(text.text) end
  end
  assert(#podium == 3 and podium[1] == 'P1' and podium[2] == 'P2' and podium[3] == 'P3')
  for i = 2, #tablePos do assert(tablePos[i] == tablePos[i-1] + 1, 'Tabela pulou posicao') end
  audit.render(def('TV Tower'))
  local towerPos = {}
  for _, text in ipairs(audit.texts) do
    if text.x == 4 and tonumber(text.text) then towerPos[#towerPos+1] = tonumber(text.text) end
  end
  for i = 2, #towerPos do assert(towerPos[i] > towerPos[i-1], 'Torre fora de ordem') end
  local uniq = {}
  for _, v in ipairs(towerPos) do assert(not uniq[v], 'Torre repetiu posicao') uniq[v] = true end
end)
test('piloto focado permanece visivel e clicavel em todas as paginas da torre', function()
  audit.grid(40) sim.focusedCar = 39
  audit.store('ETV_towerRows', 10) audit.store('ETV_scale', 1)
  audit.restart() tick(0.1)
  for page = 1, 6 do
    for _ = 1, 80 do tick(0.1) end
    audit.render(def('TV Tower'))
    assert(textHas('PILOT_01'), 'Lider deve ficar fixo')
    assert(textHas('PILOT_40'), 'Focado deve ficar fixo em toda pagina')
    local found = false
    for _, button in ipairs(audit.buttons) do
      if button.id == '##race_tv_focus_39' then found = true end
    end
    assert(found, 'Linha do focado deve ser clicavel')
  end
  audit.clickId = '##race_tv_focus_39'
  local before = audit.focusChanges
  audit.paint(def('TV Tower'))
  assert(audit.focusChanges == before or sim.focusedCar == 39)
  audit.clickId = nil
end)
test('tower sem carros vazios: altura segue o conteudo e pílula legível', function()
  audit.grid(6) audit.restart()
  audit.store('ETV_towerRows', 20) audit.store('ETV_scale', 1)
  tick(0.1) audit.render(def('TV Tower'))
  local win = audit.windows['TV Tower']
  assert(win.h == 86 + 22 + 6 * 30, 'Altura deve seguir 6 linhas + faixa ambiente, sem vão vazio')
  for _, text in ipairs(audit.texts) do
    if text.text:match('^PILOT_') then assert(text.size >= 12.9, 'Fonte da torre encolhida') end
  end
  sim.windowWidth, sim.windowHeight, uiInfo.uiScale = 1280, 720, 1.5
  audit.store('ETV_scale', 1.6) tick(0.1) audit.render(def('TV Tower'))
  assert(win.h <= 480, 'Torre deve paginar em viewport pequena')
  local rows = 0
  for _, text in ipairs(audit.texts) do if text.text:match('^PILOT_') then rows = rows + 1 end end
  assert(rows >= 3 and rows < 20, 'Paginacao deve preservar leitura em vez de espremer linhas')
  sim.windowWidth, sim.windowHeight, uiInfo.uiScale = 1920,1080,1
  audit.store('ETV_scale', 1) audit.store('ETV_towerRows', 8) tick(0.1)
end)
test('troca de piloto no mesmo indice nao gera seta falsa na torre', function()
  audit.grid(6) audit.restart() tick(0.1)
  audit.render(def('TV Tower'))
  names[2] = 'REPLACEMENT DRIVER' tick(0.5)
  audit.render(def('TV Tower'))
  local found = false
  for _, text in ipairs(audit.texts) do if text.text == '▲' or text.text == '▼' then found = true end end
  assert(not found, 'Seta falsa apos troca de piloto')
end)
test('logo aceita caminho absoluto, maiusculas e mostra onde procurou', function()
  audit.grid(6) tick(0.1)
  local cfg = require('core.config')
  cfg.set('logo', 'C:/fake/dir/MINHALOGO.PNG') tick(0.1)
  local branding = require('core.branding')
  assert(branding.logo() == nil)
  assert(require('core.branding').logoStatus:find('MINHALOGO.PNG', 1, true))
  cfg.set('logo', 'icon.png') tick(0.1)
  assert(branding.logo() and branding.ready())
  cfg.set('logo', 'arquivo.txt') tick(0.1)
  assert(branding.logo() == nil)
  assert(branding.logoStatus:find('Formato', 1, true))
  cfg.set('logo', '') tick(0.1)
end)
test('numero real do jogo aparece quando nao ha override', function()
  audit.grid(3) tick(0.1)
  local number = require('core.branding').driver(2)
  assert(number == '12', 'Numero nativo esperado, obtido: ' .. tostring(number))
  require('core.branding').setDriver(2, '99', '')
  number = require('core.branding').driver(2)
  assert(number == '99')
end)
test('gap nativo ao lider aparece na batalha e no narrador', function()
  audit.grid(6) sim.focusedCar = 2 audit.restart() tick(2.2)
  audit.render(def('TV Battle'))
  local found = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('DER', 1, true) then found = true end
  end
  assert(found, 'Gap ao lider ausente na batalha')
  audit.render(def('TV Narrator'))
  found = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('DER', 1, true) then found = true end
  end
  assert(found, 'Gap ao lider ausente no narrador')
end)
test('faixa de ambiente mostra bandeira, grip e temperaturas', function()
  audit.grid(6) tick(0.1)
  audit.render(def('TV Tower'))
  assert(textHas('RACE'))
  local flag, strip = false, false
  for _, text in ipairs(audit.texts) do
    if text.text == 'LAP 4/10' or text.text == 'YELLOW' or text.text == 'CHEQUERED' then flag = true end
    if text.text:find('GRIP', 1, true) then strip = true end
  end
  assert(flag and strip)
  sim.raceFlagType = ac.FlagType.Caution tick(0.1)
  audit.render(def('TV Tower'))
  assert(textHas('YELLOW'))
  sim.raceFlagType = 0
  require('core.config').set('showEnv', false) tick(0.1)
  audit.render(def('TV Tower'))
  local env = false
  for _, text in ipairs(audit.texts) do if text.text:find('GRIP', 1, true) then env = true end end
  assert(not env, 'Faixa deveria sumir com showEnv desligado')
  require('core.config').set('showEnv', true) tick(0.1)
end)
test('multiclass por tag e override classifica sem quebrar heuristica', function()
  audit.grid(3) models[0] = 'mc_blancpain_car' models[1] = 'mc_porsche_gt3' models[2] = 'mc_ginetta_gt4'
  audit.tagFiles = { mc_blancpain_car = '{"tags":["GT3","Blancpain"]}' }
  audit.store('ETV_mc1Enabled', true) audit.store('ETV_mc1Tag', 'Blancpain')
  audit.store('ETV_mc1Color', '#FF0000')
  tick(0.1)
  local classes = require('core.classes')
  assert(classes.get(0).key:find('BLANCPAIN', 1, true), 'Tag deveria vencer: ' .. classes.get(0).key)
  assert(classes.get(1).key == classes.get(0).key or classes.get(1).key == 'GT3')
  assert(classes.get(2).key == 'GT4')
  audit.tagFiles = nil
  audit.store('ETV_mc1Enabled', false) tick(0.1)
  assert(classes.get(1).key == 'GT3' and classes.get(2).key == 'GT4')
end)
test('tower nunca mostra pagina vazia ou cortada em nenhuma configuracao', function()
  for _, count in ipairs({ 8, 10, 19, 20, 21, 24, 40 }) do
    for _, rows in ipairs({ 5, 7, 8, 10, 15, 20 }) do
      for _, filter in ipairs({ false, true }) do
        audit.grid(count) sim.focusedCar = 0
        audit.store('ETV_towerRows', rows)
        audit.store('ETV_classFilter', filter)
        audit.store('ETV_scale', 1)
        audit.restart()
        for _ = 1, 10 do tick(0.1) end
        local tower = require('widgets.tower')
        -- percorre todas as paginas (8s cada) e confere cada desenho
        for page = 1, 12 do
          for _ = 1, 80 do tick(0.1) end
          audit.render(def('TV Tower'))
          local names, positions = {}, {}
          for _, text in ipairs(audit.texts) do
            if text.text:match('^PILOT_') then
              assert(not names[text.text], 'Piloto duplicado: grid=' .. count .. ' rows=' .. rows)
              names[text.text] = true
            end
            if text.x == 4 and tonumber(text.text) then positions[#positions + 1] = tonumber(text.text) end
          end
          local n = 0
          for _ in pairs(names) do n = n + 1 end
          assert(n > 0, 'Pagina vazia: grid=' .. count .. ' rows=' .. rows .. ' filter=' .. tostring(filter))
          assert(n == #positions, 'Linha sem numero de posicao')
          local win = audit.windows['TV Tower']
          assert(win.h >= 86 + 22 + n * 22, 'Janela menor que o conteudo: h=' .. win.h .. ' linhas=' .. n)
        end
      end
    end
  end
  audit.store('ETV_classFilter', false) audit.store('ETV_towerRows', 8)
end)
test('janela limitada pelo CSP: torre pagina no que cabe, sem cortar e sem esvaziar', function()
  audit.grid(40) sim.focusedCar = 7
  audit.store('ETV_scale', 1) audit.store('ETV_towerRows', 20)
  audit.towerMaxHeight, audit.deferResize = 200, true
  require('core.winsize').reset()
  audit.restart()
  local settled
  for frame = 1, 60 do
    tick(0.1)
    audit.render(def('TV Tower'))
    audit.settleSizes()
    local win = audit.windows['TV Tower']
    if frame == 12 then settled = win.resizeCalls end
    if frame > 12 then
      assert(win.resizeCalls == settled, 'Loop de resize com janela limitada')
      assert(win.h == 200, 'Janela deveria seguir o limite nativo')
      -- conteudo desenhado cabe na janela real: nada cortado, nada vazio
      local rows, bottom = 0, 0
      for _, text in ipairs(audit.texts) do
        if text.text:match('^PILOT_') then
          rows = rows + 1
          bottom = math.max(bottom, (text.y or 0) + (text.size or 0))
        end
      end
      assert(rows >= 3, 'Torre esvaziou com janela limitada')
      assert(bottom <= win.h + 1, 'Conteudo cortado pela janela: ' .. bottom .. ' > ' .. win.h)
    end
  end
  -- limite liberado + mudanca logica: a janela volta ao tamanho cheio
  audit.towerMaxHeight, audit.deferResize = nil, false
  require('core.winsize').reset()
  audit.store('ETV_towerRows', 19) tick(0.1)
  audit.settleSizes() tick(0.1)
  audit.render(def('TV Tower'))
  assert(audit.windows['TV Tower'].h > 200, 'Janela nao voltou ao tamanho cheio')
  local rows = 0
  for _, text in ipairs(audit.texts) do if text.text:match('^PILOT_') then rows = rows + 1 end end
  assert(rows == 19, 'Deveria mostrar 19 linhas, mostrou ' .. rows)
  audit.store('ETV_towerRows', 8)
end)
test('cor da classe sai com um clique na paleta, sem digitar hex', function()
  audit.grid(3) tick(0.1)
  local classes = require('core.classes')
  audit.store('ETV_mc1Color', '#FFFFFF') tick(0.1)
  audit.buttonClick = '##mc1preset1'
  audit.render(def('TV Settings')) tick(0.1)
  assert(ac.storage('ETV_mc1Color', ''):get() == '#E10600', 'Clique na paleta deveria aplicar o vermelho')
  assert(classes.setColor(2, '00ff00') and ac.storage('ETV_mc2Color', ''):get() == '#00FF00')
  assert(not classes.setColor(2, 'zzz'))
  assert(not classes.setColor(9, '#E10600'))
  assert(not classes.setColor(2, nil))
end)
test('dica mostra carros que casam com a tag digitada', function()
  audit.grid(3) models[0] = 'hint_car_a' models[1] = 'hint_car_b' models[2] = 'hint_car_c'
  audit.tagFiles = { hint_car_a = '{"tags":["Endurance"]}', hint_car_b = '{"tags":["Sprint"]}' }
  tick(0.1)
  local classes = require('core.classes')
  assert(classes.matchHint('endurance') == 'hint_car_a')
  assert(classes.matchHint('gt3') == '')
  assert(classes.matchHint('') == '')
  audit.tagFiles = nil
end)
test('torre identifica classe pela pilula e pelo tooltip', function()
  audit.grid(6) models[0] = 'mc_tower_a' models[1] = 'mc_tower_b'
  audit.tagFiles = { mc_tower_a = '{"tags":["Alpha"]}', mc_tower_b = '{"tags":["Beta"]}' }
  audit.store('ETV_mc1Enabled', true) audit.store('ETV_mc1Tag', 'Alpha') audit.store('ETV_mc1Color', '#FF0000')
  audit.store('ETV_mc2Enabled', true) audit.store('ETV_mc2Tag', 'Beta') audit.store('ETV_mc2Color', '#00FF00')
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  local classes = require('core.classes')
  local a, b = classes.get(0).color, classes.get(1).color
  assert(math.abs(a.r - b.r) + math.abs(a.g - b.g) > 0.5, 'Classes distintas precisam de cores distintas')
  audit.render(def('TV Tower'))
  audit.clickId, audit.hoverId = nil, '##race_tv_focus_0'
  audit.paint(def('TV Tower'))
  assert(audit.tooltip and audit.tooltip:find('MC1 ALPHA', 1, true), 'Tooltip deveria trazer a classe')
  audit.clickId, audit.hoverId = nil, nil
  audit.tagFiles = nil
  audit.store('ETV_mc1Enabled', false) audit.store('ETV_mc2Enabled', false)
  tick(0.1)
end)
test('linhas sem codigo de categoria, classe so na pilula e no tooltip', function()
  audit.grid(6) models[0] = 'cat_ferrari_gt3' models[1] = 'cat_ginetta_gt4' models[2] = 'cat_ferrari_gt3'
  audit.store('ETV_classFilter', false) audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  audit.render(def('TV Tower'))
  assert(not textHas('GT3') and not textHas('GT4') and not textHas('MC1'), 'Codigos de categoria deveriam sumir das linhas')
  audit.clickId, audit.hoverId = nil, '##race_tv_focus_0'
  audit.paint(def('TV Tower'))
  assert(audit.tooltip and audit.tooltip:find('GT3', 1, true), 'Tooltip deveria manter a classe')
  audit.clickId, audit.hoverId = nil, nil
end)
test('isolamento mostra so a categoria escolhida e rodape cicla com um clique', function()
  audit.grid(6) models[0] = 'iso_ferrari_gt3' models[1] = 'iso_ginetta_gt4' models[2] = 'iso_ferrari_gt3'
  models[3] = 'iso_ginetta_gt4' models[4] = 'iso_ferrari_gt3' models[5] = 'iso_ginetta_gt4'
  audit.store('ETV_classFilter', true) audit.store('ETV_classSelect', 'GT4')
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  audit.render(def('TV Tower'))
  local names = {}
  for _, text in ipairs(audit.texts) do if text.text:match('^PILOT_') then names[#names + 1] = text.text end end
  assert(#names == 3, 'Isolamento GT4 deveria mostrar 3 linhas, mostrou ' .. #names)
  local footer = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('GT4', 1, true) and text.text:find('INTERVALO', 1, true) then footer = true end
  end
  assert(footer, 'Rodape deveria indicar a categoria isolada')
  audit.clickId, audit.repeatClick = '##race_tv_classcycle', true
  local before = audit.storeWrites
  audit.paint(def('TV Tower')) audit.paint(def('TV Tower'))
  assert(require('core.config').get().classSelect ~= 'GT4', 'Clique no rodape deveria trocar a categoria')
  audit.clickId, audit.repeatClick = nil, false
  audit.store('ETV_classSelect', 'DESCONHECIDA') tick(0.1)
  for _ = 1, 5 do tick(0.1) end -- a janela real acompanha o resize no frame seguinte
  audit.render(def('TV Tower'))
  local all = 0
  for _, text in ipairs(audit.texts) do if text.text:match('^PILOT_') then all = all + 1 end end
  assert(all == 6, 'Categoria ausente deveria voltar a mostrar tudo')
  audit.store('ETV_classFilter', false) audit.store('ETV_classSelect', 'AUTO')
  tick(0.1)
end)
test('delta dedicado mostra live, previsao e barra sem resize no desenho', function()
  audit.grid(3) sim.focusedCar = 1
  cars[1].performanceMeter, cars[1].physicsAvailable = -0.35, true
  cars[1].isRemote, cars[1].isInPitlane = false, false
  for _ = 1, 15 do tick(0.1) end
  audit.render(def('TV Delta'))
  assert(textHas('DELTA') and textHas('LIVE'))
  local big = false
  for _, text in ipairs(audit.texts) do if text.text == '-0.350' then big = true end end
  assert(big, 'Delta live gigante ausente')
end)
test('relative mostra focado e vizinhos ordenados, com clique unico', function()
  audit.grid(6) sim.focusedCar = 2 audit.restart()
  for _ = 1, 25 do tick(0.1) end
  audit.render(def('TV Relative'))
  assert(textHas('RELATIVE') and textHas('FOCADO'))
  local gaps = {}
  for _, text in ipairs(audit.texts) do
    if text.text:match('^[+-]%d') then gaps[#gaps + 1] = text.text end
  end
  assert(#gaps >= 2, 'Vizinhos do focado ausentes')
  audit.clickId, audit.repeatClick = '##race_tv_rel_4', true
  local before = audit.focusChanges
  audit.paint(def('TV Relative')) audit.paint(def('TV Relative'))
  assert(sim.focusedCar == 4 and audit.focusChanges == before + 1)
  audit.clickId, audit.repeatClick = nil, false
end)
test('fuel mostra litros, consumo e autonomia, ou SEM DADOS', function()
  audit.grid(2) sim.focusedCar = 0
  cars[0].fuel, cars[0].maxFuel, cars[0].fuelPerLap = 30, 100, 2.5
  tick(0.1)
  audit.render(def('TV Fuel'))
  assert(textHas('FUEL') and textHas('30.0'))
  local autonomy = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('AUTONOMIA 12.0', 1, true) then autonomy = true end
  end
  assert(autonomy)
  cars[0].maxFuel = 0 tick(0.1)
  audit.render(def('TV Fuel'))
  assert(textHas('SEM DADOS'))
end)
test('session e flags cobrem verde, amarelo e quadriculada', function()
  audit.grid(6) tick(0.1)
  sim.raceFlagType = 1 tick(0.1)
  audit.render(def('TV Session'))
  assert(textHas('GREEN'))
  audit.render(def('TV Flags'))
  assert(textHas('GREEN'))
  sim.raceFlagType = ac.FlagType.Caution tick(0.1)
  audit.render(def('TV Flags'))
  assert(textHas('YELLOW'))
  sim.isSessionFinished = true tick(0.1)
  audit.render(def('TV Session'))
  assert(textHas('CHEQUERED'))
  audit.render(def('TV Flags'))
  assert(textHas('CHEQUERED'))
  sim.isSessionFinished, sim.raceFlagType = false, 0
end)
test('pacote de serie aplica cor e titulo juntos', function()
  audit.grid(3) tick(0.1)
  local cfg = require('core.config')
  audit.radioClick = 'WEC Azul'
  audit.render(def('TV Settings'))
  assert(cfg.get().preset == 4 and cfg.get().series == 'WEC')
  assert(cfg.get().brand1.b > cfg.get().brand1.r)
  audit.radioClick = 'IMSA Vermelho'
  audit.render(def('TV Settings'))
  assert(cfg.get().preset == 5 and cfg.get().series == 'IMSA')
  cfg.setPreset(1)
  assert(cfg.get().preset == 1)
end)
test('recorde da pista persiste entre sessoes e aparece nos resultados', function()
  audit.grid(3) audit.restart() tick(0.1)
  cars[0].isRaceFinished = true tick(0.1)
  cars[1].bestLapTimeMs = 88000 tick(0.2)
  local records = require('core.records')
  assert(records.ms == 88000, 'Recorde deveria registrar 88000')
  audit.restart() tick(0.1)
  assert(records.ms == 88000, 'Recorde deveria persistir entre sessoes')
  cars[0].isRaceFinished = true tick(0.1)
  audit.render(def('TV Results'))
  local found = false
  for _, text in ipairs(audit.texts) do if text.text:find('RECORDE', 1, true) then found = true end end
  assert(found, 'Linha de recorde ausente nos resultados')
  cars[2].bestLapTimeMs = 87000 tick(0.2)
  assert(records.ms == 87000, 'Recorde deveria melhorar para 87000')
end)
test('torre mostra o pneu de cada linha e respeita o interruptor', function()
  audit.grid(6) compounds[0] = 'S'
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  require('core.config').setTowerMode(1)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  audit.render(def('TV Tower'))
  local found = false
  for _, text in ipairs(audit.texts) do
    if text.text == 'S' and text.x and text.x >= 200 then found = true end
  end
  assert(found, 'Letra do pneu ausente na coluna da torre')
  require('core.config').set('showTyre', false) tick(0.1)
  audit.render(def('TV Tower'))
  found = false
  for _, text in ipairs(audit.texts) do
    if text.text == 'S' and text.x and text.x >= 200 then found = true end
  end
  assert(not found, 'Pneu deveria sumir com showTyre desligado')
  require('core.config').set('showTyre', true) tick(0.1)
end)
test('battle e onboard exibem classe e pneu do piloto', function()
  audit.grid(6) models[0] = 'pol_ferrari_gt3' models[1] = 'pol_ferrari_gt3'
  compounds[0], compounds[1] = 'S', 'S'
  audit.restart()
  local control = require('core.control')
  control.choose('A', 0) control.choose('B', 1)
  for _ = 1, 20 do tick(0.1) end
  audit.render(def('TV Battle'))
  local stats = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('GT3', 1, true) and text.text:sub(-1) == 'S' then stats = true end
  end
  assert(stats, 'Linha de comparacao deveria trazer classe e pneu')
  sim.focusedCar = 0 tick(0.1)
  audit.render(def('TV Onboard Top'))
  local team = false
  for _, text in ipairs(audit.texts) do
    if text.text:find('GT3', 1, true) then team = true end
  end
  assert(team, 'Barra onboard deveria trazer o codigo da classe')
end)
test('torre vazia mostra placeholder em vez de janela em branco', function()
  audit.grid(0) audit.restart() tick(0.1)
  audit.render(def('TV Tower'))
  assert(textHas('AGUARDANDO CARROS'))
end)
test('torre estilo CMRT: volta, intervalo e ultima volta por linha', function()
  audit.grid(6) sim.focusedCar = 0
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.store('ETV_classFilter', false)
  require('core.config').setTowerMode(2)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  audit.render(def('TV Tower'))
  assert(textHas('L3'), 'Coluna de volta ausente')
  assert(textHas('1:32.000'), 'Coluna de ultima volta ausente')
  assert(audit.windows['TV Tower'].w == 400, 'Torre deveria ter 400 de largura')
end)
test('delta de posicao mostra numero e codigos de classe sumiram das linhas', function()
  audit.grid(6) models[0] = 'cmrt_ferrari_gt3' models[1] = 'cmrt_ginetta_gt4'
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.store('ETV_classFilter', false)
  require('core.config').setTowerMode(2)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  cars[5].racePosition, cars[0].racePosition = 1, 6
  tick(0.2) tick(0.2)
  audit.render(def('TV Tower'))
  assert(textHas('▲5') and textHas('▼5'), 'Seta deveria trazer o numero de posicoes')
  assert(not textHas('MC1') and not textHas('GT3') and not textHas('GT4'), 'Codigos de classe deveriam sumir das linhas')
  require('core.config').setTowerMode(1)
end)
test('real penalty via chat: selo na torre, alerta e limpeza ao cumprir', function()
  audit.grid(6) sim.focusedCar = 0
  audit.store('ETV_towerRows', 6) audit.store('ETV_scale', 1)
  audit.restart()
  for _ = 1, 10 do tick(0.1) end
  local rp = require('core.rp')
  assert(rp.penalty(2) == nil)
  audit.chat('RP: PILOT_03 - DRIVE THROUGH')
  tick(0.1)
  local pen = rp.penalty(2)
  assert(pen and pen.kind == 'DT' and pen.label == 'DT')
  audit.render(def('TV Tower'))
  assert(textHas('DT'), 'Selo DT ausente na torre')
  tick(0.1) -- segundo update: alerta sai da fila e o fade passa de zero
  audit.render(def('TV Alert'))
  assert(textHas('RP PENALIDADE'), 'Alerta de punicao ausente')
  cars[2].isInPitlane = true tick(0.2)
  cars[2].isInPitlane = false tick(0.2)
  assert(rp.penalty(2) == nil, 'DT deveria limpar apos cruzar o pitlane')
end)
test('real penalty: aviso, stop-go com segundos e safety car na bandeira', function()
  audit.grid(6) audit.restart()
  for _ = 1, 10 do tick(0.1) end
  local rp = require('core.rp')
  audit.chat('RP: PILOT_04 - CUT WARNING 2/5')
  tick(0.1)
  local warn = rp.penalty(3)
  assert(warn and warn.kind == 'WARN' and warn.label == 'W2')
  audit.chat('RP: PILOT_05 - STOP & GO 10')
  tick(0.1)
  local sg = rp.penalty(4)
  assert(sg and sg.kind == 'SG' and sg.label == 'SG10')
  audit.chat('Hello everyone, nice race!')
  tick(0.1)
  assert(rp.penalty(0) == nil and rp.penalty(1) == nil and rp.penalty(5) == nil)
  audit.chat('RP: SAFETY CAR DEPLOYED')
  tick(0.1)
  audit.render(def('TV Flags'))
  assert(textHas('SAFETY CAR'), 'Safety car do RP ausente nas bandeiras')
  audit.chat('RP: UNKNOWN DRIVER XYZ - DRIVE THROUGH')
  for _ = 1, 65 do tick(0.1) end -- safety car anterior (5.6s) sai da fila antes
  audit.render(def('TV Alert'))
  assert(textHas('RP PENALIDADE'), 'Penalidade sem piloto deveria ao menos alertar')
end)
test('real penalty some ao trocar de sessao e ignora sem listener', function()
  audit.grid(3) audit.restart() tick(0.1)
  local rp = require('core.rp')
  audit.chat('RP: PILOT_02 - DRIVE THROUGH')
  tick(0.1)
  assert(rp.penalty(1) ~= nil)
  audit.restart() tick(0.1)
  assert(rp.penalty(1) == nil and rp.flag == nil)
end)
audit.release()
