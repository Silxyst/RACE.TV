local M = {}
local function stored(key, default) return ac.storage('ETV_' .. key, default) end
local S = {
  preset = stored('preset', 1), scale = stored('scale', 1), towerRows = stored('towerRows', 12),
  showTyre = stored('showTyre', true), mph = stored('mph', false), series = stored('series', 'RACE TV'),
  showTags = stored('showTags', true), tagsAdjacent = stored('tagsAdjacent', false),
  pedalTags = stored('pedalTags', true), autoBattle = stored('autoBattle', true),
  autoLayout = stored('autoLayout', true),
  towerMode = stored('towerMode', 1), classFilter = stored('classFilter', false), classSelect = stored('classSelect', 'AUTO'),
  sound = stored('sound', true), volume = stored('volume', 0.35),
  customColor = stored('customColor', false), red = stored('red', 225), green = stored('green', 6), blue = stored('blue', 0),
  logo = stored('logo', ''), showLogo = stored('showLogo', true), showEnv = stored('showEnv', true),
}
local cached
function M.refresh() cached = nil end
function M.set(key, value)
  if not S[key] then return false end
  if S[key]:get() ~= value then S[key]:set(value) cached = nil end
  return true
end
function M.setValues(values) for key, value in pairs(values) do M.set(key, value) end end
local presets = {
  { name = 'Race Red', rgb = { 225, 6, 0 } },
  { name = 'Enduro Blue', rgb = { 28, 55, 180 } },
  { name = 'NLS Green', rgb = { 0, 180, 80 } },
  { name = 'WEC Azul', rgb = { 0, 130, 200 }, series = 'WEC' },
  { name = 'IMSA Vermelho', rgb = { 200, 20, 40 }, series = 'IMSA' },
  { name = 'F1 Vermelho', rgb = { 225, 6, 0 }, series = 'F1' },
}
local function number(key, default, lo, hi)
  local n = tonumber(S[key]:get()) or default
  if n ~= n then n = default end
  return math.max(lo, math.min(hi, n))
end
function M.presetColor(index)
  local p = presets[math.max(1, math.min(#presets, math.floor(index or 1)))]
  local c = p.rgb
  return rgbm.from0255(c[1], c[2], c[3], 1), rgbm.from0255(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1), p.name
end
function M.get()
  if cached then return cached end
  local p = math.floor(number('preset', 1, 1, #presets))
  local c1, c2, name = M.presetColor(p)
  if S.customColor:get() == true then
    local r, g, b = number('red', 225, 0, 255), number('green', 6, 0, 255), number('blue', 0, 0, 255)
    c1, c2, name = rgbm.from0255(r, g, b, 1), rgbm.from0255(r*0.55, g*0.55, b*0.55, 1), 'Personalizado'
  end
  local cfg = {
    preset = p, presetName = name, brand1 = c1, brand2 = c2,
    scale = math.floor(number('scale', 1, 0.7, 1.6) * 100 + 0.5) / 100, towerRows = math.floor(number('towerRows', 12, 5, 20)),
    towerMode = math.floor(number('towerMode', 1, 1, 4)), volume = number('volume', 0.35, 0, 1),
    series = tostring(S.series:get() or 'RACE TV'),
    classSelect = require('core.draw').truncate(tostring(S.classSelect:get() or 'AUTO'), 40),
    logo = tostring(S.logo:get() or ''):match('^%s*(.-)%s*$'),
    red = number('red', 225, 0, 255), green = number('green', 6, 0, 255), blue = number('blue', 0, 0, 255),
    surface = rgbm(0.025 + c1.r * 0.055, 0.03 + c1.g * 0.055, 0.045 + c1.b * 0.075, 1),
  }
  for _, key in ipairs({ 'showTyre', 'showTags', 'pedalTags', 'autoBattle', 'sound', 'showLogo', 'showEnv' }) do cfg[key] = S[key]:get() ~= false end
  for _, key in ipairs({ 'mph', 'tagsAdjacent', 'autoLayout', 'classFilter', 'customColor' }) do cfg[key] = S[key]:get() == true end
  cached = cfg
  return cfg
end
function M.setPreset(index)
  index = math.floor(tonumber(index) or 1)
  index = math.max(1, math.min(#presets, index))
  M.set('preset', index)
  M.set('customColor', false)
  -- Series packs also brand the broadcast title.
  local series = presets[index].series
  if series then M.set('series', series) end
end
function M.setTowerMode(mode) M.set('towerMode', math.max(1, math.min(4, math.floor(tonumber(mode) or 1)))) end
local function check(label, key, cfg)
  if ui.checkbox(label, cfg[key]) then M.set(key, not cfg[key]) end
end
function M.settingsUI()
  local cfg = M.get()
  ui.text('RACE TV — Configurações')
  ui.separator()
  ui.text('Tema de cores do HUD')
  for i, p in ipairs(presets) do if ui.radioButton(p.name, cfg.preset == i) then M.setPreset(i) end end
  cfg = M.get() -- show a new selection immediately in this settings frame
  ui.textColored('Tema aplicado: ' .. cfg.presetName, cfg.brand1)
  local title = ui.inputText('Título da transmissão', cfg.series)
  if title ~= cfg.series and title ~= '' then M.set('series', require('core.draw').truncate(title, 28)) end
  M.set('scale', math.floor(ui.slider('Escala', cfg.scale, 0.7, 1.6, '%.2fx') * 100 + 0.5) / 100)
  M.set('towerRows', math.floor(ui.slider('Linhas da torre', cfg.towerRows, 5, 20, '%.0f')))
  ui.textWrapped('Cada janela ajusta o próprio tamanho ao conteúdo. Use o app OBS Apps Redirection do CSP para enviar janelas ao OBS (textura Extra: Redirected apps).')
  check('Posicionamento automático das janelas', 'autoLayout', cfg)
  if ui.button('Reposicionar janelas agora') then require('core.winsize').apply() end
  ui.separator()
  for i, mode in ipairs({ 'AUTO', 'GAP', 'BEST', 'TYRE' }) do if ui.radioButton(mode, cfg.towerMode == i) then M.setTowerMode(i) end end
  ui.text('Atalho para alternar a coluna da torre:')
  ac.ControlButton('TV_TOWER_MODE'):control()
  check('Indicador de pneu na torre', 'showTyre', cfg)
  check('Filtrar a categoria do piloto focado', 'classFilter', cfg)
  check('Velocidade em MPH', 'mph', cfg)
  check('Selecionar batalha automaticamente', 'autoBattle', cfg)
  check('Sons de avisos', 'sound', cfg)
  M.set('volume', ui.slider('Volume dos avisos', cfg.volume, 0, 1, '%.2f'))
  check('Tags dos carros', 'showTags', cfg)
  check('Tags somente de pilotos próximos na classificação', 'tagsAdjacent', cfg)
  check('Pedais progressivos abaixo das tags', 'pedalTags', cfg)
  ui.separator()
  ui.text('Painel do narrador: abra TV Narrator na barra de apps.')
  ui.text('Atalhos de controle manual:')
  for _, entry in ipairs(require('core.control').hotkeys) do
    ui.text(entry[2])
    ac.ControlButton(entry[1]):control()
  end
  ui.separator()
  require('core.layouts').settingsUI()
  ui.separator()
  ui.text('Identidade visual')
  check('Usar cor personalizada', 'customColor', cfg)
  cfg = M.get()
  if cfg.customColor then
    for _, entry in ipairs({ { 'Vermelho', 'red' }, { 'Verde', 'green' }, { 'Azul', 'blue' } }) do
      M.set(entry[2], math.floor(ui.slider(entry[1], cfg[entry[2]], 0, 255, '%.0f')))
    end
  end
  check('Mostrar logo da transmissão', 'showLogo', cfg)
  M.set('logo', ui.inputText('Logo PNG/JPG/DDS (caminho)', cfg.logo))
  if ui.button('Recarregar logo') then require('core.branding').reloadLogo() end
  ui.textWrapped('Caminho relativo à pasta Streamer Hud, por exemplo assets/logo.png, ou caminho absoluto.')
  if require('core.branding').logoStatus ~= '' then ui.text(require('core.branding').logoStatus) end
  require('core.branding').settingsUI()
  ui.separator()
  check('Faixa de ambiente na torre (bandeira, grip, temperaturas)', 'showEnv', cfg)
  ui.separator()
  require('core.classes').settingsUI()
end
return M
