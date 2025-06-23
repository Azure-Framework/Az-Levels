local STAT_COLUMNS = {
  stamina  = "rp_stamina",
  strength = "rp_strength",
  driving  = "rp_driving"
}

local function dprint(...)
  print("[AZ-LEVELS SERVER]", ...)
end

local function getLicense(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:match("^license:") then return id end
  end
  return nil
end

-- internal: ensure default row
local function ensureRow(lic, cb)
  MySQL.Async.fetchAll(
    "SELECT identifier FROM user_levels WHERE identifier = @id",
    { ['@id'] = lic },
    function(res)
      if not res or #res == 0 then
        MySQL.Async.execute(
          "INSERT INTO user_levels (identifier) VALUES (@id)",
          { ['@id'] = lic },
          function() cb() end
        )
      else
        cb()
      end
    end
  )
end

-- internal: fetch full stats
local function loadStatsInternal(lic, cb)
  ensureRow(lic, function()
    MySQL.Async.fetchAll(
      [[SELECT rp_total, rp_stamina, rp_strength, rp_driving
        FROM user_levels WHERE identifier = @id]],
      { ['@id'] = lic },
      function(results)
        local r = results[1]
        cb({
          total    = tonumber(r.rp_total),
          stamina  = tonumber(r.rp_stamina),
          strength = tonumber(r.rp_strength),
          driving  = tonumber(r.rp_driving)
        })
      end
    )
  end)
end

-- internal: modify a stat value
local function modifyStatInternal(lic, stat, delta, cb)
  local col = STAT_COLUMNS[stat]
  if not col then return cb(false, 'invalid_stat') end
  ensureRow(lic, function()
    MySQL.Async.execute(
      string.format(
        [[UPDATE user_levels SET rp_total = rp_total + @amt, %s = %s + @amt WHERE identifier = @id]],
        col, col
      ),
      { ['@amt'] = delta, ['@id'] = lic },
      function() cb(true) end
    )
  end)
end

-- internal: set a stat value
local function setStatInternal(lic, stat, value, cb)
  local col = STAT_COLUMNS[stat]
  if not col or type(value) ~= 'number' then return cb(false, 'invalid') end
  ensureRow(lic, function()
    MySQL.Async.execute(
      string.format(
        [[UPDATE user_levels SET %s = @val, rp_total = (rp_stamina + rp_strength + rp_driving + @val - %s) WHERE identifier = @id]],
        col, col
      ),
      { ['@val'] = value, ['@id'] = lic },
      function() cb(true) end
    )
  end)
end

-- internal: remove stat (subtract)
local function removeStatInternal(lic, stat, delta, cb)
  modifyStatInternal(lic, stat, -math.abs(delta), cb)
end

-- exports
exports('getStats', function(src, cb)
  local lic = getLicense(src)
  if not lic then return cb(nil) end
  loadStatsInternal(lic, cb)
end)

exports('checkStat', function(src, stat, cb)
  local lic = getLicense(src)
  if not lic then return cb(false) end
  loadStatsInternal(lic, function(stats)
    cb(stats[stat] ~= nil)
  end)
end)

exports('addStat', function(src, stat, amount, cb)
  if amount <= 0 then return cb(false, 'invalid_amount') end
  local lic = getLicense(src)
  if not lic then return cb(false, 'no_license') end
  modifyStatInternal(lic, stat, amount, cb)
end)

exports('removeStat', function(src, stat, amount, cb)
  if amount <= 0 then return cb(false, 'invalid_amount') end
  local lic = getLicense(src)
  if not lic then return cb(false, 'no_license') end
  removeStatInternal(lic, stat, amount, cb)
end)

exports('updateStat', function(src, stat, value, cb)
  local lic = getLicense(src)
  if not lic then return cb(false, 'no_license') end
  setStatInternal(lic, stat, value, cb)
end)

-- legacy events
RegisterNetEvent('level:loadStatsRP')
AddEventHandler('level:loadStatsRP', function()
  local src = source
  exports['Az-Levels']:getStats(src, function(stats)
    if stats then
      TriggerClientEvent('level:setStatsRP', src, stats)
    end
  end)
end)

RegisterNetEvent('level:addStatRP')
AddEventHandler('level:addStatRP', function(stat, amt)
  local src = source
  exports['Az-Levels']:addStat(src, stat, amt, function(ok)
    if ok then
      exports['Az-Levels']:getStats(src, function(stats)
        TriggerClientEvent('level:updateStatsRP', src, stats)
      end)
    end
  end)
end)
