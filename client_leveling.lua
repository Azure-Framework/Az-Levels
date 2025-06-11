-- client_leveling.lua

local function award(stat, amt)
  if amt > 0 then
    TriggerServerEvent('level:addStatRP', stat, amt)
  end
end

-- 1) Play-time → Stamina: 10 RP per minute
Citizen.CreateThread(function()
  local acc = 0
  while true do
    Citizen.Wait(1000)
    acc = acc + 1
    if acc >= 60 then
      acc = acc - 60
      award("stamina", 10)
    end
  end
end)

-- 2) Driving → Driving: 0.5 RP per meter
Citizen.CreateThread(function()
  local acc, lastPos = 0.0, nil
  while true do
    Citizen.Wait(1000)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
      local pos = GetEntityCoords(GetVehiclePedIsIn(ped, false))
      if lastPos then
        local d = #(pos - lastPos)
        acc = acc + d * 0.5
      end
      lastPos = pos
      if acc >= 1 then
        local give = math.floor(acc)
        acc = acc - give
        award("driving", give)
      end
    else
      lastPos = nil
    end
  end
end)

-- 3) Running → Strength: 1 RP per 2 meters
Citizen.CreateThread(function()
  local acc, lastPos = 0.0, nil
  while true do
    Citizen.Wait(1000)
    local ped = PlayerPedId()
    if IsPedRunning(ped) then
      local pos = GetEntityCoords(ped)
      if lastPos then
        local d = #(pos - lastPos)
        acc = acc + d * 0.5
      end
      lastPos = pos
      if acc >= 1 then
        local give = math.floor(acc)
        acc = acc - give
        award("strength", give)
      end
    else
      lastPos = nil
    end
  end
end)

-- Test command: /testrp [stamina|strength|driving] [amount]
RegisterCommand("testrp", function(_, args)
  local stat, amt = args[1], tonumber(args[2])
  if stat and amt then
    award(stat, amt)
  else
    print("Usage: /testrp [stamina|strength|driving] [amount]")
  end
end)
