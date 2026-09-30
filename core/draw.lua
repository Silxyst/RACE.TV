-- ========================================
-- VELOCITY SLASH // core/draw.lua
-- Linguagem visual unica: painel glass + corte SLASH diagonal + barra accent
-- So usa APIs seguras: drawRectFilled, drawLine, drawCircleFilled, dwrite
-- ========================================
local M = {}

local ac = ac
local ui = ui
local rgbm = rgbm
local vec2 = vec2
local math = math
local string = string

function M.clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

function M.lerp(a, b, t) return a + (b - a) * t end

-- ms -> "1:23.456" | "--:--.---"
function M.fmtLap(ms)
  if not ms or type(ms) ~= 'number' or ms <= 0 or ms > 3600000 then return '--:--.---' end
  local m = math.floor(ms / 60000)
  local s = math.floor((ms - m * 60000) / 1000)
  local mm = math.floor(ms % 1000)
  return string.format('%d:%02d.%03d', m, s, mm)
end

-- ms diff -> "+1.234" / "-0.456"
function M.fmtGap(ms)
  if not ms or type(ms) ~= 'number' then return '--.--' end
  if ms >= 90000 then return '+' .. string.format('%.1f', ms / 1000) .. 's' end
  local sign = ms < 0 and '-' or '+'
  return sign .. string.format('%.3f', math.abs(ms) / 1000)
end

-- seg float -> "+1.23"
function M.fmtSec(sec)
  if not sec or type(sec) ~= 'number' or sec > 90 then return '--.--' end
  return string.format('+%.2f', sec)
end

function M.shortName(full)
  if not full or #full == 0 then return '---' end
  -- "Joao Silva" -> "J. SILVA" (padrao broadcast)
  local parts = {}
  for w in string.gmatch(full, '%S+') do parts[#parts + 1] = w end
  if #parts == 0 then return full:sub(1, 12):upper() end
  if #parts == 1 then return parts[1]:sub(1, 12):upper() end
  local first = parts[1]:sub(1, 1):upper() .. '.'
  local last = parts[#parts]:upper()
  if #last > 10 then last = last:sub(1, 10) end
  return first .. ' ' .. last
end

function M.bg(alpha) return rgbm(0.02, 0.03, 0.05, alpha) end
function M.bg2(alpha) return rgbm(0.06, 0.09, 0.13, alpha) end
function M.white(a) return rgbm(1, 1, 1, a or 1) end
function M.dim(a) return rgbm(0.62, 0.68, 0.75, a or 1) end

function M.accent(cfg, a)
  local c = cfg.accent or { r = 0, g = 0.9, b = 1 }
  return rgbm(c.r, c.g, c.b, a or 1)
end

-- Painel SLASH: retangulo glass + barra accent esquerda + corte diagonal topo-direita
-- x,y,w,h em pixels ja escalados. slash = tamanho do corte.
function M.slashPanel(x, y, w, h, cfg, opts)
  opts = opts or {}
  local op = cfg.opacity or 0.92
  local r = opts.rounding or 7
  ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), M.bg(0.78 * op), r)
  -- linha sutil de borda
  ui.drawRect(vec2(x + 0.5, y + 0.5), vec2(x + w - 0.5, y + h - 0.5), rgbm(1, 1, 1, 0.08 * op), 1)
  -- barra accent esquerda
  local bw = opts.barW or 4
  ui.drawRectFilled(vec2(x, y), vec2(x + bw, y + h), M.accent(cfg, 1), r)
  -- corte slash: triangulo accent no topo-direita
  local slash = opts.slash or 18
  local ax = cfg.accent
  -- pequeno triangulo via 2 linhas grossas (sem drawTriangle na API, simulamos com rect rotado visual)
  ui.drawRectFilled(vec2(x + w - slash, y), vec2(x + w, y + 4), M.accent(cfg, 1), 1)
  -- canto inferior com micro detalhe
  if not opts.noDot then
    ui.drawCircleFilled(vec2(x + w - 10, y + h - 10), 2.2, M.accent(cfg, 0.9), 8)
  end
end

-- Header padrao: "// CANAL  ● LIVE" + titulo widget
function M.header(x, y, w, cfg, title, livePulse)
  local s = cfg.scale or 1
  ui.setCursor(vec2(x + 12 * s, y + 7 * s))
  ui.dwriteTextAligned('// ' .. string.upper(cfg.channel or 'STREAM'), 13 * s, ui.Alignment.Start, ui.Alignment.Center, vec2(w * 0.62, 18 * s), false, M.dim(1))
  -- LIVE dot
  local pulse = 0.6 + 0.4 * math.sin(livePulse or 0)
  ui.drawCircleFilled(vec2(x + w - 52 * s, y + 16 * s), 4 * s, rgbm(1, 0.2, 0.25, pulse), 12)
  ui.setCursor(vec2(x + w - 44 * s, y + 7 * s))
  ui.dwriteTextAligned('LIVE', 13 * s, ui.Alignment.Start, ui.Alignment.Center, vec2(40 * s, 18 * s), false, M.white(1))
  if title then
    ui.setCursor(vec2(x + 12 * s, y + 24 * s))
    ui.dwriteTextAligned(title, 11 * s, ui.Alignment.Start, ui.Alignment.Center, vec2(w - 24 * s, 14 * s), false, M.accent(cfg, 1))
  end
end

function M.text(x, y, str, size, color, align, boxW, boxH)
  ui.setCursor(vec2(x, y))
  ui.dwriteTextAligned(tostring(str), size, align or ui.Alignment.Start, ui.Alignment.Center, vec2(boxW or 200, boxH or (size + 6)), false, color)
end

-- Barra horizontal simples (pedal, rpm, delta)
function M.hbar(x, y, w, h, frac, fill, back, rounding)
  frac = M.clamp(frac or 0, 0, 1)
  ui.drawRectFilled(vec2(x, y), vec2(x + w, y + h), back or rgbm(1, 1, 1, 0.12), rounding or 3)
  if frac > 0.001 then
    ui.drawRectFilled(vec2(x, y), vec2(x + w * frac, y + h), fill, rounding or 3)
  end
end

-- Cor do pneu (heuristica por compound string)
function M.tyreColor(compound)
  if not compound then return rgbm(0.7, 0.7, 0.7, 1) end
  local c = string.upper(tostring(compound))
  if c:find('SOFT') or c:find('S ') or c == 'S' then return rgbm(1, 0.2, 0.25, 1)
  elseif c:find('MEDIUM') or c:find('M ') or c == 'M' then return rgbm(1, 0.85, 0.1, 1)
  elseif c:find('HARD') or c:find('H ') or c == 'H' then return rgbm(1, 1, 1, 1)
  elseif c:find('WET') or c:find('RAIN') then return rgbm(0.2, 0.6, 1, 1)
  elseif c:find('INTER') then return rgbm(0.2, 0.9, 0.4, 1)
  else return rgbm(0.75, 0.75, 0.8, 1) end
end

return M
