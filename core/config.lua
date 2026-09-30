-- ========================================
-- ENDURO TV // core/config.lua
-- Presets broadcast (WEC/IMSA/NLS). Sem nome de canal obrigatorio.
-- ========================================
local M = {}

local function stored(key, def)
  return ac.storage('ETV_' .. key, def)
end

local S = {
  preset    = stored('preset', 1),      -- 1 Race Red, 2 Enduro Blue, 3 NLS Green
  scale     = stored('scale', 1.0),
  towerRows = stored('towerRows', 8),
  showTyre  = stored('showTyre', true),
  mph       = stored('mph', false),
  series    = stored('series', 'RACE TV'),
  showTags  = stored('showTags', true),
  tagsAdjacent = stored('tagsAdjacent', false),
  pedalTags = stored('pedalTags', true),
  autoBattle = stored('autoBattle', true),
  autoDirector = stored('autoDirector', false),
  autoLayout = stored('autoLayout', false),
  towerMode = stored('towerMode', 1), -- 1 AUTO, 2 GAP, 3 BEST, 4 TYRE
  classFilter = stored('classFilter', false),
  sound = stored('sound', true),
}

local PRESETS = {
  { name = 'RACE RED (IMSA/WEC)',   c1 = { 225, 6, 0 },   c2 = { 140, 0, 0 } },
  { name = 'ENDURO BLUE (WEC)',     c1 = { 0, 110, 255 },  c2 = { 0, 60, 140 } },
  { name = 'NLS GREEN',             c1 = { 0, 180, 80 },   c2 = { 0, 100, 45 } },
}

function M.presetColor(idx)
  idx = math.max(1, math.min(#PRESETS, idx or 1))
  local p = PRESETS[idx]
  return rgbm.from0255(p.c1[1], p.c1[2], p.c1[3], 255),
         rgbm.from0255(p.c2[1], p.c2[2], p.c2[3], 255), p.name
end

function M.get()
  local pi = S.preset:get() or 1
  if type(pi) ~= 'number' then pi = 1 end
  pi = math.max(1, math.min(#PRESETS, math.floor(pi)))
  local c1, c2, pname = M.presetColor(pi)
  local sc = S.scale:get() or 1.0
  if type(sc) ~= 'number' then sc = 1.0 end
  sc = math.max(0.7, math.min(1.6, sc))
  local rows = S.towerRows:get() or 12
  if type(rows) ~= 'number' then rows = 12 end
  rows = math.max(5, math.min(20, math.floor(rows)))
  return {
    preset = pi, presetName = pname, brand1 = c1, brand2 = c2,
    scale = sc,
    towerRows = rows,
    showTyre = S.showTyre:get() ~= false,
    mph = S.mph:get() == true,
    series = tostring(S.series:get() or 'RACE TV'),
    showTags = S.showTags:get() ~= false,
    tagsAdjacent = S.tagsAdjacent:get() == true,
    pedalTags = S.pedalTags:get() ~= false,
    autoBattle = S.autoBattle:get() ~= false,
    autoDirector = S.autoDirector:get() == true,
    autoLayout = S.autoLayout:get() == true,
    towerMode = math.max(1, math.min(4, math.floor(S.towerMode:get() or 1))),
    classFilter = S.classFilter:get() == true,
    sound = S.sound:get() ~= false,
  }
end

function M.setTowerMode(m) S.towerMode:set(math.max(1, math.min(4, math.floor(m or 1)))) end

function M.settingsUI()
  ui.text('ENDURO TV // Broadcast Settings')
  ui.separator()
  local cfg = M.get()
  ui.text('Identidade da transmissao:')
  for i, p in ipairs(PRESETS) do
    if ui.radioButton(p.name, cfg.preset == i) then S.preset:set(i) end
  end
  ui.separator()
  ui.text('Rotulo da serie (ex: IMSA, WEC, NLS, LIGA):')
  local sv = ui.inputText('##etv_series', cfg.series)
  if type(sv) == 'string' and #sv > 0 and sv ~= cfg.series then
    S.series:set(sv:sub(1, 18):upper())
  end
  local sc = cfg.scale
  local ns = ui.slider('##etv_scale', sc, 0.7, 1.6, 'Escala: %.2f')
  if ns ~= sc then S.scale:set(ns) end
  local r = cfg.towerRows
  local nr = ui.slider('##etv_rows', r, 5, 20, 'Linhas Tower: %.0f')
  if nr ~= r then S.towerRows:set(math.floor(nr)) end
  if ui.checkbox('Tyre dot na Tower', cfg.showTyre) then S.showTyre:set(not cfg.showTyre) end
  if ui.checkbox('MPH (padrao KM/H)', cfg.mph) then S.mph:set(not cfg.mph) end
  if ui.checkbox('Tags acima dos carros (estilo PHIL TV)', cfg.showTags) then S.showTags:set(not cfg.showTags) end
  if ui.checkbox('Tags só ±1 posição (GT7 adjacency)', cfg.tagsAdjacent) then S.tagsAdjacent:set(not cfg.tagsAdjacent) end
  if ui.checkbox('Pedais THR/BRK sob as tags 3D', cfg.pedalTags) then S.pedalTags:set(not cfg.pedalTags) end
  if ui.checkbox('Auto-batalha: Battle segue a briga mais próxima (<1.2s)', cfg.autoBattle) then S.autoBattle:set(not cfg.autoBattle) end
  if ui.checkbox('Auto-director: assistindo segue a briga (10s)', cfg.autoDirector) then S.autoDirector:set(not cfg.autoDirector) end
  ui.separator()
  ui.text('Tower: coluna direita (tecla TV_TOWER_MODE alterna em jogo)')
  local modes = { 'AUTO (quali BEST, corrida GAP)', 'GAP', 'BEST', 'TYRE (composto·idade·stops)' }
  for i, n in ipairs(modes) do
    if ui.radioButton(n, cfg.towerMode == i) then S.towerMode:set(i) end
  end
  if ui.checkbox('Multiclasse: só a classe do focado', cfg.classFilter) then S.classFilter:set(not cfg.classFilter) end
  if ui.checkbox('Som nos alertas (fastest/PB/flag)', cfg.sound) then S.sound:set(not cfg.sound) end
  ui.separator()
  ui.text('Posicionamento automático (16:9, proporcional):')
  if ui.button('Aplicar layout agora') then
    local n = 0
    pcall(function() n = require('core.layout').apply() end)
    ac.debug('TV Layout', 'janelas movidas: ' .. tostring(n))
  end
  if ui.checkbox('Auto-layout ao iniciar sessão', cfg.autoLayout) then S.autoLayout:set(not cfg.autoLayout) end
  ui.separator()
  ui.textWrapped('Posicione no Content Manager > Apps: Tower esquerda, Onboard inferior-esquerda, Timing topo-direita, Telemetry inferior-direita. Estilo chapado igual TV — sem transparencia.')
end

return M
