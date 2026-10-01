-- ========================================
-- RACE TV // Entry point: one real app window per HUD element.
-- Every FUNCTION_MAIN draws its widget directly, so the CSP
-- "OBS Apps Redirection" tool can redirect windows to OBS
-- (texture "Extra: Redirected apps (transparent)").
-- ========================================
Dt = 0
Time = 0

local tower      = require('widgets.tower')
local speed      = require('widgets.speed')
local pedals     = require('widgets.pedals')
local lap        = require('widgets.lap')
local lowerthird = require('widgets.lowerthird')
local radar      = require('widgets.radar')
local battle     = require('widgets.battle')
local onboard    = require('widgets.onboard')
local tags       = require('widgets.tags')
local alert      = require('widgets.alert')
local mapw       = require('widgets.map')
local lineup     = require('widgets.lineup')
local winsize    = require('core.winsize')
local cfgmod     = require('core.config')
local data       = require('core.data')
local tyres      = require('core.tyres')
local pits       = require('core.pits')
local classes    = require('core.classes')
local sectors   = require('core.sectors')
local control   = require('core.control')
local narrator  = require('widgets.narrator')
local deltaWin  = require('widgets.delta')
local relative  = require('widgets.relative')
local fuel      = require('widgets.fuel')
local sessionW  = require('widgets.session')
local flagW     = require('widgets.flag')
local native = require('core.native')
local rpmod = require('core.rp')
local records = require('core.records')
local resultData = require('core.results')
local resultWindow = require('widgets.results')
local layouts = require('core.layouts')
local branding = require('core.branding')

local windows = {
  { title = 'TV Tower', module = tower, width = 400, height = 446 },
  { title = 'TV Battle', module = battle, width = 632, height = 166 },
  { title = 'TV Onboard Top', module = onboard, width = 480, height = 52 },
  { title = 'TV Telemetry', module = speed, width = 470, height = 80 },
  { title = 'TV Inputs', module = pedals, width = 300, height = 132 },
  { title = 'TV Timing', module = lap, width = 300, height = 170 },
  { title = 'TV Onboard Bar', module = lowerthird, width = 460, height = 92 },
  { title = 'TV Spotter', module = radar, width = 190, height = 210 },
  { title = 'TV Alert', module = alert, width = 460, height = 56 },
  { title = 'TV Map', module = mapw, width = 230, height = 230 },
  { title = 'TV Lineup', module = lineup, width = 680, height = 418 },
  { title = 'TV Narrator', module = narrator, width = 430, height = 430 },
  { title = 'TV Delta', module = deltaWin, width = 460, height = 132 },
  { title = 'TV Relative', module = relative, width = 320, height = 274 },
  { title = 'TV Fuel', module = fuel, width = 300, height = 118 },
  { title = 'TV Session', module = sessionW, width = 460, height = 120 },
  { title = 'TV Flags', module = flagW, width = 460, height = 84 },
  { title = 'TV Results', module = resultWindow, width = 680, height = 460 },
}
layouts.configure(windows)

local init = false
local session_time = nil
local session_key = nil
local lastError = {}

local function safe(fn)
  xpcall(fn, function(err)
    local message = tostring(err)
    if not lastError[message] or Time - lastError[message] >= 5 then
      ac.debug('TV ERROR', message .. '\n' .. debug.traceback())
      ac.log('[Race TV] ' .. message .. '\n' .. debug.traceback())
      lastError[message] = Time
    end
  end)
end

local function session_start(session_index, restarted)
  Time = 0
  lastError = {}
  safe(data.on_session_start)
  safe(tyres.on_session_start)
  safe(pits.on_session_start)
  safe(classes.on_session_start)
  safe(sectors.on_session_start)
  safe(winsize.on_session_start)
  safe(control.on_session_start)
  safe(rpmod.on_session_start)
  safe(native.on_session_start)
  safe(records.on_session_start)
  safe(resultData.on_session_start)
  safe(resultWindow.on_session_start)
  safe(deltaWin.on_session_start)
  safe(relative.on_session_start)
  safe(fuel.on_session_start)
  safe(sessionW.on_session_start)
  safe(flagW.on_session_start)
  safe(tower.on_session_start)
  safe(speed.on_session_start)
  safe(pedals.on_session_start)
  safe(lap.on_session_start)
  safe(lowerthird.on_session_start)
  safe(radar.on_session_start)
  safe(battle.on_session_start)
  safe(onboard.on_session_start)
  safe(tags.on_session_start)
  safe(alert.on_session_start)
  safe(mapw.on_session_start)
  safe(lineup.on_session_start)
  local sim = ac.getSim()
  if sim then session_time = sim.currentSessionTime end
end

local function on_game_close()
  safe(alert.on_release)
end

function script.update(dt)
  cfgmod.refresh()
  safe(layouts.beforeUpdate)
  safe(branding.update)
  Dt = math.max(0, math.min(dt or 0, 0.1))
  local sim = ac.getSim()
  if not sim then return end
  if sim.isPaused then Dt = 0 end
  Time = Time + Dt

  if not init then
    init = true
    ac.onRelease(on_game_close)
    ac.onSessionStart(session_start)
    safe(tower.init)
    safe(rpmod.init)
    safe(control.init)
    safe(speed.init)
    safe(pedals.init)
    safe(lap.init)
    safe(lowerthird.init)
    safe(radar.init)
    safe(battle.init)
    safe(onboard.init)
    safe(tags.init)
    safe(alert.init)
    safe(mapw.init)
    safe(lineup.init)
    ac.log('[Race TV 12.3.0] Stable scaling, narrator controls, manual comparison, crossing gaps, results, layouts and branding.')
  end

  local key = (ac.getTrackID() or '') .. '/' .. (ac.getTrackLayout() or '') .. '#' .. sim.currentSessionIndex
  if key ~= session_key or (session_time and sim.currentSessionTime < session_time - 1000) then
    session_start(sim.currentSessionIndex, true)
    session_key = key
  end
  session_time = sim.currentSessionTime
  safe(function() data.update(Dt) end)
  safe(tyres.update)
  safe(function() pits.update(Dt) end)
  safe(classes.update)
  safe(function() sectors.update(Dt) end)
  safe(function() control.update(Dt) end)
  safe(function() rpmod.update(Dt) end)
  safe(function() native.update(Dt) end)
  safe(records.update)
  safe(resultData.update)
  safe(function() resultWindow.update(Dt) end)

  safe(function() deltaWin.update(Dt) end)
  safe(function() relative.update(Dt) end)
  safe(function() fuel.update(Dt) end)
  safe(function() sessionW.update(Dt) end)
  safe(function() flagW.update(Dt) end)
  safe(function() tower.update(Dt) end)
  safe(function() speed.update(Dt) end)
  safe(function() pedals.update(Dt) end)
  safe(function() lap.update(Dt) end)
  safe(function() lowerthird.update(Dt) end)
  safe(function() radar.update(Dt) end)
  safe(function() battle.update(Dt) end)
  safe(function() onboard.update(Dt) end)
  safe(function() tags.update(Dt) end)
  safe(function() alert.update(Dt) end)
  safe(function() mapw.update(Dt) end)
  safe(function() lineup.update(Dt) end)
  safe(function() winsize.prepare(windows, cfgmod.get()) end)
  safe(winsize.update)
  safe(layouts.afterUpdate)
end

-- ====== WINDOWS (nomes batem com manifest.ini) ======
-- Registrados como global (padrão CMRT) e em script (padrão wiki).
local function export(name, fn)
  pcall(function() _G[name] = fn end)
  script[name] = fn
end

local function bindWindow(base, title, module)
  local opened = false
  export(base .. 'Main', function(dt)
    -- Native window resizing can settle after update. Clip this pass to the
    -- current content area without changing its logical scale or requesting size.
    ui.pushClipRect(vec2(0, 0), ui.windowSize(), true)
    safe(module.main)
    ui.popClipRect()
  end)
  export(base .. 'Show', function(dt)
    -- Duplicate notifications from a resize/render layer must not replay intros.
    if opened or winsize.isResizing(title) then return end
    opened = true
    safe(module.on_open)
  end)
  export(base .. 'Hide', function(dt)
    if not opened then return end
    opened = false
    safe(module.on_close)
  end)
end

bindWindow('vsTower', 'TV Tower', tower)
bindWindow('vsSpeed', 'TV Telemetry', speed)
bindWindow('vsPedals', 'TV Inputs', pedals)
bindWindow('vsLap', 'TV Timing', lap)
bindWindow('vsLower', 'TV Onboard Bar', lowerthird)
bindWindow('vsRadar', 'TV Spotter', radar)
bindWindow('vsBattle', 'TV Battle', battle)
bindWindow('vsOnboard', 'TV Onboard Top', onboard)
bindWindow('vsAlert', 'TV Alert', alert)
bindWindow('vsMap', 'TV Map', mapw)
bindWindow('vsLineup', 'TV Lineup', lineup)
bindWindow('vsNarrator', 'TV Narrator', narrator)
bindWindow('vsDelta', 'TV Delta', deltaWin)
bindWindow('vsRelative', 'TV Relative', relative)
bindWindow('vsFuel', 'TV Fuel', fuel)
bindWindow('vsSession', 'TV Session', sessionW)
bindWindow('vsFlag', 'TV Flags', flagW)
bindWindow('vsResults', 'TV Results', resultWindow)

export('vsSettingsMain', function(dt)
  safe(cfgmod.settingsUI)
end)
