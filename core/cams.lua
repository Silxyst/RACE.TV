-- ========================================
-- RACE TV // core/cams.lua
-- Perfis por câmera: cada widget escolhe em quais câmeras aparece.
-- Grupos: ONB (onboard: Cockpit/Dash/Car/Onboard/Drivable),
--         EXT (externas: chase F3/F5, pista F6, resto),
--         FRE (livres: Free/OnBoardFree).
-- Modos desconhecidos caem em EXT (nunca some tudo por engano).
-- ========================================
local M = {}

M.ONB, M.EXT, M.FRE = 1, 2, 4
M.ALL = 7

M.GROUPS = {
  { bit = 1, code = 'ONB', label = 'Onboard' },
  { bit = 2, code = 'EXT', label = 'Externa F3/F5/F6' },
  { bit = 4, code = 'FRE', label = 'Livre' },
}

M.WIDGETS = {
  'TV Tower', 'TV Battle', 'TV Onboard Top', 'TV Telemetry', 'TV Inputs',
  'TV Timing', 'TV Onboard Bar', 'TV Spotter', 'TV Map', 'TV Lineup', 'TV Alert',
  'TV Tags',
}

local DEFAULTS = {
  ['TV Tower'] = 6,
  ['TV Battle'] = 6,
  ['TV Onboard Top'] = 7,
  ['TV Telemetry'] = 7,
  ['TV Inputs'] = 1,
  ['TV Timing'] = 7,
  ['TV Onboard Bar'] = 7,
  ['TV Spotter'] = 7,
  ['TV Map'] = 7,
  ['TV Lineup'] = 6,
  ['TV Alert'] = 7,
}

local stores = {}
local function storeFor(title)
  local st = stores[title]
  if not st then
    st = ac.storage('CAM_' .. title, DEFAULTS[title] or M.ALL)
    stores[title] = st
  end
  return st
end

function M.group()
  local sim = ac.getSim()
  local cm = sim and sim.cameraMode or nil
  local C = ac.CameraMode
  if cm == C.Cockpit or cm == C.Dash or cm == C.Car or cm == C.Onboard or cm == C.Drivable then
    return M.ONB, 'ONB'
  elseif cm == C.Free or cm == C.OnBoardFree then
    return M.FRE, 'FRE'
  end
  return M.EXT, 'EXT'
end

function M.groupLabel()
  local _, code = M.group()
  if code == 'ONB' then return 'Onboard (cockpit/F1)'
  elseif code == 'FRE' then return 'Livre (orbit/cine)' end
  return 'Externa (F3/F5/F6/pista)'
end

function M.mask(title)
  local v = storeFor(title):get()
  if type(v) ~= 'number' then v = DEFAULTS[title] or M.ALL end
  return v
end

function M.set(title, mask) storeFor(title):set(mask) end

-- true = deve desenhar nesta câmera
function M.gate(title)
  local bit, _ = M.group()
  local m = M.mask(title)
  return (m % (bit * 2)) >= bit
end

return M
