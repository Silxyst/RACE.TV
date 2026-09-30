-- ========================================
-- VELOCITY SLASH // core/config.lua
-- Config central com ac.storage (persiste entre sessoes)
-- ========================================
local M = {}

local function stored(key, def)
  local s = ac.storage('VS_' .. key, def)
  return s
end

local S = {
  channel   = stored('channel', 'MEU CANAL'),
  accent    = stored('accent', 1),        -- 1 cyan, 2 magenta, 3 lime, 4 orange
  scale     = stored('scale', 1.0),
  opacity   = stored('opacity', 0.92),
  towerRows = stored('towerRows', 10),
  showTyre  = stored('showTyre', true),
  showRadar = stored('showRadar', true),
  mph       = stored('mph', false),
}

local ACCENTS = {
  { r = 0.0,  g = 0.90, b = 1.0  },  -- cyan #00E5FF
  { r = 1.0,  g = 0.15, b = 0.65 },  -- magenta
  { r = 0.55, g = 1.0,  b = 0.15 },  -- lime
  { r = 1.0,  g = 0.55, b = 0.05 },  -- orange
}
local ACCENT_NAMES = { 'Cyan Stream', 'Magenta Pulse', 'Lime Volt', 'Orange Attack' }

function M.get()
  local accentIdx = S.accent:get() or 1
  if type(accentIdx) ~= 'number' then accentIdx = 1 end
  accentIdx = math.max(1, math.min(#ACCENTS, math.floor(accentIdx)))
  local a = ACCENTS[accentIdx]
  local scale = S.scale:get() or 1.0
  if type(scale) ~= 'number' then scale = 1.0 end
  scale = math.max(0.7, math.min(1.6, scale))
  local opacity = S.opacity:get() or 0.92
  if type(opacity) ~= 'number' then opacity = 0.92 end
  opacity = math.max(0.35, math.min(1.0, opacity))
  local rows = S.towerRows:get() or 10
  if type(rows) ~= 'number' then rows = 10 end
  rows = math.max(5, math.min(20, math.floor(rows)))
  return {
    channel = tostring(S.channel:get() or 'MEU CANAL'),
    accentIdx = accentIdx,
    accent = a,
    accentName = ACCENT_NAMES[accentIdx],
    scale = scale,
    opacity = opacity,
    towerRows = rows,
    showTyre = S.showTyre:get() ~= false,
    showRadar = S.showRadar:get() ~= false,
    mph = S.mph:get() == true,
  }
end

function M.settingsUI()
  ui.text('VELOCITY SLASH // Config da Live')
  ui.separator()

  local cfg = M.get()

  -- Nome do canal (assinatura correta CSP: newVal, changed = inputText)
  ui.text('Nome do canal (aparece no header e lower-third):')
  local cur = S.channel:get() or 'MEU CANAL'
  local newVal = ui.inputText('##vs_channel', cur)
  if type(newVal) == 'string' and #newVal > 0 and newVal ~= cur then
    S.channel:set(newVal:sub(1, 28))
  end

  -- Accent
  ui.text('Cor de destaque (identidade unica): ' .. (cfg.accentName or ''))
  for i, n in ipairs(ACCENT_NAMES) do
    if ui.radioButton(n, cfg.accentIdx == i) then S.accent:set(i) end
  end

  ui.separator()
  local s = cfg.scale
  local ns = ui.slider('##vs_scale', s, 0.7, 1.6, 'Escala global: %.2f')
  if ns ~= s then S.scale:set(ns) end

  local o = cfg.opacity
  local no = ui.slider('##vs_opacity', o, 0.35, 1.0, 'Opacidade fundo: %.2f')
  if no ~= o then S.opacity:set(no) end

  local r = cfg.towerRows
  local nr = ui.slider('##vs_rows', r, 5, 20, 'Linhas da Tower: %.0f')
  if nr ~= r then S.towerRows:set(math.floor(nr)) end

  local st = cfg.showTyre
  if ui.checkbox('Mostrar bolinha de pneu na Tower', st) then S.showTyre:set(not st) end

  local mph = cfg.mph
  if ui.checkbox('Velocidade em MPH (padrao KM/H)', mph) then S.mph:set(not mph) end

  ui.separator()
  ui.textWrapped('DICA OBS: posicione cada janela (VS Tower, VS Speed, etc) pelo Content Manager > Apps. Ative Sombra OFF. Capture o jogo via Game Capture. Cada widget e uma fonte separada dentro do jogo.')
  ui.textWrapped('Layout sugerido 16:9: Tower esquerda | Lap topo-direita | Speed inferior-direita | Pedals inferior-centro | Lower-Third inferior-esquerda | Radar acima do Speed.')
end

return M
