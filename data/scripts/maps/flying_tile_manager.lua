-- This script enables flying tiles on a map.

local flying_tile_manager = {}

function flying_tile_manager:create_flying_tiles(map, prefix)

  local next_index = 1  -- Index of the next flying tile to spawn.

  local function spawn_next()

    map:get_entity(prefix .. "_enemy_" .. next_index):set_enabled(true)
    map:get_entity(prefix .. "_after_" .. next_index):set_enabled(true)
    next_index = next_index + 1
  end

  -- Start the attack of flying tiles
  -- (this function can be called when the hero enters the room of flying tiles).
  local function start_flying_tiles()

    local total = map:get_entities_count(prefix .. "_enemy")
    local spawn_delay = 1500  -- Delay between two flying tiles.

    map:set_entities_enabled(prefix .. "_enemy", false)
    map:set_entities_enabled(prefix .. "_after", false)

    -- Spawn a tile and schedule the next one.
    spawn_next()
    sol.timer.start(map, spawn_delay, function()
      spawn_next()
      return next_index <= total
    end)

    -- Play a sound repeatedly as long as at least one tile is moving.
    sol.timer.start(map, 150, function()

      sol.audio.play_sound("walk_on_grass")

      -- Repeat the sound until the last tile starts animation "destroy".
      local again = false
      local remaining = map:get_entities_count(prefix .. "_enemy")
      if remaining > 1 then
        again = true
      elseif remaining == 1 then
        for enemy in map:get_entities(prefix .. "_enemy_") do
          local sprite = enemy:get_sprite()
          if sprite and sprite:get_animation() ~= "destroy" then
            again = true
            break
          end
        end
      end

      if not again then
        map:open_doors(prefix .. "_door")
      end
      return again
    end)
  end

  local function sensor_on_activated(sensor)

    local first_door
    for door in map:get_entities(prefix .. "_door") do
      first_door = door
      break
    end

    local first_enemy = map:get_entity(prefix .. "_enemy_1")

    if first_door:is_open()
        and first_enemy ~= nil then
      map:close_doors(prefix .. "_door")
      sol.timer.start(2000, function()
        start_flying_tiles()
      end)
    end
  end

  for sensor in map:get_entities(prefix .. "_sensor") do
    sensor.on_activated = sensor_on_activated
  end

  map:set_entities_enabled(prefix .. "_enemy", false)
  map:set_entities_enabled(prefix .. "_after", false)
  map:set_doors_open(prefix .. "_door", true)
end

return flying_tile_manager
