local M = { logoStatus = '' }
local drivers = require('core.drivers')
local checked, logo, logoFull, metadata = nil, nil, nil, {}
local VALID_EXT = { png = true, jpg = true, jpeg = true, dds = true, bmp = true }

local function appFolder()
  local ok, folder = pcall(function() return ac.getFolder(ac.FolderID.ACAppsLua) end)
  if ok and type(folder) == 'string' and folder ~= '' then
    return (folder:gsub('\\', '/'):gsub('/+$', ''))
  end
  return nil
end

local function candidates(path)
  local list = {}
  local function add(value)
    if value and value ~= '' then list[#list + 1] = value end
  end
  add(path)
  local app = appFolder()
  if app then
    if not path:match('^%a:[/\\]') and not path:match('^[/\\]') then
      add(app .. '/Streamer Hud/' .. path)
      add(app .. '/Streamer Hud/assets/' .. path)
    end
  end
  return list
end

local function fileExists(path)
  local ok, exists = pcall(io.fileExists, path)
  if ok and exists then return true end
  local okOpen, file = pcall(io.open, path, 'rb')
  if okOpen and file then pcall(function() file:close() end) return true end
  return false
end

function M.update()
  local cfg = require('core.config').get()
  local path = cfg.showLogo and cfg.logo or ''
  if path == checked then return end
  checked, logo, logoFull = path, nil, nil
  if path == '' then M.logoStatus = '' return end
  local ext = path:lower():match('%.([a-z0-9]+)%s*$')
  if not ext or not VALID_EXT[ext] then
    M.logoStatus = 'Formato inválido (use PNG, JPG, DDS ou BMP)'
    return
  end
  for _, full in ipairs(candidates(path)) do
    if fileExists(full) then
      logo, logoFull, M.logoStatus = path, full, 'Logo carregado'
      return
    end
  end
  M.logoStatus = 'Logo não encontrado: ' .. path
end
function M.logo() return logoFull or logo end
function M.ready()
  local image = logoFull or logo
  if not image then return false end
  if ui.isImageReady then
    local ok, ready = pcall(ui.isImageReady, image)
    if ok then return ready end
  end
  return true
end
function M.reloadLogo() checked = nil end
local function state(index)
  local key = drivers.key(index)
  if not metadata[key] then
    metadata[key] = { number = ac.storage('ETV_driver_' .. key .. '_number', ''), team = ac.storage('ETV_driver_' .. key .. '_team', '') }
  end
  return metadata[key]
end
function M.driver(index)
  local value = state(index)
  local number, team = tostring(value.number:get() or ''), tostring(value.team:get() or '')
  if number == '' then
    -- Real car number from the game; custom override above takes priority.
    local ok, native = pcall(ac.getDriverNumber, index)
    if ok and type(native) == 'number' and native > 0 and native < 1000 then
      number = tostring(math.floor(native))
    elseif ok and type(native) == 'string' and native:match('%d') then
      number = native:gsub('[^%d]', ''):sub(1, 3)
    end
  end
  if team == '' then
    local ok, name = pcall(ac.getCarName, index)
    team = ok and tostring(name or '') or ''
  end
  return number, team
end
function M.setDriver(index, number, team)
  if not drivers.valid(index) then return false end
  local value, draw = state(index), require('core.draw')
  number, team = draw.truncate(tostring(number or ''):gsub('[\r\n]', ' '), 5), draw.truncate(tostring(team or ''):gsub('[\r\n]', ' '), 40)
  if value.number:get() ~= number then value.number:set(number) end
  if value.team:get() ~= team then value.team:set(team) end
  return true
end
function M.settingsUI()
  local sim = ac.getSim()
  if not sim or not drivers.valid(sim.focusedCar) then return end
  local index, value = sim.focusedCar, state(sim.focusedCar)
  ui.text('Identificação do piloto focado: ' .. drivers.name(index))
  local number = ui.inputText('Número do carro', tostring(value.number:get() or ''))
  local team = ui.inputText('Equipe (vazio usa o modelo do carro)', tostring(value.team:get() or ''))
  M.setDriver(index, number, team)
end
return M
