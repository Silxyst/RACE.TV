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

-- Paleta broadcast real (WEC/IMSA/NLS)
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

function M.clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
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
