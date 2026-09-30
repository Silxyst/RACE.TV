-- ========================================
-- RACE TV v4 // core/anim.lua
-- Motor de animação (técnica CMRT-Broadcast-HUD):
-- remap/ease + fade/slide/clip + rowY suave
-- ========================================
local M = {}

local math = math

function M.remap(v, a, b, c, d)
  if a == b then return c end
  return c + (v - a) * (d - c) / (b - a)
end

function M.remapc(v, a, b, c, d)
  return M.remap(math.max(a, math.min(b, v)), a, b, c, d)
end

-- 0->1 linear com clamp (timer, inicio, duracao)
function M.lerpT(t, start, dur)
  return M.remapc(t, start, start + dur, 0, 1)
end

function M.ease_out_quad(x) return 1 - (1 - x) * (1 - x) end
function M.ease_out_cubic(x) return 1 - math.pow(1 - x, 3) end
function M.ease_out_quart(x) return 1 - math.pow(1 - x, 4) end
function M.ease_in_quad(x) return x * x end
function M.ease_out_back(x)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
end

-- aproxima atual->alvo com velocidade (para rowY, valores)
function M.damp(cur, target, speed, dt)
  local t = math.min(1, (dt or 0.016) * (speed or 10))
  return cur + (target - cur) * t
end

-- popup reveal: retorna {clip (0..1), alpha (0..1), slide (px offset)}
-- t = tempo desde show, stay = segundos visível, intro/out = durações
function M.popup(t, stay, intro, outro)
  intro = intro or 0.3
  outro = outro or 0.3
  local ci = M.ease_out_quart(M.lerpT(t, 0, intro))
  local co = M.lerpT(t, intro + (stay or 5), outro)
  return math.max(0, ci - co), math.max(0, ci - co), (1 - M.ease_out_quart(M.lerpT(t, 0, intro))) * 24
end

return M
