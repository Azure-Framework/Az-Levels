-- client_ui.lua

local totalRP, statRP, lastLevel = 0, {}, 0
local uiOpen = false

-- Simple quadratic RP curve
local function rpForLevel(x)
  return 100 * x * x
end

local function getLevelInfo(rp)
  local lvl = 1
  while rpForLevel(lvl + 1) <= rp do lvl = lvl + 1 end
  local cur = rpForLevel(lvl)
  local nxt = rpForLevel(lvl + 1)
  local prog = (rp - cur) / (nxt - cur)
  return {
    level    = lvl,
    progress = prog,
    rp       = rp,
    rpToNext = nxt - rp,
    rpMax    = nxt
  }
end

-- Fetch initial RP on resource start or spawn
AddEventHandler('onClientResourceStart', function(res)
  if res == GetCurrentResourceName() then
    TriggerServerEvent('level:loadStatsRP')
  end
end)
AddEventHandler('playerSpawned', function()
  TriggerServerEvent('level:loadStatsRP')
end)

-- Receive initial pools (no pop-up)
RegisterNetEvent('level:setStatsRP')
AddEventHandler('level:setStatsRP', function(data)
  totalRP = data.total
  statRP  = { stamina = data.stamina, strength = data.strength, driving = data.driving }
  lastLevel = getLevelInfo(totalRP).level
end)

-- Receive RP updates
RegisterNetEvent('level:updateStatsRP')
AddEventHandler('level:updateStatsRP', function(data)
  local oldLevel = getLevelInfo(totalRP).level
  totalRP        = data.total
  statRP         = { stamina = data.stamina, strength = data.strength, driving = data.driving }
  local info     = getLevelInfo(totalRP)

  -- true level-up: fire top bar
  if info.level > oldLevel then
    SendNUIMessage({
      type     = "levelup",
      oldLevel = oldLevel,
      newLevel = info.level,
      progress = info.progress,
      rp       = info.rp,
      rpMax    = info.rpMax
    })
  end

  -- refresh manual UI if open
  if uiOpen then
    SendNUIMessage({
      type     = "refresh",
      level    = info.level,
      progress = info.progress,
      rp       = info.rp,
      rpToNext = info.rpToNext,
      stats    = {
        stamina  = statRP.stamina  / 1000,
        strength = statRP.strength / 1000,
        driving  = statRP.driving  / 1000
      },
      statsText = {
        stamina  = string.format("%d/1000", statRP.stamina),
        strength = string.format("%d/1000", statRP.strength),
        driving  = string.format("%d/1000", statRP.driving)
      }
    })
  end
end)

-- Manual full-panel show
RegisterCommand("showlevel", function()
  local info = getLevelInfo(totalRP)
  SendNUIMessage({
    type     = "show",
    level    = info.level,
    progress = info.progress,
    rp       = info.rp,
    rpToNext = info.rpToNext,
    stats    = {
      stamina  = statRP.stamina  / 1000,
      strength = statRP.strength / 1000,
      driving  = statRP.driving  / 1000
    },
    statsText = {
      stamina  = string.format("%d/1000", statRP.stamina),
      strength = string.format("%d/1000", statRP.strength),
      driving  = string.format("%d/1000", statRP.driving)
    }
  })
  SetNuiFocus(true, true)
  uiOpen = true
end)

-- Hide callback
RegisterNUICallback("hide", function(_, cb)
  SetNuiFocus(false, false)
  uiOpen = false
  cb("ok")
end)
