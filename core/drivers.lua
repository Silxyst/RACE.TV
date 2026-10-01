local M = {}
local function text(fn, index)
  local ok, value = pcall(fn, index)
  return ok and tostring(value or '') or ''
end
function M.name(index) return text(ac.getDriverName, index) end
function M.model(index) return text(ac.getCarID or ac.getCarName, index) end
function M.key(index)
  return (M.name(index) .. '\t' .. M.model(index)):gsub('[\r\n]', ' ')
end
function M.valid(index, key)
  if type(index) ~= 'number' or index < 0 or index ~= math.floor(index) then return false end
  local car = ac.getCar(index)
  return car ~= nil and car.isConnected and car.isActive and (not key or M.key(index) == key)
end
return M
