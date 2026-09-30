-- ========================================
-- RACE TV // core/winfit.lua
-- Auto-resize: janela acompanha o conteúdo (técnica CMRT winstuff).
-- Corrige o travamento da escala (conteúdo maior que a janela fixa).
-- ========================================
local M = {}

local names = {} -- title -> app name
local lastSize = {} -- title -> "WxH" aplicado

local function appName(title)
  if names[title] then return names[title] end
  local ok, all = pcall(ac.getAppWindows)
  if not ok or not all then return nil end
  for i = 1, #all do
    local app = all[i]
    if app and app.title == title and app.name then
      names[title] = app.name
      return app.name
    end
  end
  return nil
end

-- garante janela com (w,h); retorna true se ajustou
function M.fit(title, w, h)
  w = math.max(40, math.floor(w + 0.5))
  h = math.max(20, math.floor(h + 0.5))
  local key = w .. 'x' .. h
  if lastSize[title] == key then return false end
  local name = appName(title)
  if not name then return false end
  local ok, win = pcall(ac.accessAppWindow, name)
  if not ok or not win then return false end
  local okR = pcall(win.resize, win, vec2(w, h))
  if okR then lastSize[title] = key return true end
  return false
end

return M
