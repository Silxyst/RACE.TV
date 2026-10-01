-- RACE TV v12 // Relative: rivais próximos do focado, com clique para focar.
local M = {}
local config, draw = require('core.config'), require('core.draw')
local anim, data = require('core.anim'), require('core.data')
local native = require('core.native')
local time, intro = 0, 0
local frameSerial, lastClickFrame = 0, -1
local WINDOW, AHEAD, BEHIND, MAXGAP = 320, 3, 3, 8
function M.init() end
function M.on_open() end
function M.on_close() end
function M.on_session_start() time, intro, lastClickFrame = 0, 0, -1 end
function M.update(dt)
  frameSerial = frameSerial + 1
  time = time + (dt or 0.016)
  intro = math.min(1, intro + dt * 2.6)
end

local function signedGap(focused, entry)
  local direct = native.gapToFocused(entry.idx)
  if direct then
    if math.abs(direct) > MAXGAP then return nil end
    return direct
  end
  if not focused or entry.idx == focused.idx then return 0 end
  local diff = data.progress(focused.car) - data.progress(entry.car)
  if diff == 0 or math.abs(diff) >= 1 then return nil end
  local seconds = data.gap(diff > 0 and entry or focused, diff > 0 and focused or entry)
  if not seconds then return nil end
  if seconds > MAXGAP then return nil end
  return diff > 0 and seconds or -seconds
end

local function build(sim)
  local focused = sim and data.byIndex[sim.focusedCar]
  if not focused then return nil, {} end
  local ahead, behind = {}, {}
  for _, e in ipairs(data.list) do
    if e.idx ~= focused.idx then
      local gap = signedGap(focused, e)
      if gap then
        if gap < -0.001 then ahead[#ahead + 1] = { entry = e, gap = gap }
        elseif gap > 0.001 then behind[#behind + 1] = { entry = e, gap = gap } end
      end
    end
  end
  table.sort(ahead, function(a, b) return a.gap > b.gap end)
  table.sort(behind, function(a, b) return a.gap < b.gap end)
  local view = {}
  for i = math.max(1, #ahead - AHEAD + 1), #ahead do view[#view + 1] = ahead[i] end
  view[#view + 1] = { entry = focused, gap = 0, self = true }
  for i = 1, math.min(BEHIND, #behind) do view[#view + 1] = behind[i] end
  return focused, view
end

function M.size()
  local sim = ac.getSim()
  local _, view = build(sim)
  return WINDOW, 64 + math.max(1, #view) * 27
end

function M.main()
  local cfg, sim = config.get(), ac.getSim()
  if not sim then return end
  local focused, view = build(sim)
  if not focused or #view == 0 then return end
  local k = cfg.scale
  local headH, rowH, footH = 40 * k, 27 * k, 24 * k
  local W, H = WINDOW * k, (64 + #view * 27) * k
  local alpha = anim.ease_out_quart(intro)

  ui.pushClipRect(vec2(0, 0), vec2(W, H), true)
  draw.card(0, 0, W, H, cfg.brand1, alpha)
  draw.textF(draw.FONT_HEAD, 12 * k, 8 * k, 'RELATIVE', 13 * k, draw.fade(draw.WHITE, alpha),
    ui.Alignment.Start, 160 * k, 20 * k)
  local okN, nm = pcall(ac.getDriverName, focused.idx)
  local who = (okN and nm and #tostring(nm) > 0) and draw.fullName(nm, 18) or ''
  if who ~= '' then
    draw.textF(draw.FONT_TXT, W - 172 * k, 8 * k, who, 10 * k, draw.fade(draw.PHIL_GRAY, alpha),
      ui.Alignment.End, 160 * k, 20 * k)
  end
  ui.pushClipRect(vec2(0, headH), vec2(W, headH + #view * rowH), true)
  local clicked
  for r, item in ipairs(view) do
    local e, y = item.entry, headH + (r - 1) * rowH
    local isSelf = item.self == true
    if isSelf then
      ui.drawRectFilled(vec2(6 * k, y + 1 * k), vec2(W - 6 * k, y + rowH - 1 * k),
        rgbm(1, 1, 1, 0.94 * alpha), 5)
    else
      ui.drawRectFilled(vec2(6 * k, y + 1 * k), vec2(W - 6 * k, y + rowH - 1 * k),
        rgbm(1, 1, 1, (r % 2 == 0 and 0.05 or 0.025) * alpha), 5)
    end
    local ink = isSelf and draw.PHIL_BG or draw.WHITE
    local cc = require('core.classes').get(e.idx).color
    ui.drawRectFilled(vec2(6 * k, y + 4 * k), vec2(9 * k, y + rowH - 4 * k), draw.fade(cc, alpha))
    draw.textF(draw.FONT_NUM, 4 * k, y, e.rank or e.pos, 13 * k, draw.fade(ink, alpha),
      ui.Alignment.Center, 26 * k, rowH)
    local okD, dn = pcall(ac.getDriverName, e.idx)
    local dname = (okD and dn and #tostring(dn) > 0) and draw.fullName(dn, 20) or '---'
    draw.textF(draw.FONT_BOLD, 34 * k, y, dname, 12 * k, draw.fade(ink, alpha),
      ui.Alignment.Start, W - 134 * k, rowH)
    local gapTxt = isSelf and 'FOCADO' or string.format('%+.2f', item.gap)
    local gcol = isSelf and ink or (item.gap < 0 and draw.RED or draw.GREEN)
    if not isSelf and math.abs(item.gap) < 1 then gcol = draw.YELLOW end
    draw.textF(draw.FONT_SEMI, W - 96 * k, y, gapTxt, 12 * k, draw.fade(gcol, alpha),
      ui.Alignment.End, 90 * k, rowH)
    if not isSelf and alpha > 0.25 then
      ui.setCursor(vec2(6 * k, y + 1 * k))
      if ui.invisibleButton('##race_tv_rel_' .. e.idx, vec2(W - 12 * k, rowH - 2 * k),
        ui.ButtonFlags.PressedOnClick + ui.ButtonFlags.NoNavFocus) then clicked = e.idx end
      if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        ui.setTooltip('Clique para acompanhar ' .. dname)
      end
    end
  end
  ui.popClipRect()
  draw.textF(draw.FONT_TXT, 0, headH + #view * rowH, 'RIVAIS ±' .. MAXGAP .. 'S', 10 * k,
    draw.fade(draw.dim(0.85), alpha), ui.Alignment.Center, W, footH)
  ui.popClipRect()
  if clicked ~= nil and lastClickFrame ~= frameSerial then
    local car = ac.getCar(clicked)
    if car and car.isConnected and car.isActive then
      lastClickFrame = frameSerial
      ac.focusCar(clicked)
    end
  end
end
return M
