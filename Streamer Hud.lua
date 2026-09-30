-- ========================================
-- RACE TV v3 // Streamer Hud.lua
-- Replica PHIL TV: tower + battle + onboard + telemetry + tags
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
local director   = require('widgets.director')
local mapw       = require('widgets.map')
local lineup     = require('widgets.lineup')
local layout     = require('core.layout')
local cfgmod     = require('core.config')

local init = false
local M_layoutDone = false
local session_time = -999999
local err_count = 1

local function safe(fn)
  xpcall(fn, function(err)
    ac.debug('TV ERROR ' .. tostring(err_count), tostring(err) .. '\n' .. debug.traceback())
    err_count = err_count + 1
  end)
end

local function session_start(session_index, restarted)
  M_layoutDone = false
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
  safe(director.on_session_start)
  safe(mapw.on_session_start)
  safe(lineup.on_session_start)
end

local function on_game_close()
end

function script.update(dt)
  err_count = 1
  Dt = dt or 0.016
  Time = Time + Dt

  local sim = ac.getSim()

  if not init then
    init = true
    pcall(ac.onRelease, on_game_close, nil)
    pcall(ac.onSessionStart, session_start)
    safe(tower.init)
    safe(speed.init)
    safe(pedals.init)
    safe(lap.init)
    safe(lowerthird.init)
    safe(radar.init)
    safe(battle.init)
    safe(onboard.init)
    safe(tags.init)
    safe(alert.init)
    safe(director.init)
    safe(mapw.init)
    safe(lineup.init)
  end

  if sim and sim.isOnlineRace then
    if sim.currentSessionTime and sim.currentSessionTime < session_time then
      session_start(-1, -1)
    end
  end
  if sim then session_time = sim.currentSessionTime or 0 end

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
  safe(function() director.update(Dt) end)
  safe(function() mapw.update(Dt) end)
  safe(function() lineup.update(Dt) end)
  -- auto-layout uma vez por sessão (se ativado)
  if not M_layoutDone then
    local cfg = nil
    pcall(function() cfg = cfgmod.get() end)
    if cfg and cfg.autoLayout then
      pcall(layout.apply)
      M_layoutDone = true
    end
  end
end

-- ====== WINDOWS (nomes batem com manifest.ini) ======
function vsTowerMain(dt) safe(tower.main) end
function vsTowerShow(dt) safe(tower.on_open) end
function vsTowerHide(dt) safe(tower.on_close) end

function vsSpeedMain(dt) safe(speed.main) end
function vsSpeedShow(dt) safe(speed.on_open) end
function vsSpeedHide(dt) safe(speed.on_close) end

function vsPedalsMain(dt) safe(pedals.main) end
function vsPedalsShow(dt) safe(pedals.on_open) end
function vsPedalsHide(dt) safe(pedals.on_close) end

function vsLapMain(dt) safe(lap.main) end
function vsLapShow(dt) safe(lap.on_open) end
function vsLapHide(dt) safe(lap.on_close) end

function vsLowerMain(dt) safe(lowerthird.main) end
function vsLowerShow(dt) safe(lowerthird.on_open) end
function vsLowerHide(dt) safe(lowerthird.on_close) end

function vsRadarMain(dt) safe(radar.main) end
function vsRadarShow(dt) safe(radar.on_open) end
function vsRadarHide(dt) safe(radar.on_close) end

function vsBattleMain(dt) safe(battle.main) end
function vsBattleShow(dt) safe(battle.on_open) end
function vsBattleHide(dt) safe(battle.on_close) end

function vsOnboardMain(dt) safe(onboard.main) end
function vsOnboardShow(dt) safe(onboard.on_open) end
function vsOnboardHide(dt) safe(onboard.on_close) end

function vsAlertMain(dt) safe(alert.main) end
function vsAlertShow(dt) safe(alert.on_open) end
function vsAlertHide(dt) safe(alert.on_close) end

function vsMapMain(dt) safe(mapw.main) end
function vsMapShow(dt) safe(mapw.on_open) end
function vsMapHide(dt) safe(mapw.on_close) end

function vsLineupMain(dt) safe(lineup.main) end
function vsLineupShow(dt) safe(lineup.on_open) end
function vsLineupHide(dt) safe(lineup.on_close) end

function vsSettingsMain(dt)
  safe(cfgmod.settingsUI)
end
