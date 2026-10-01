-- Profiles persist normalized positions, visibility, common scale and tower rows.
-- Apply only in script.update; redirect layers remain owned by CSP Redirection.
local M = { names = { 'Corrida', 'Classificação', 'Replay', 'Vertical' }, status = '' }
local config, winsize = require('core.config'), require('core.winsize')
local current = ac.storage('ETV_layout_current', 'Corrida')
local windows, pendingName, pendingDefault, applying, shows = {}, nil, false, nil, {}
local function known(name)
  for _, value in ipairs(M.names) do if value == name then return true end end
  return false
end
function M.configure(definitions) windows = definitions end
function M.current() local name = current:get() return known(name) and name or 'Corrida' end
local function store(name) return ac.storage('ETV_layout_' .. name, '') end
local function defaults(name)
  local result = { scale = name == 'Vertical' and 0.85 or 1, rows = name == 'Replay' and 10 or 12, windows = {} }
  local coords = {
    ['TV Tower'] = { 0.015, 0.12 }, ['TV Battle'] = { 0.33, 0.8 },
    ['TV Telemetry'] = { 0.38, 0.025 }, ['TV Onboard Top'] = { 0.38, 0.11 },
    ['TV Alert'] = { 0.38, 0.17 }, ['TV Timing'] = { 0.825, 0.12 },
    ['TV Inputs'] = { 0.825, 0.32 }, ['TV Onboard Bar'] = { 0.015, 0.86 },
    ['TV Map'] = { 0.865, 0.5 }, ['TV Spotter'] = { 0.89, 0.76 },
    ['TV Lineup'] = { 0.32, 0.25 }, ['TV Results'] = { 0.32, 0.25 }, ['TV Narrator'] = { 0.42, 0.32 },
  }
  for _, entry in ipairs(windows) do
    local p = coords[entry.title] or { 0.1, 0.1 }
    local visible = entry.title ~= 'TV Results' and entry.title ~= 'TV Lineup' and entry.title ~= 'TV Spotter'
    if name == 'Classificação' then visible = visible and entry.title ~= 'TV Battle' and entry.title ~= 'TV Inputs' end
    if name == 'Replay' then visible = visible and entry.title ~= 'TV Timing' end
    if name == 'Vertical' then
      visible = entry.title == 'TV Tower' or entry.title == 'TV Telemetry' or entry.title == 'TV Onboard Bar'
        or entry.title == 'TV Alert' or entry.title == 'TV Narrator'
      p = { 0.015, entry.title == 'TV Tower' and 0.16 or (entry.title == 'TV Telemetry' and 0.025
        or (entry.title == 'TV Alert' and 0.11 or 0.86)) }
      if entry.title == 'TV Narrator' then p = { 0.6, 0.32 } end
    end
    result.windows[entry.title] = { x = p[1], y = p[2], visible = visible }
  end
  return result
end
local function finite(value) return value and value == value and math.abs(value) < math.huge end
local function load(name)
  local text = tostring(store(name):get() or '')
  local scale, rows = text:match('^([^|\n]+)|([^\n]+)')
  scale, rows = tonumber(scale), tonumber(rows)
  if not finite(scale) or not finite(rows) or scale < 0.7 or scale > 1.6 or rows < 5 or rows > 20 then return defaults(name) end
  local result, count = { scale = scale, rows = math.floor(rows), windows = {} }, 0
  for title, x, y, visible in text:gmatch('\n([^|\n]+)|([^|\n]+)|([^|\n]+)|([01])') do
    x, y = tonumber(x), tonumber(y)
    if finite(x) and finite(y) and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
      result.windows[title], count = { x = x, y = y, visible = visible == '1' }, count + 1
    end
  end
  if count == 0 then return defaults(name) end
  return result
end
function M.save(name)
  name = name or M.current()
  if not known(name) then return false end
  local cfg, screen = config.get(), require('core.screen').size()
  local lines = { string.format('%.2f|%d', cfg.scale, cfg.towerRows) }
  for _, entry in ipairs(windows) do
    local win = winsize.window(entry.title)
    if win then
      local p = win:position()
      local visible = win:visible()
      if win.redirectLayer2 then
        local ok, layer = pcall(function() return win:redirectLayer2() end)
        visible = visible or (ok and type(layer) == 'number' and layer > 0)
      end
      lines[#lines+1] = string.format('%s|%.6f|%.6f|%d', entry.title,
        math.max(0, math.min(1, p.x / screen.x)), math.max(0, math.min(1, p.y / screen.y)), visible and 1 or 0)
    end
  end
  local encoded, storage = table.concat(lines, '\n'), store(name)
  if storage:get() ~= encoded then storage:set(encoded) end
  M.status = 'Layout salvo: ' .. name
  return true
end
function M.request(name, useDefault)
  if not known(name) then return false end
  pendingName, pendingDefault = name, useDefault == true
  return true
end
function M.cycle()
  local name = pendingName or M.current()
  for i, value in ipairs(M.names) do if value == name then M.request(M.names[i % #M.names + 1]) return end end
end
function M.showWindow(title) shows[title] = true end
function M.beforeUpdate()
  if pendingName then
    local name = pendingName
    applying = { profile = pendingDefault and defaults(name) or load(name), done = {} }
    config.setValues({ scale = applying.profile.scale, towerRows = applying.profile.rows, autoLayout = false })
    current:set(name)
    M.status = 'Layout aplicado: ' .. name
    pendingName, pendingDefault = nil, false
  end
end
function M.afterUpdate()
  if applying then
    local complete = true
    local screen = require('core.screen').size()
    for _, entry in ipairs(windows) do
      local value = applying.profile.windows[entry.title]
      if value and not applying.done[entry.title] then
        local win = winsize.window(entry.title)
        if win then
          local size = winsize.size(entry.title)
          win:move(vec2(math.max(0, math.min(screen.x-size.x, value.x*screen.x)),
            math.max(0, math.min(screen.y-size.y, value.y*screen.y))))
          win:setVisible(value.visible)
          applying.done[entry.title] = true
        else complete = false end
      end
    end
    if complete then applying = nil end
  end
  for title in pairs(shows) do
    local win = winsize.window(title)
    if win then win:setVisible(true) shows[title] = nil end
  end
end
function M.settingsUI()
  ui.text('Layouts de transmissão')
  for _, name in ipairs(M.names) do
    if ui.radioButton('Layout: ' .. name, M.current() == name) then M.request(name) end
  end
  if ui.button('Salvar posições atuais neste perfil') then M.save() end
  if ui.button('Restaurar layout padrão deste perfil') then M.request(M.current(), true) end
  if M.status ~= '' then ui.text(M.status) end
  ui.textWrapped('Os perfis guardam posições, janelas, escala e linhas. Depois de aplicar um perfil, arraste as janelas e salve. Vertical organiza uma coluna para recorte na cena do OBS.')
end
return M
