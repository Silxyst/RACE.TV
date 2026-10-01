-- Racing categories: ui_car.json tag rules + per-skin override win,
-- manufacturer heuristics stay as fallback. Different GT3 makes share ONE class.
local M = {}
local byIndex, categories = {}, {}
local tagCache = {}
local colors = {
  GT3 = rgbm.from0255(0, 150, 255, 1), GT4 = rgbm.from0255(0, 200, 90, 1),
  LMP2 = rgbm.from0255(255, 190, 0, 1), HYPERCAR = rgbm.from0255(225, 6, 0, 1),
  FORMULA = rgbm.from0255(190, 90, 255, 1), TOURING = rgbm.from0255(255, 110, 0, 1),
  OPEN = rgbm.from0255(160, 170, 185, 1),
}
local slots = {}
for i = 1, 6 do
  slots[i] = { enabled = ac.storage('ETV_mc' .. i .. 'Enabled', false),
    tag = ac.storage('ETV_mc' .. i .. 'Tag', ''),
    color = ac.storage('ETV_mc' .. i .. 'Color', '#FFFFFF') }
end
local overrides = ac.storage('ETV_mcOverrides', '')
-- One-click broadcast palette. Free choice via the native picker below.
M.palette = {
  { 'Vermelho', '#E10600' }, { 'Laranja', '#FF6E00' }, { 'Amarelo', '#FFD500' },
  { 'Verde', '#00B450' }, { 'Ciano', '#00B4FF' }, { 'Azul', '#1C37B4' },
  { 'Roxo', '#BE5AFF' }, { 'Rosa', '#FF4FA3' }, { 'Branco', '#F4F4F6' },
  { 'Cinza', '#A0AAB9' }, { 'Preto', '#23232B' }, { 'Lima', '#39FF14' },
}
function M.setColor(slot, hex)
  if not slots[slot] or type(hex) ~= 'string' then return false end
  hex = hex:gsub('#', ''):gsub('%s+', '')
  if #hex ~= 6 or not hex:match('^%x%x%x%x%x%x$') then return false end
  hex = '#' .. hex:upper()
  if slots[slot].color:get() ~= hex then slots[slot].color:set(hex) end
  return true
end
local function hexColor(value, fallback)
  if type(value) ~= 'string' then return fallback end
  local hex = value:gsub('#', ''):gsub('%s+', '')
  if #hex ~= 6 then return fallback end
  local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  if not r or not g or not b then return fallback end
  return rgbm(r / 255, g / 255, b / 255, 1)
end
local function normalize(tag) return string.lower(tostring(tag or '')) end
local function extractTags(raw)
  local result = {}
  if type(raw) ~= 'string' then return result end
  local block = raw:match('"tags"%s*:%s*%[(.-)%]')
  if not block then return result end
  for tag in block:gmatch('"(.-)"') do if tag ~= '' then result[#result + 1] = tag end end
  return result
end
local function carID(index)
  local car = ac.getCar(index)
  if car then
    local ok, value = pcall(function() return car:id() end)
    if ok and type(value) == 'string' and value ~= '' then return value end
  end
  local ok, value = pcall(ac.getCarID, index)
  if ok and value then return tostring(value) end
  return ''
end
local function skinID(index)
  local car = ac.getCar(index)
  if car then
    local ok, value = pcall(function() return car:skin() end)
    if ok and type(value) == 'string' then return value end
  end
  return ''
end
local function readTags(id)
  if tagCache[id] then return tagCache[id] end
  local lookup = {}
  -- Test hook: audit.tagFiles[id] bypasses the filesystem in regression tests.
  local raw = nil
  if audit and audit.tagFiles and audit.tagFiles[id] then raw = audit.tagFiles[id] end
  if raw == nil then
    local okFolder, folder = pcall(function() return ac.getFolder(ac.FolderID.ContentCars or ac.FolderID.Root) end)
    if okFolder and type(folder) == 'string' and id ~= '' then
      local base = folder:gsub('\\', '/'):gsub('/+$', '')
      local suffix = ''
      if not base:match('[Cc]ontent/[Cc]ars$') then suffix = '/content/cars' end
      local path = base .. suffix .. '/' .. id .. '/ui/ui_car.json'
      local ok, file = pcall(io.open, path, 'r')
      if ok and file then
        local okRead, contents = pcall(function() return file:read('*a') end)
        pcall(function() file:close() end)
        if okRead then raw = contents end
      end
    end
  end
  if type(raw) == 'string' then
    for _, tag in ipairs(extractTags(raw)) do lookup[normalize(tag)] = true end
  end
  tagCache[id] = lookup
  return lookup
end
local function rule(slot)
  local s = slots[slot]
  local enabled, tag, hex = s.enabled:get() == true, tostring(s.tag:get() or ''), tostring(s.color:get() or '#FFFFFF')
  return enabled, tag, hexColor(hex, colors.OPEN)
end
local function findOverride(id, skin)
  if id == '' or skin == '' then return nil end
  for entry in tostring(overrides:get() or ''):gmatch('[^;]+') do
    local car, sk, slot = entry:match('^([^|]+)|([^|]+)|(%d+)$')
    if car == id and sk == skin then
      slot = tonumber(slot)
      if slot and slot >= 1 and slot <= 6 then return slot end
    end
  end
end
function M.setOverride(index, slot)
  local id, skin = carID(index), skinID(index)
  if id == '' or skin == '' then return false end
  local kept = {}
  for entry in tostring(overrides:get() or ''):gmatch('[^;]+') do
    local car, sk = entry:match('^([^|]+)|([^|]+)|%d+$')
    if car ~= id or sk ~= skin then kept[#kept + 1] = entry end
  end
  if slot and slot >= 1 and slot <= 6 then kept[#kept + 1] = id .. '|' .. skin .. '|' .. slot end
  overrides:set(table.concat(kept, ';'))
  byIndex[index] = nil
  return true
end
function M.override(index) return findOverride(carID(index), skinID(index)) end
local function category(text)
  text = text:lower()
  if text:find('gt3') or text:find('gt3r') then return 'GT3' end
  if text:find('gt4') then return 'GT4' end
  if text:find('lmp2') then return 'LMP2' end
  if text:find('hypercar') or text:find('lmdh') or text:find('lmh') then return 'HYPERCAR' end
  if text:find('formula') or text:find('rss_formula') or text:find('vrc_formula') then return 'FORMULA' end
  if text:find('tcr') or text:find('touring') then return 'TOURING' end
  return 'OPEN'
end
local lastRules = nil
local function rulesSig()
  local parts = {}
  for i = 1, 6 do
    local enabled, tag, col = rule(i)
    parts[#parts + 1] = (enabled and '1' or '0') .. '|' .. tag .. '|' .. string.format('%f|%f|%f', col.r, col.g, col.b)
  end
  return table.concat(parts, ';')
end
function M.update()
  local sig = rulesSig()
  if sig ~= lastRules then lastRules, byIndex = sig, {} end
  categories = {}
  local sim = ac.getSim()
  if not sim then return end
  for i = 0, sim.carsCount - 1 do
    local car = ac.getCar(i)
    if car and car.isConnected then
      local id = carID(i)
      local skin = skinID(i)
      local current = byIndex[i]
      if not current or current.model ~= id or current.skin ~= skin then
        local name, color = nil, nil
        local slot = findOverride(id, skin)
        if slot then
          local enabled, tag, col = rule(slot)
          if enabled then name, color = ('MC%d %s'):format(slot, tag ~= '' and tag:upper() or ('CLASS ' .. slot)), col end
        end
        if not name then
          local lookup = readTags(id)
          for s = 1, 6 do
            local enabled, tag, col = rule(s)
            if enabled and tag ~= '' and lookup[normalize(tag)] then
              name, color = ('MC%d %s'):format(s, tag:upper()), col
              break
            end
          end
        end
        if not name then
          local okName, model = pcall(ac.getCarName, i)
          name = category(id .. ' ' .. (okName and model or ''))
          color = colors[name]
        end
        current = { model = id, skin = skin, name = name, key = name, color = color }
        byIndex[i] = current
      end
      categories[current.key] = true
    else byIndex[i] = nil end
  end
end
function M.get(idx) return byIndex[idx] or { name = 'OPEN', key = 'OPEN', color = colors.OPEN } end
function M.count()
  local n = 0
  for _ in pairs(categories) do n = n + 1 end
  return n
end
function M.keys()
  local out = {}
  for k in pairs(categories) do out[#out + 1] = k end
  table.sort(out)
  return out
end
local SHORT = { GT3 = 'GT3', GT4 = 'GT4', LMP2 = 'LMP2', HYPERCAR = 'HYP',
  FORMULA = 'FOR', TOURING = 'TCR', OPEN = '' }
-- Compact badge code for tower rows: MC1..MC6 for tag classes, short stock codes.
function M.short(idx)
  local key = M.get(idx).key
  local mc = key:match('^MC(%d)')
  if mc then return 'MC' .. mc end
  if SHORT[key] ~= nil then return SHORT[key] end
  return key:sub(1, 6):upper()
end
local function swatchRow(slot, current)
  for i, preset in ipairs(M.palette) do
    if i > 1 then ui.sameLine() end
    local color = hexColor(preset[2], colors.OPEN)
    if ui.pushStyleColor and ui.StyleColor then
      ui.pushStyleColor(ui.StyleColor.Button, color)
      ui.pushStyleColor(ui.StyleColor.ButtonHovered, color)
      ui.pushStyleColor(ui.StyleColor.ButtonActive, color)
    end
    local picked = ui.button('##mc' .. slot .. 'preset' .. i, vec2(24, 18))
    if ui.popStyleColor then ui.popStyleColor(3) end
    if picked then M.setColor(slot, preset[2]) end
    if ui.itemHovered and ui.itemHovered() and ui.setTooltip then
      ui.setTooltip(preset[1] .. ' ' .. preset[2])
    end
  end
  if ui.colorButton and ui.ColorPickerFlags then
    ui.sameLine()
    local tmp = hexColor(current, colors.OPEN)
    if ui.colorButton('##mc' .. slot .. 'custom', tmp, ui.ColorPickerFlags.NoAlpha, vec2(24, 18)) then
      M.setColor(slot, string.format('#%02X%02X%02X',
        math.floor(tmp.r * 255 + 0.5), math.floor(tmp.g * 255 + 0.5), math.floor(tmp.b * 255 + 0.5)))
    end
    if ui.itemHovered and ui.itemHovered() and ui.setTooltip then ui.setTooltip('Cor personalizada') end
  end
end
function M.settingsUI()
  ui.text('Categoria isolada na torre')
  local cfgmod = require('core.config')
  local sel = cfgmod.get().classSelect
  if ui.radioButton('Automática (categoria do focado)', sel == 'AUTO') then cfgmod.set('classSelect', 'AUTO') end
  if ui.radioButton('Todas as categorias', sel == 'TODAS') then cfgmod.set('classSelect', 'TODAS') end
  for _, key in ipairs(M.keys()) do
    if ui.radioButton('Somente ' .. key, sel == key) then cfgmod.set('classSelect', key) end
  end
  ui.textWrapped('Vale quando “Filtrar a categoria do piloto focado” está ligado. Clique no rodapé da torre para alternar sem abrir ajustes.')
  ui.separator()
  ui.text('Multiclass por tags (ui_car.json)')
  ui.textWrapped('Ative a classe, informe a tag e clique na cor. Override por skin tem prioridade sobre a tag.')
  for s = 1, 6 do
    local enabled, tag, hex = rule(s)
    local store = slots[s]
    if ui.checkbox('Classe ' .. s .. ' ativa', enabled) then store.enabled:set(not enabled) end
    local newTag = ui.inputText('Tag classe ' .. s, tag)
    if newTag ~= tag then store.tag:set(newTag) end
    ui.text('Cor da classe ' .. s .. ':')
    swatchRow(s, hex)
    ui.textColored('Atual: ' .. (tag ~= '' and tag:upper() or 'CLASSE ' .. s), hexColor(hex, colors.OPEN))
    local hint = M.matchHint(tag)
    if hint ~= '' then ui.textWrapped('Detectado: ' .. hint) end
    ui.separator()
  end
  local sim = ac.getSim()
  if sim then
    local car = ac.getCar(sim.focusedCar)
    if car then
      local current = M.override(sim.focusedCar)
      ui.text('Override do focado: ' .. (current and ('classe ' .. current) or 'AUTO por tag'))
      if skinID(sim.focusedCar) ~= '' then
        if ui.button('Override AUTO') then M.setOverride(sim.focusedCar, nil) end
        for s = 1, 6 do
          ui.sameLine()
          if ui.button('MC' .. s) then M.setOverride(sim.focusedCar, s) end
        end
      else
        ui.textWrapped('Sem skin ID: vale só a tag automática.')
      end
    end
  end
end
-- Up to three car IDs whose tags contain the typed rule (settings helper).
function M.matchHint(tag)
  tag = normalize(tag)
  if tag == '' then return '' end
  local sim = ac.getSim()
  if not sim then return '' end
  local found = {}
  for i = 0, math.min(sim.carsCount - 1, 30) do
    if #found >= 3 then break end
    local id = carID(i)
    if id ~= '' and readTags(id)[tag] then found[#found + 1] = id end
  end
  return table.concat(found, ', ')
end
function M.on_session_start() byIndex = {} categories = {} tagCache = {} end
function M.init() end
return M
