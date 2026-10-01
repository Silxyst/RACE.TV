-- Operator panel: real window, manual focus, favorites and comparison selection.
local M = {}
local config, draw, control = require('core.config'), require('core.draw'), require('core.control')
function M.init() end
function M.update() end
function M.on_open() end
function M.on_close() end
function M.on_session_start() end
function M.main()
  local sim = ac.getSim()
  if not sim then return end
  local cfg, k = config.get(), config.get().scale
  local W, H = 430 * k, 430 * k
  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1)
  draw.textF(draw.FONT_HEAD, 14*k, 8*k, 'PAINEL DO NARRADOR', 19*k, draw.WHITE, ui.Alignment.Start, W-28*k, 26*k)
  local driver = require('core.drivers').name(sim.focusedCar)
  local leaderGap = require('core.native').text(sim.focusedCar)
  if leaderGap then driver = driver .. '  ·  ' .. leaderGap end
  draw.textF(draw.FONT_TXT, 14*k, 37*k, driver ~= '' and ('ATUAL: ' .. driver) or 'SEM PILOTO', 12*k, draw.GRAY,
    ui.Alignment.Start, W-28*k, 22*k)
  local function action(id, label, x, y, w, callback)
    if draw.action('narrator_' .. id, label, x*k, y*k, w*k, 28*k, cfg.brand1, k) then
      control.command('narrator_' .. id, callback)
    end
  end
  action('leader', 'LÍDER', 14, 68, 128, control.leader)
  action('previous', 'ANTERIOR', 151, 68, 128, function() control.adjacent(-1) end)
  action('next', 'PRÓXIMO', 288, 68, 128, function() control.adjacent(1) end)
  action('favorite', control.isFavorite(sim.focusedCar) and 'REMOVER FAVORITO' or 'FAVORITAR ATUAL', 14, 105, 197,
    function() control.toggleFavorite(sim.focusedCar) end)
  action('nextfavorite', 'PRÓXIMO FAVORITO', 219, 105, 197, control.nextFavorite)
  draw.textF(draw.FONT_HEAD, 14*k, 143*k, 'COMPARAÇÃO MANUAL', 13*k, draw.WHITE, ui.Alignment.Start, W-28*k, 22*k)
  local a, b = control.slot('A'), control.slot('B')
  draw.textF(draw.FONT_TXT, 14*k, 170*k, 'A: ' .. (a and require('core.drivers').name(a.idx) or 'Escolha um piloto'), 12*k,
    draw.GRAY, ui.Alignment.Start, W-28*k, 20*k)
  draw.textF(draw.FONT_TXT, 14*k, 195*k, 'B: ' .. (b and require('core.drivers').name(b.idx) or 'Escolha outro piloto'), 12*k,
    draw.GRAY, ui.Alignment.Start, W-28*k, 20*k)
  action('a', 'ATUAL → A', 14, 225, 128, function() control.choose('A', sim.focusedCar) end)
  action('b', 'ATUAL → B', 151, 225, 128, function() control.choose('B', sim.focusedCar) end)
  action('clear', 'LIMPAR DUPLA', 288, 225, 128, control.clearComparison)
  action('results', 'RESULTADOS', 14, 263, 197, function()
    require('core.layouts').showWindow('TV Results')
  end)
  action('layout', 'PRÓXIMO LAYOUT', 219, 263, 197, function() require('core.layouts').cycle() end)
  draw.textF(draw.FONT_HEAD, 14*k, 302*k, 'FAVORITOS CONECTADOS', 13*k, draw.WHITE, ui.Alignment.Start, W-28*k, 22*k)
  local list = control.favoriteRows()
  for i = 1, math.min(3, #list) do
    local row = list[i]
    action('fav_' .. row.idx, 'P' .. row.pos .. '  ' .. require('core.drivers').name(row.idx), 14, 330 + (i-1)*30, 402,
      function() control.focus(row.idx) end)
  end
  if #list == 0 then draw.textF(draw.FONT_TXT, 14*k, 330*k, 'Favorite um piloto para acesso rápido.', 12*k,
    draw.GRAY, ui.Alignment.Start, W-28*k, 24*k) end
  ui.popClipRect()
end
return M
