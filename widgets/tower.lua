-- RACE TV v10 // Timing Tower em glass broadcast com linhas animadas.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim, data = require('core.anim'), require('core.data')
local classes, tyres, pits = require('core.classes'), require('core.tyres'), require('core.pits')
local time, intro = 0, 0
local rowY, previous, arrows, identities = {}, {}, {}, {}
local modeButton
local frame, frameSerial, lastClickFrame, lastCycleFrame = nil, 0, -1, -1

function M.init() modeButton = ac.ControlButton('TV_TOWER_MODE') end
-- Only session start plays the full-card intro. Native size/layer show events
-- must never blank an already running tower.
function M.on_open() end
function M.on_close() end
function M.on_session_start()
  rowY, previous, arrows, identities = {}, {}, {}, {}
  time, intro, frame, lastClickFrame, lastCycleFrame = 0, 0, nil, -1, -1
end

local function buildView(cfg, sim, capacity)
  -- Effective filter: chosen category, focused driver's category (AUTO) or all.
  local sel = cfg.classSelect or 'AUTO'
  local focusKey = classes.get(sim.focusedCar).key
  local picked = nil
  if cfg.classFilter and sel ~= 'TODAS' then
    picked = (sel == 'AUTO' or sel == '') and focusKey or sel
    if picked ~= focusKey then
      local present = false
      for _, e in ipairs(data.list) do
        if classes.get(e.idx).key == picked then present = true break end
      end
      if not present then picked = nil end
    end
  end
  local list = {}
  for _, e in ipairs(data.list) do
    if not picked or classes.get(e.idx).key == picked then list[#list + 1] = e end
  end
  local category = picked or 'TODAS'
  if #list == 0 then return list, list, 1, 0, category end
  local rows = math.min(cfg.towerRows, capacity, #list)
  local fixed, rest = { list[1] }, {}
  local focus = data.byIndex[sim.focusedCar]
  if focus and focus.idx ~= list[1].idx and (not picked or classes.get(focus.idx).key == picked) then fixed[#fixed + 1] = focus end
  for _, e in ipairs(list) do
    if e.idx ~= fixed[1].idx and (not fixed[2] or e.idx ~= fixed[2].idx) then rest[#rest + 1] = e end
  end
  local pages, page, view = 1, 0, list
  if #list > rows then
    local perPage = rows - #fixed
    pages = math.ceil(#rest / perPage)
    page = math.floor(time / 8) % pages
    -- A short final page uses an overlapping final range: no shrinking window,
    -- duplicate rows, blank slots or repeated intro when the page rotates.
    local start = math.min(page * perPage + 1, #rest - perPage + 1)
    view = {}
    for _, e in ipairs(fixed) do view[#view + 1] = e end
    for i = start, start + perPage - 1 do view[#view + 1] = rest[i] end
    table.sort(view, function(a, b) return a.rank < b.rank end)
  end
  return list, view, pages, page, category
end

function M.update(dt)
  frameSerial = frameSerial + 1
  time = time + dt
  intro = math.min(1, intro + dt * 2.6)
  if modeButton and modeButton:pressed() then config.setTowerMode(config.get().towerMode % 4 + 1) end
  local drivers = require('core.drivers')
  for _, e in ipairs(data.list) do
    local key = drivers.key(e.idx)
    if identities[e.idx] ~= key then
      identities[e.idx], previous[e.idx], rowY[e.idx], arrows[e.idx] = key, e.pos, nil, nil
    elseif previous[e.idx] and previous[e.idx] ~= e.pos then
      arrows[e.idx] = { up = e.pos < previous[e.idx], n = math.abs(e.pos - previous[e.idx]), untilTime = time + 5 }
      previous[e.idx] = e.pos
    end
  end
  for idx in pairs(previous) do
    if not data.byIndex[idx] then previous[idx], rowY[idx], arrows[idx], identities[idx] = nil, nil, nil, nil end
  end
  local sim = ac.getSim()
  if sim then
    local cfg = config.get()
    local scale = draw.fit(cfg.scale)
    local screen = require('core.screen').size()
    local heightBudget = math.max(166, (screen.y - 12) / scale)
    -- Compact vertical padding when necessary; width and font scale stay equal
    -- to the rest of the HUD. Small viewports paginate instead of shrinking.
    local envH = cfg.showEnv and 22 or 0
    local pitch = math.max(22, math.min(30, (heightBudget - 86 - envH) / cfg.towerRows))
    pitch = math.floor(pitch * 2) / 2
    local capacity = math.max(3, math.floor((heightBudget - 86 - envH) / pitch))
    local screenRows = math.min(cfg.towerRows, capacity)
    local actual = require('core.winsize').actual('TV Tower')
    local fullRows = math.min(cfg.towerRows, capacity)
    if actual and actual.y >= 120 then
      -- CSP clamped the window: paginate into what really fits instead of
      -- drawing cut rows. The full size keeps being requested (M.size).
      local fitRows = math.floor((actual.y / scale - 86 - envH) / pitch)
      if fitRows >= 3 and fitRows < fullRows
        and actual.y < (86 + envH + fullRows * pitch) * scale - 2 then
        capacity = fitRows
      end
    end
    local list, view, pages, page, category = buildView(cfg, sim, capacity)
    if #view == 0 and #list > 0 then view = list end
    local fullHeight = 86 + envH + math.min(#list, screenRows) * pitch
    local height = 86 + envH + #view * pitch
    frame = { list = list, view = view, pages = pages, page = page,
      category = category, scale = scale, height = height, pitch = pitch,
      mode = cfg.towerMode, envH = envH, fullHeight = fullHeight }
    for r, e in ipairs(view) do
      local target = (r - 1) * pitch
      rowY[e.idx] = anim.damp(rowY[e.idx] or target, target, 9, dt)
    end
  else frame = nil end
end

function M.size(cfg)
  if frame and frame.fullHeight then return 400, frame.fullHeight end
  return 400, 86 + (cfg.showEnv and 22 or 0) + cfg.towerRows * 30
end

function M.main()
  local cfg, sim = config.get(), ac.getSim()
  if not sim then return end
  if not frame or #frame.view == 0 then
    if #data.list > 0 then return end
    local k = cfg.scale
    local W, H = 320 * k, (86 + (cfg.showEnv and 22 or 0) + cfg.towerRows * 30) * k
    ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
    draw.card(0, 0, W, H, cfg.brand1, 1)
    draw.textF(draw.FONT_HEAD, 0, H / 2 - 22 * k, 'AGUARDANDO CARROS', 18 * k,
      draw.WHITE, ui.Alignment.Center, W, 28 * k)
    draw.textF(draw.FONT_TXT, 0, H / 2 + 8 * k, cfg.series, 11 * k,
      draw.fade(draw.PHIL_GRAY, 1), ui.Alignment.Center, W, 20 * k)
    ui.popClipRect()
    return
  end
  local focused = sim.focusedCar
  local list, view, pages, page, category = frame.list, frame.view, frame.pages, frame.page, frame.category

  local n, mode = #view, frame.mode
  local k = frame.scale
  local W, H = 400 * k, frame.height * k
  local headH, rowH, footH = (62 + frame.envH) * k, frame.pitch * k, 24 * k
  local p = anim.ease_out_quart(intro)
  local alpha = p

  local sBest
  for _, e in ipairs(data.list) do
    local best = e.car.bestLapTimeMs
    if best > 0 and (not sBest or best < sBest) then sBest = best end
  end

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)

  -- header: série + sessão/clock
  local caution = sim.raceFlagType == ac.FlagType.Caution
  local hasLogo = draw.logo(12*k, 6*k, 28*k, 28*k, alpha)
  draw.textF(draw.FONT_HEAD, (hasLogo and 46 or 12) * k, 6 * k, cfg.series, 23 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Center, W - (hasLogo and 58 or 24) * k, 28 * k)
  local sessTxt = draw.sessionLabel(sim)
  local clockTxt = draw.sessionClock(sim)
  local sess = ac.getSession(sim.currentSessionIndex or 0)
  local lapTotal = (sess and sess.laps) or 0
  if not data.quali(sim) and lapTotal > 0 then
    clockTxt = string.format('%d/%d', math.min(list[1].car.lapCount + 1, lapTotal), lapTotal)
  end
  local caption = clockTxt
  local capColor = draw.WHITE
  if caution then
    local blink = math.floor(time * 1.5) % 2 == 0
    caption = blink and 'YELLOW FLAG' or clockTxt
    capColor = blink and draw.PHIL_BG or draw.WHITE
    ui.drawRectFilled(vec2(8 * k, 36 * k), vec2(W - 8 * k, 56 * k),
      blink and draw.fade(draw.YELLOW, alpha) or rgbm(1, 1, 1, 0.06 * alpha), 5)
  end
  draw.textF(draw.FONT_TXT, 14 * k, 37 * k, sessTxt, 11 * k, draw.fade(draw.dim(1), alpha),
    ui.Alignment.Start, 130 * k, 18 * k)
  draw.textF(draw.FONT_HEAD, W - 144 * k, 37 * k, caption, 12 * k, draw.fade(capColor, alpha),
    ui.Alignment.End, 130 * k, 18 * k)
  -- faixa de ambiente: bandeira + grip/temperaturas/hora local
  if frame.envH > 0 then
    local env = require('core.env')
    local flag, style = env.flag()
    draw.flagPill(12*k, 62*k, 108*k, 18*k, flag, style, alpha)
    local strip = env.strip()
    if strip then
      draw.textF(draw.FONT_TXT, 128*k, 62*k, strip, 10*k, draw.fade(draw.PHIL_GRAY, alpha),
        ui.Alignment.Start, W - 140*k, 18*k)
    end
  end
  -- progresso da sessão
  local elapsed, left = math.max(0, sim.currentSessionTime), math.max(0, sim.sessionTimeLeft)
  local lap0 = list[1].car.lapCount or 0
  local frac = 0
  if not data.quali(sim) and lapTotal > 0 then frac = lap0 / lapTotal
  elseif elapsed + left > 0 then frac = elapsed / (elapsed + left) end
  local barY = (60 + frame.envH) * k
  ui.drawRectFilled(vec2(12 * k, barY), vec2(12 * k + (W - 24 * k) * draw.clamp(frac, 0, 1), barY + 2 * k),
    rgbm(1, 1, 1, 0.45 * alpha))

  -- linhas
  local showBest = mode == 3 or (mode == 1 and data.quali(sim))
  local hitAreas = {}
  ui.pushClipRect(vec2(0, headH), vec2(W, headH + n * rowH), true)
  for r, e in ipairs(view) do
    local car = e.car
    local target = (r - 1) * frame.pitch
    local ry = rowY[e.idx] or target
    local y = headH + ry * k
    local hitTop = math.max(headH, y + 2 * k)
    local hitBottom = math.min(headH + n * rowH, y + rowH - 2 * k)
    if hitBottom - hitTop > 2 and alpha > 0.25 then
      hitAreas[#hitAreas + 1] = { idx = e.idx, name = ac.getDriverName(e.idx) or 'Piloto',
        x = 6 * k, y = hitTop, w = W - 12 * k, h = hitBottom - hitTop }
    end
    local isFoc = (e.idx == focused)
    local isP1 = e.idx == list[1].idx
    local white = isP1 or isFoc
    local ink = white and draw.PHIL_BG or draw.WHITE
    if isFoc then
      ui.drawRectFilled(vec2(6 * k, y + 2 * k), vec2(W - 6 * k, y + rowH - 2 * k),
        rgbm(1, 1, 1, 0.94 * alpha), 6)
      ui.drawRect(vec2(6 * k + 0.5, y + 2 * k + 0.5), vec2(W - 6 * k - 0.5, y + rowH - 2 * k - 0.5),
        draw.fade(cfg.brand1, alpha))
    elseif isP1 then
      ui.drawRectFilled(vec2(6 * k, y + 2 * k), vec2(W - 6 * k, y + rowH - 2 * k),
        rgbm(1, 1, 1, 0.94 * alpha), 6)
    else
      ui.drawRectFilled(vec2(6 * k, y + 2 * k), vec2(W - 6 * k, y + rowH - 2 * k),
        rgbm(1, 1, 1, (r % 2 == 0 and 0.05 or 0.025) * alpha), 6)
    end
    -- posição única 1..N em pílula na cor da classe (identificação multiclass)
    local cc = classes.get(e.idx).color
    local lum = 0.299 * cc.r + 0.587 * cc.g + 0.114 * cc.b
    local posInk = lum > 0.6 and draw.PHIL_BG or draw.WHITE
    local posBox = white and draw.PHIL_BG or cc
    draw.pill(4 * k, y + 3 * k, 26 * k, rowH - 6 * k, draw.fade(posBox, alpha))
    draw.textF(draw.FONT_NUM, 4 * k, y, e.rank or e.pos, 15 * k, draw.fade(white and draw.WHITE or posInk, alpha),
      ui.Alignment.Center, 26 * k, rowH)
    local arrow = arrows[e.idx]
    if arrow and arrow.untilTime > time then
      local a = math.min(1, (arrow.untilTime - time) / 0.4)
      draw.textF(draw.FONT_HEAD, 31 * k, y + 4 * k,
        (arrow.up and '▲' or '▼') .. (arrow.n and arrow.n > 0 and arrow.n or ''), 9 * k,
        rgbm(arrow.up and 0.1 or 1, arrow.up and 0.85 or 0.3, arrow.up and 0.4 or 0.35, a * alpha),
        ui.Alignment.Start, 13 * k, 16 * k)
    end
    -- marca
    local okC, cn = pcall(ac.getCarName, e.idx)
    local initial = '·'
    if okC and cn and #tostring(cn) > 0 then initial = draw.truncate(cn, 1):upper() end
    local number = require('core.branding').driver(e.idx)
    if number ~= '' then initial = number end
    local boxC = white and draw.PHIL_BG or draw.driverColor(e.idx)
    draw.pill(46 * k, y + 6 * k, 18 * k, rowH - 12 * k, draw.fade(boxC, alpha))
    draw.textF(draw.FONT_HEAD, 46 * k, y + 6 * k, initial, 11 * k, draw.fade(draw.WHITE, alpha),
      ui.Alignment.Center, 18 * k, rowH - 12 * k)
    -- nome com clip anti-sobreposição (sem código de categoria na linha)
    local nameEnd = W - 200 * k
    ui.pushClipRect(vec2(68 * k, y), vec2(nameEnd, y + rowH), true)
    local okN, nm = pcall(ac.getDriverName, e.idx)
    local dname = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 20) or '---'
    draw.textF(draw.FONT_BOLD, 68 * k, y, dname, 13 * k, draw.fade(ink, alpha),
      ui.Alignment.Start, nameEnd - 68 * k - 4 * k, rowH)
    ui.popClipRect()
    -- pneu da linha (todas as classes, todos os modos exceto TYRE detalhado)
    local miniTyre = cfg.showTyre and mode ~= 4 and not status
    if miniTyre then
      local letter = tyres.get(e.idx)
      ui.drawCircleFilled(vec2(W - 192 * k, y + rowH / 2), 4 * k, draw.fade(draw.tyreColor(letter), alpha), 10)
      draw.textF(draw.FONT_SEMI, W - 184 * k, y, letter, 11 * k, draw.fade(ink, alpha),
        ui.Alignment.Start, 20 * k, rowH)
    end
    -- volta atual do piloto (selo de punição do Real Penalty tem prioridade)
    local pen = require('core.rp').penalty(e.idx)
    if pen then
      local pcol = pen.kind == 'WARN' and draw.YELLOW or draw.RED
      draw.pill(W - 162 * k, y + 5 * k, 30 * k, rowH - 10 * k, draw.fade(pcol, alpha))
      local plum = 0.299 * pcol.r + 0.587 * pcol.g + 0.114 * pcol.b
      draw.textF(draw.FONT_HEAD, W - 162 * k, y + 5 * k, pen.label, 10 * k,
        draw.fade(plum > 0.6 and draw.PHIL_BG or draw.WHITE, alpha),
        ui.Alignment.Center, 30 * k, rowH - 10 * k)
    else
      local lapCount = car.lapCount or 0
      local lapNum = (car.isRaceFinished and lapCount or lapCount + 1)
      if type(lapNum) ~= 'number' or lapNum < 1 then lapNum = 1 end
      draw.textF(draw.FONT_SEMI, W - 162 * k, y, 'L' .. lapNum, 11 * k, draw.fade(ink, alpha),
        ui.Alignment.End, 30 * k, rowH)
    end
    -- direita
    local status = nil
    if car.isRetired then status = 'DNF'
    elseif car.isInPit then status = 'PIT'
    elseif car.isInPitlane then status = 'PIT LANE' end
    if status then
      if status == 'PIT' then
        local st = pits.get(e.idx)
        draw.pill(W - 40 * k, y + 6 * k, 32 * k, rowH - 12 * k, draw.fade(draw.RED, alpha))
        draw.textF(draw.FONT_HEAD, W - 40 * k, y + 6 * k, st > 0 and ('P' .. st) or 'P', 11 * k,
          draw.fade(draw.WHITE, alpha), ui.Alignment.Center, 32 * k, rowH - 12 * k)
      else
        draw.textF(draw.FONT_SEMI, W - 70 * k, y, status, 11 * k, draw.fade(ink, alpha),
          ui.Alignment.End, 62 * k, rowH)
      end
    elseif mode == 4 then
      local letter, age = tyres.get(e.idx)
      local tc = draw.tyreColor(letter)
      ui.drawCircleFilled(vec2(W - 88 * k, y + rowH / 2), 4 * k, draw.fade(tc, alpha), 10)
      local st = pits.get(e.idx)
      draw.textF(draw.FONT_SEMI, W - 78 * k, y, letter .. (age and ' ' .. age .. 'L' or '') .. (st > 0 and '·' .. st .. 'S' or ''), 11.5 * k,
        draw.fade(ink, alpha), ui.Alignment.Start, 72 * k, rowH)
    elseif showBest then
      local b = car.bestLapTimeMs or 0
      local bc = draw.sectorColor(b, sBest, nil)
      if b <= 0 then bc = ink end
      draw.textF(draw.FONT_SEMI, W - 130 * k, y, draw.fmtLap(b), 12 * k, draw.fade(bc, alpha),
        ui.Alignment.End, 124 * k, rowH)
    else
      local gapStr = 'LEADER'
      if not isP1 then
        local front = data.list[e.rank - 1]
        if cfg.classFilter then
          for index, candidate in ipairs(list) do if candidate.idx == e.idx then front = list[index - 1] break end end
        end
        gapStr = data.gapText(front, e)
      end
      draw.textF(draw.FONT_SEMI, W - 130 * k, y, gapStr, 12 * k, draw.fade(ink, alpha),
        ui.Alignment.End, 60 * k, rowH)
      local last = car.previousLapTimeMs or 0
      local lc = draw.sectorColor(last, sBest, car.bestLapTimeMs)
      if last <= 0 then lc = ink end
      draw.textF(draw.FONT_SEMI, W - 68 * k, y, draw.fmtLap(last), 12 * k, draw.fade(lc, alpha),
        ui.Alignment.End, 62 * k, rowH)
    end
  end
  local clicked
  for _, hit in ipairs(hitAreas) do
    ui.setCursor(vec2(hit.x, hit.y))
    if ui.invisibleButton('##race_tv_focus_' .. hit.idx, vec2(hit.w, hit.h),
      ui.ButtonFlags.PressedOnClick + ui.ButtonFlags.NoNavFocus) then clicked = hit.idx end
    if ui.itemHovered() then
      ui.setMouseCursor(ui.MouseCursor.Hand)
      ui.drawRectFilled(vec2(hit.x, hit.y), vec2(hit.x + hit.w, hit.y + hit.h),
        rgbm(cfg.brand1.r, cfg.brand1.g, cfg.brand1.b, 0.16 * alpha))
      local leaderGap = require('core.native').text(hit.idx)
      local className = classes.get(hit.idx).name or ''
      ui.setTooltip('Clique para acompanhar ' .. hit.name
        .. (className ~= '' and ' · ' .. className or '')
        .. (leaderGap and (' · ' .. leaderGap) or ''))
      ui.drawRect(vec2(hit.x, hit.y), vec2(hit.x + hit.w, hit.y + hit.h), cfg.brand1)
    end
  end
  ui.popClipRect()

  -- rodapé (clique alterna a categoria isolada quando o filtro está ligado)
  local fy = headH + n * rowH
  ui.drawLine(vec2(12 * k, fy), vec2(W - 12 * k, fy), rgbm(1, 1, 1, 0.09 * alpha), 1)
  local ftxt = mode == 4 and 'PNEUS / PARADAS' or (showBest and 'MELHOR VOLTA' or 'INTERVALO')
  if cfg.classFilter then ftxt = category .. ' · ' .. ftxt end
  if pages > 1 then ftxt = ftxt .. '  ·  ' .. (page + 1) .. '/' .. pages end
  draw.textF(draw.FONT_TXT, 0, fy, ftxt, 10 * k, draw.fade(draw.dim(0.85), alpha),
    ui.Alignment.Center, W, footH)
  local cycleClicked = false
  if cfg.classFilter and alpha > 0.25 then
    ui.setCursor(vec2(0, fy))
    if ui.invisibleButton('##race_tv_classcycle', vec2(W, footH),
      ui.ButtonFlags.PressedOnClick + ui.ButtonFlags.NoNavFocus) then cycleClicked = true end
    if ui.itemHovered() then
      ui.setMouseCursor(ui.MouseCursor.Hand)
      ui.setTooltip('Categoria isolada: ' .. category .. ' — clique para trocar')
    end
  end
  ui.popClipRect()
  if cycleClicked and lastCycleFrame ~= frameSerial then
    lastCycleFrame = frameSerial
    local opts = { 'AUTO', 'TODAS' }
    for _, key in ipairs(classes.keys()) do opts[#opts + 1] = key end
    local current = cfg.classSelect or 'AUTO'
    local at = 1
    for i, key in ipairs(opts) do if key == current then at = i break end end
    config.set('classSelect', opts[at % #opts + 1])
  end
  -- Redirect/duplicate layers can traverse the same row again in this frame.
  -- Dispatch a user click at most once and re-check the connected driver.
  if clicked ~= nil and lastClickFrame ~= frameSerial then
    local car = ac.getCar(clicked)
    if car and car.isConnected and car.isActive then
      lastClickFrame = frameSerial
      ac.focusCar(clicked)
    end
  end
end
return M
