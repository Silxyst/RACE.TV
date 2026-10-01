-- ========================================
-- ENDURO TV // core/draw.lua
-- Shared Broadcast Glass theme, font fitting and drawing helpers.
-- ========================================
local M = {}

local ui = ui
local rgbm = rgbm
local vec2 = vec2
local math = math
local string = string

M.FONT_NUM  = 'fonts/Archivo-ExtraBoldItalic.ttf'
M.FONT_HEAD = 'fonts/Archivo-ExtraBoldItalic.ttf'
M.FONT_BOLD = 'fonts/Archivo-BoldItalic.ttf'
M.FONT_SEMI = 'fonts/Archivo-SemiBoldItalic.ttf'
M.FONT_TXT  = 'fonts/OpenSans-SemiBold.ttf'

-- Paleta broadcast real (WEC/IMSA/NLS) + PHIL TV
M.NAVY   = rgbm.from0255(15, 5, 60, 1)
M.DARK   = rgbm.from0255(18, 18, 26, 1)
M.DARK2  = rgbm.from0255(28, 28, 38, 1)
M.RED    = rgbm.from0255(225, 6, 0, 1)
M.RED_D  = rgbm.from0255(140, 0, 0, 1)
M.BLUE   = rgbm.from0255(0, 180, 255, 1)
M.YELLOW = rgbm.from0255(255, 215, 0, 1)
M.GREEN  = rgbm.from0255(0, 180, 50, 1)
M.WHITE  = rgbm(1, 1, 1, 1)
M.GRAY   = rgbm.from0255(200, 200, 208, 1)
M.LIGHT  = rgbm.from0255(244, 244, 246, 1)
-- PHIL TV: fundo quase preto + azul royal do timer + cards
M.PHIL_BG    = rgbm.from0255(8, 8, 18, 1)
M.PHIL_ROW   = rgbm.from0255(16, 16, 34, 1)
M.PHIL_ROW2  = rgbm.from0255(22, 22, 42, 1)
M.PHIL_BLUE  = rgbm.from0255(28, 55, 180, 1)
M.PHIL_BLUE_D= rgbm.from0255(12, 22, 90, 1)
M.LIME       = rgbm.from0255(57, 255, 20, 1)
M.PHIL_YEL   = rgbm.from0255(255, 213, 0, 1)
M.PHIL_GRAY  = rgbm.from0255(150, 155, 170, 1)
M.PURPLE     = rgbm.from0255(190, 90, 255, 1)

-- Cor por piloto (faixa do card estilo PHIL: vermelho/verde/cinza/amarelo/azul)
local DRIVER_COLORS = {
  rgbm.from0255(225, 6, 0, 1),
  rgbm.from0255(57, 255, 20, 1),
  rgbm.from0255(200, 205, 215, 1),
  rgbm.from0255(255, 213, 0, 1),
  rgbm.from0255(40, 110, 255, 1),
  rgbm.from0255(255, 110, 0, 1),
}
function M.driverColor(idx)
  idx = math.abs(math.floor(tonumber(idx) or 0))
  -- Keep driver differentiation, but let the selected theme color the whole HUD.
  local accent = require('core.config').get().brand1
  local individual = DRIVER_COLORS[(idx % #DRIVER_COLORS) + 1]
  return rgbm(accent.r * 0.8 + individual.r * 0.2,
    accent.g * 0.8 + individual.g * 0.2, accent.b * 0.8 + individual.b * 0.2, 1)
end
function M.driverColorDark(idx)
  return M.darken(M.driverColor(idx), 0.55)
end

-- ms -> "80:16:16" (H:MM:SS) estilo PHIL
function M.fmtClock(ms)
  if not ms or type(ms) ~= 'number' or ms < 0 then return '--:--:--' end
  local total = math.floor(ms / 1000)
  local h = math.floor(total / 3600)
  local m = math.floor((total % 3600) / 60)
  local s = total % 60
  return string.format('%d:%02d:%02d', h, m, s)
end

function M.sessionClock(sim)
  if not sim then return '--:--:--' end
  local left = sim.sessionTimeLeft or 0
  if left and left > 0 then return M.fmtClock(left) end
  return M.fmtClock(math.max(0, sim.currentSessionTime or 0))
end

function M.isQualiLike(sim)
  local sess = sim and ac.getSession(sim.currentSessionIndex or 0)
  local t = sess and sess.type
  return t == ac.SessionType.Qualify or t == ac.SessionType.Practice
      or t == ac.SessionType.Hotlap or t == ac.SessionType.TimeAttack
end

function M.clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local renderScale

function M.withScale(scale, callback)
  local old = renderScale
  renderScale = scale
  local ok, err = xpcall(callback, debug.traceback)
  renderScale = old
  if not ok then error(err, 0) end
end

-- All widgets share the requested scale. Fit spacing/pages, never shrink a card
-- according to its own height or a transient native window size.
function M.fit(cfgScale, baseW, baseH, title)
  if renderScale then return renderScale end
  return M.clamp(tonumber(cfgScale) or 1, 0.7, 1.6)
end

function M.smoothstep(a, b, x)
  if a == b then return x >= b and 1 or 0 end
  x = M.clamp((x - a) / (b - a), 0, 1)
  return x * x * (3 - 2 * x)
end

function M.moveTowards(cur, tgt, d)
  if cur < tgt then return math.min(cur + d, tgt) end
  return math.max(cur - d, tgt)
end

-- Cor de setor/volta estilo LapAlly/ACTV: roxo overall, verde PB, amarelo resto
function M.sectorColor(t, overallBest, personalBest)
  if not t or t <= 0 then return M.PHIL_GRAY end
  if overallBest and overallBest > 0 and t <= overallBest + 0.001 then
    return M.PURPLE
  end
  if personalBest and personalBest > 0 and t <= personalBest + 0.001 then
    return M.GREEN
  end
  return M.YELLOW
end

-- Delta LapAlly: "+1.234" adaptativo
function M.fmtDeltaS(sec)
  if not sec or type(sec) ~= 'number' then return '---' end
  local a = math.abs(sec)
  if a > 100 then return string.format('%+.0f', sec)
  elseif a > 10 then return string.format('%+.1f', sec)
  else return string.format('%+.3f', sec) end
end

function M.darken(c, k)
  return rgbm(c.r * k, c.g * k, c.b * k, 1)
end

-- ms -> "1:23.456"
function M.fmtLap(ms)
  if not ms or type(ms) ~= 'number' or ms <= 0 or ms > 3600000 then return '--:--.---' end
  local m = math.floor(ms / 60000)
  local s = math.floor((ms - m * 60000) / 1000)
  local mm = math.floor(ms % 1000)
  return string.format('%d:%02d.%03d', m, s, mm)
end

function M.fmtSec(sec)
  if not sec or type(sec) ~= 'number' or sec > 90 then return '--.--' end
  return string.format('+%.2f', sec)
end

function M.fmtGap(ms)
  if not ms or type(ms) ~= 'number' then return '--.--' end
  if ms >= 90000 then return '+' .. string.format('%.1f', ms / 1000) end
  local sign = ms < 0 and '-' or '+'
  return sign .. string.format('%.3f', math.abs(ms) / 1000)
end

-- "Joao Silva" -> "J. SILVA" (padrao onboard TV)
function M.shortName(full, maxLen)
  if not full or #tostring(full) == 0 then return '---' end
  full = tostring(full)
  local parts = {}
  for w in string.gmatch(full, '%S+') do parts[#parts + 1] = w end
  if #parts == 0 then return M.truncate(full, 12):upper() end
  if #parts == 1 then return M.truncate(parts[1], maxLen or 12):upper() end
  local last = parts[#parts]:upper()
  last = M.truncate(last, 10)
  return (M.truncate(parts[1], 1):upper() .. '. ' .. last)
end

function M.fullName(full, maxLen)
  if not full or tostring(full):match('^%s*$') then return '---' end
  return M.truncate(tostring(full):upper(), maxLen or 22)
end

-- Barra solida com gradiente TV (esq cor cheia, dir 60%)
function M.solidBar(x, y, w, h, color)
  local c2 = M.darken(color, 0.55)
  ui.drawRectFilledMultiColor(vec2(x, y), vec2(x + w, y + h), color, c2, c2, color)
end

-- Fundo de linha: navy chapado
function M.rowBg(x, y, w, h, alt)
  if alt then
    ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), M.DARK2)
  else
    ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), M.DARK)
  end
end

-- Header TV com cor de bandeira (igual WEC DrawRoundBoxTop, sem round)
-- Retorna {bg1, bg2, text}
function M.flagColors(sim)
  local ft = sim and sim.raceFlagType
  if ft == ac.FlagType.Caution then
    return M.YELLOW, M.darken(M.YELLOW, 0.7), 'YELLOW FLAG', M.NAVY
  end
  return nil, nil, nil, nil
end

function M.sessionLabel(sim)
  local sess = sim and ac.getSession(sim.currentSessionIndex or 0)
  local t = sess and sess.type
  if t == ac.SessionType.Qualify then return 'QUALIFYING'
  elseif t == ac.SessionType.Race then return 'RACE'
  elseif t == ac.SessionType.Practice then return 'PRACTICE'
  elseif t == ac.SessionType.Hotlap then return 'HOTLAP'
  elseif t == ac.SessionType.TimeAttack then return 'TIME ATTACK'
  elseif t == ac.SessionType.Drift then return 'DRIFT' end
  if sim and sim.raceSessionType == ac.SessionType.Qualify then return 'QUALIFYING' end
  if sim and sim.raceSessionType == ac.SessionType.Race then return 'RACE' end
  return 'SESSION'
end

-- Texto com fonte push/pop seguro
function M.textF(font, x, y, str, size, color, alignH, boxW, boxH)
  str = tostring(str or '')
  boxW, boxH = math.max(1, boxW or 200), math.max(1, boxH or size + 6)
  ui.pushDWriteFont(font)
  local ok, err = pcall(function()
    local measured = ui.measureDWriteText(str, size)
    if measured.x > boxW then size = size * math.max(0.65, boxW / measured.x) end
    -- Fractional animation/fitting sizes otherwise continuously grow CSP's
    -- glyph atlas (the real log showed 532 ms glyph-map reallocation stalls).
    size = math.max(6, math.min(128, math.floor(size * 2 + 0.5) / 2))
    ui.dwriteDrawTextClipped(str, size, vec2(x, y), vec2(x + boxW, y + boxH),
      alignH or ui.Alignment.Start, ui.Alignment.Center, false, color)
  end)
  ui.popDWriteFont()
  if not ok then error(err, 0) end
end

-- Safe UTF-8 truncation: never split an accent into invalid bytes.
function M.truncate(text, count)
  local out, n = {}, 0
  for char in tostring(text or ''):gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    n = n + 1
    if n > count then break end
    out[#out + 1] = char
  end
  return table.concat(out)
end

function M.tyreColor(compound)
  if not compound then return M.PHIL_GRAY end
  local c = string.upper(tostring(compound))
  if c:find('SOFT') or c == 'S' then return M.RED
  elseif c:find('MEDIUM') or c == 'M' then return M.YELLOW
  elseif c:find('HARD') or c == 'H' then return M.WHITE
  elseif c:find('WET') or c:find('RAIN') then return M.BLUE
  elseif c:find('INTER') or c == 'I' then return M.GREEN
  else return M.PHIL_GRAY end
end

-- alpha sobre qualquer cor (o 4o valor do rgbm é multiplicador 0..1)
function M.fade(c, a)
  return rgbm(c.r, c.g, c.b, M.clamp((c.mult or 1) * a, 0, 1))
end

function M.surface(alpha)
  local c = require('core.config').get().surface
  return rgbm(c.r, c.g, c.b, M.clamp(alpha or 0.92, 0, 1))
end

-- branco suavizado (1 = quase branco, 0 = cinza médio)
function M.dim(f)
  f = 0.55 + 0.45 * math.max(0, math.min(1, f or 1))
  return rgbm(f, f, math.min(1, f + 0.03), 1)
end

-- cartão broadcast: fundo escuro + filete de acento no topo + borda sutil
function M.card(x, y, w, h, accent, alpha, radius)
  alpha = alpha or 1
  radius = radius or 8
  ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), M.surface(0.92 * alpha), radius)
  ui.drawRectFilled(vec2(x, y), vec2(x + w, y + 3), M.fade(accent, alpha), 2)
  ui.drawRect(vec2(x + 0.5, y + 0.5), vec2(x + w - 0.5, y + h - 0.5), rgbm(1, 1, 1, 0.09 * alpha))
end

-- pílula arredondada (posições, status, setores); passe a cor já com alpha
function M.pill(x, y, w, h, bg)
  ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), bg, 6)
end

local FLAG_COLORS = { yellow = 'YELLOW', green = 'GREEN', white = 'WHITE' }
function M.flagPill(x, y, w, h, text, style, alpha)
  local color = M[FLAG_COLORS[style] or 'GRAY'] or M.PHIL_GRAY
  local dark = style == 'yellow' or style == 'white'
  M.pill(x, y, w, h, M.fade(color, alpha))
  local size = math.max(6, math.min(18, h * 0.61))
  M.textF(M.FONT_HEAD, x, y, text, size, M.fade(dark and M.PHIL_BG or M.WHITE, alpha),
    ui.Alignment.Center, w, h)
end

function M.action(id, label, x, y, w, h, accent, scale)
  ui.setCursor(vec2(x, y))
  local clicked = ui.invisibleButton('##' .. id, vec2(w, h), ui.ButtonFlags.PressedOnClick + ui.ButtonFlags.NoNavFocus)
  local hovered = ui.itemHovered()
  M.pill(x, y, w, h, hovered and M.fade(accent, 0.85) or rgbm(1, 1, 1, 0.08))
  M.textF(M.FONT_SEMI, x+4, y, label, 11*(scale or 1), M.WHITE, ui.Alignment.Center, w-8, h)
  if hovered then ui.setMouseCursor(ui.MouseCursor.Hand) end
  return clicked
end

function M.logo(x, y, w, h, alpha)
  local branding = require('core.branding')
  local image = branding.logo()
  if not image then return false end
  -- Reserve the layout slot even while the texture streams in.
  if branding.ready and not branding.ready() then return true end
  ui.drawImage(image, vec2(x, y), vec2(x+w, y+h), M.fade(M.WHITE, alpha or 1), vec2(0, 0), vec2(1, 1), ui.ImageFit.Fit)
  return true
end

return M
