-- ========================================
-- ENDURO TV // core/draw.lua
-- Linguagem broadcast solida estilo WEC/IMSA/NLS:
-- retangulos chapados, gradiente esquerda->direita escurecido,
-- tipografia Archivo Italic Bold, sem glass, sem neon, sem rounded.
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
M.NAVY   = rgbm.from0255(15, 5, 60, 255)
M.DARK   = rgbm.from0255(18, 18, 26, 255)
M.DARK2  = rgbm.from0255(28, 28, 38, 255)
M.RED    = rgbm.from0255(225, 6, 0, 255)
M.RED_D  = rgbm.from0255(140, 0, 0, 255)
M.BLUE   = rgbm.from0255(0, 180, 255, 255)
M.YELLOW = rgbm.from0255(255, 215, 0, 255)
M.GREEN  = rgbm.from0255(0, 180, 50, 255)
M.WHITE  = rgbm(1, 1, 1, 1)
M.GRAY   = rgbm.from0255(200, 200, 208, 255)
M.LIGHT  = rgbm.from0255(244, 244, 246, 255)
-- PHIL TV: fundo quase preto + azul royal do timer + cards
M.PHIL_BG    = rgbm.from0255(8, 8, 18, 255)
M.PHIL_ROW   = rgbm.from0255(16, 16, 34, 255)
M.PHIL_ROW2  = rgbm.from0255(22, 22, 42, 255)
M.PHIL_BLUE  = rgbm.from0255(28, 55, 180, 255)
M.PHIL_BLUE_D= rgbm.from0255(12, 22, 90, 255)
M.LIME       = rgbm.from0255(57, 255, 20, 255)
M.PHIL_YEL   = rgbm.from0255(255, 213, 0, 255)
M.PHIL_GRAY  = rgbm.from0255(150, 155, 170, 255)

-- Cor por piloto (faixa do card estilo PHIL: vermelho/verde/cinza/amarelo/azul)
local DRIVER_COLORS = {
  rgbm.from0255(225, 6, 0, 255),    -- red
  rgbm.from0255(57, 255, 20, 255),  -- lime
  rgbm.from0255(200, 205, 215, 255),-- silver
  rgbm.from0255(255, 213, 0, 255),  -- yellow
  rgbm.from0255(40, 110, 255, 255), -- blue
  rgbm.from0255(255, 110, 0, 255),  -- orange
}
function M.driverColor(idx)
  idx = math.abs(math.floor(tonumber(idx) or 0))
  return DRIVER_COLORS[(idx % #DRIVER_COLORS) + 1]
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
  return M.fmtClock((sim.currentSessionTime or 0) * 1000)
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

-- FSH-style: encaixa conteúdo na JANELA real (corrige bug de escala).
-- baseW/baseH = tamanho de referência em escala 1. Retorna k.
function M.fit(cfgScale, baseW, baseH)
  local k = cfgScale or 1
  local ok, ws = pcall(ui.windowSize)
  if ok and ws and ws.x > 10 and ws.y > 10 then
    k = math.min(k, ws.x / baseW, ws.y / baseH)
  end
  return math.max(0.35, k)
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
  if not t or t <= 0 then return rgbm.from0255(150, 150, 160, 255) end
  if overallBest and overallBest > 0 and t <= overallBest + 0.001 then
    return rgbm.from0255(190, 90, 255, 255)
  end
  if personalBest and personalBest > 0 and t <= personalBest + 0.001 then
    return rgbm.from0255(0, 210, 90, 255)
  end
  return rgbm.from0255(255, 200, 40, 255)
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
  if #parts == 0 then return full:sub(1, 12):upper() end
  if #parts == 1 then return parts[1]:sub(1, maxLen or 12):upper() end
  local last = parts[#parts]:upper()
  if #last > 10 then last = last:sub(1, 10) end
  return (parts[1]:sub(1, 1):upper() .. '. ' .. last)
end

function M.fullName(full, maxLen)
  if not full then return '---' end
  full = tostring(full):upper()
  if #full > (maxLen or 22) then full = full:sub(1, maxLen or 22) end
  return full
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
    return M.YELLOW, M.darken(M.YELLOW, 0.7), 'YELLOW FLAG', rgbm.from0255(15, 5, 50, 255)
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
  ui.pushDWriteFont(font)
  ui.setCursor(vec2(x, y))
  ui.dwriteTextAligned(tostring(str), size, alignH or ui.Alignment.Start, ui.Alignment.Center, vec2(boxW or 200, boxH or (size + 6)), false, color)
  ui.popDWriteFont()
end

function M.tyreColor(compound)
  if not compound then return rgbm.from0255(160, 160, 170, 255) end
  local c = string.upper(tostring(compound))
  if c:find('SOFT') or c == 'S' then return rgbm.from0255(225, 6, 0, 255)
  elseif c:find('MEDIUM') or c == 'M' then return rgbm.from0255(255, 215, 0, 255)
  elseif c:find('HARD') or c == 'H' then return rgbm.from0255(240, 240, 240, 255)
  elseif c:find('WET') or c:find('RAIN') then return rgbm.from0255(0, 140, 255, 255)
  elseif c:find('INTER') then return rgbm.from0255(0, 180, 80, 255)
  else return rgbm.from0255(170, 170, 180, 255) end
end

return M
