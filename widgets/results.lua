local M = {}
local config, draw, results = require('core.config'), require('core.draw'), require('core.results')
local timer, slots = 0, 10
function M.init() end
function M.on_open() end
function M.on_close() end
function M.on_session_start() timer = 0 end
function M.update(dt)
  timer = timer + dt
  local cfg = config.get()
  slots = math.max(3, math.min(10, math.floor((require('core.screen').size().y / cfg.scale - 190) / 27)))
end
function M.size() return 680, 190 + slots * 27 end
function M.main()
  local cfg, k = config.get(), config.get().scale
  local W, H = 680*k, (190 + slots*27)*k
  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1)
  draw.logo(14*k, 7*k, 36*k, 36*k)
  draw.textF(draw.FONT_HEAD, 14*k, 7*k, 'RACE RESULTS', 26*k, draw.WHITE, ui.Alignment.Center, W-28*k, 36*k)
  if not results.available then
    draw.textF(draw.FONT_TXT, 14*k, 75*k, 'Resultados disponíveis ao final da corrida.', 14*k, draw.GRAY,
      ui.Alignment.Center, W-28*k, 36*k)
    ui.popClipRect() return
  end
  local rows = results.rows
  local pages = math.max(1, math.ceil(#rows / slots))
  local page = math.floor(timer / 8) % pages
  draw.textF(draw.FONT_TXT, 14*k, 44*k, cfg.series .. '  ·  ' .. (results.final and 'FINAL' or 'PROVISÓRIO')
    .. '  ·  ' .. (page+1) .. '/' .. pages, 11*k, draw.GRAY, ui.Alignment.Center, W-28*k, 20*k)
  for i = 1, math.min(3, #rows) do
    local row, x = rows[i], (14+(i-1)*220)*k
    draw.pill(x, 72*k, 212*k, 58*k, draw.fade(cfg.brand1, 0.3))
    draw.textF(draw.FONT_NUM, x+6*k, 74*k, 'P' .. i, 21*k, draw.WHITE, ui.Alignment.Start, 50*k, 28*k)
    draw.textF(draw.FONT_HEAD, x+60*k, 76*k, draw.fullName(row.name, 18), 13*k, draw.WHITE, ui.Alignment.Start, 146*k, 24*k)
    draw.textF(draw.FONT_TXT, x+6*k, 105*k, draw.truncate(row.team, 16) .. (row.number ~= '' and (' · #' .. row.number) or ''),
      10*k, draw.GRAY, ui.Alignment.Center, 200*k, 18*k)
  end
  draw.textF(draw.FONT_TXT, 14*k, 135*k, 'POS     PILOTO', 10*k, draw.GRAY, ui.Alignment.Start, 440*k, 20*k)
  draw.textF(draw.FONT_TXT, 466*k, 135*k, 'MELHOR VOLTA       STATUS', 10*k, draw.GRAY, ui.Alignment.End, 200*k, 20*k)
  local start = math.max(1, math.min(page*slots+1, #rows-slots+1))
  for slot = 1, slots do
    local row = rows[start+slot-1]
    if row then
      local y = (159+(slot-1)*27)*k
      ui.drawRectFilled(vec2(10*k, y), vec2(W-10*k, y+25*k), rgbm(1, 1, 1, slot%2 == 0 and 0.05 or 0.025), 4)
      draw.textF(draw.FONT_NUM, 14*k, y, start+slot-1, 13*k, draw.WHITE, ui.Alignment.Center, 34*k, 25*k)
      draw.textF(draw.FONT_BOLD, 58*k, y, draw.fullName(row.name, 35), 13*k, draw.WHITE, ui.Alignment.Start, 388*k, 25*k)
      draw.textF(draw.FONT_SEMI, 450*k, y, draw.fmtLap(row.best), 12*k, draw.WHITE, ui.Alignment.End, 100*k, 25*k)
      draw.textF(draw.FONT_TXT, 554*k, y, row.status == 'RUNNING' and ('L' .. row.laps) or row.status, 10*k,
        row.status == 'DNF' and draw.RED or draw.GRAY, ui.Alignment.End, 112*k, 25*k)
    end
  end
  local fastest
  for _, row in ipairs(rows) do if row.best > 0 and (not fastest or row.best < fastest.best) then fastest = row end end
  local record = require('core.records').text()
  local line = fastest and ('MELHOR VOLTA: ' .. draw.fullName(fastest.name, 22) .. '  ' .. draw.fmtLap(fastest.best))
    or 'SEM VOLTA VÁLIDA'
  if record then
    line = line .. '   ·   ' .. record
  end
  draw.textF(draw.FONT_SEMI, 14*k, H-26*k, line, 11*k, draw.PURPLE, ui.Alignment.Center, W-28*k, 22*k)
  ui.popClipRect()
end
return M
