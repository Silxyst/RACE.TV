-- ========================================
-- RACE TV // core/classes.lua
-- Multiclasse AUTOMÁTICA (melhor que WEC: zero config).
-- Agrupa por modelo do carro; cada modelo = uma classe com cor própria.
-- ========================================
local M = {}

local PALETTE = {
  rgbm.from0255(225, 6, 0, 255),    -- red
  rgbm.from0255(0, 150, 255, 255),  -- blue
  rgbm.from0255(0, 200, 90, 255),   -- green
  rgbm.from0255(255, 190, 0, 255),  -- amber
  rgbm.from0255(190, 90, 255, 255), -- purple
  rgbm.from0255(255, 110, 0, 255),  -- orange
}

local map = {}   -- modelKey -> {name, color}
local order = {} -- modelKeys na ordem de aparição

local function modelKey(idx)
  local ok, cn = pcall(ac.getCarName, idx)
  local m = (ok and cn and #tostring(cn) > 0) and tostring(cn) or 'car'
  return m:lower()
end

local function shortClass(model)
  -- "ks_porsche_911_gt3_r_2016" -> "PORSCHE 911" (2 primeiras palavras úteis)
  local clean = model:gsub('^ks_', ''):gsub('_', ' ')
  local words = {}
  for w in clean:gmatch('%S+') do
    if #w > 1 and not w:match('^%d+$') or #words < 2 then words[#words + 1] = w end
    if #words >= 2 then break end
  end
  local s = table.concat(words, ' '):upper()
  if #s > 12 then s = s:sub(1, 12) end
  return s ~= '' and s or 'OPEN'
end

function M.update()
  local sim = ac.getSim()
  if not sim then return end
  for i = 0, (sim.carsCount or 1) - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected ~= false then
      local k = modelKey(i)
      if not map[k] then
        local ok, cn = pcall(ac.getCarName, i)
        local full = (ok and cn) and tostring(cn) or k
        map[k] = { name = shortClass(full), color = PALETTE[(#order % #PALETTE) + 1] }
        order[#order + 1] = k
      end
    end
  end
end

function M.get(idx)
  local k = modelKey(idx)
  return map[k] or { name = 'OPEN', color = PALETTE[1] }
end

function M.count() return #order end

function M.on_session_start() map = {} order = {} end
function M.init() end

return M
