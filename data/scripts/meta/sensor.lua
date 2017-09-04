-- Initialize sensor behavior specific to this quest.

local sensor_meta = sol.main.get_metatable("sensor")

function sensor_meta:on_activated()

  local hero = self:get_map():get_hero()
  local game = self:get_game()
  local map = self:get_map()
  local name = self:get_name()

  if name == nil then
    return
  end

  -- Sensors named "to_layer_X_sensor" move the hero on that layer.
  -- TODO use a custom entity or a wall to block enemies and thrown items?
  if name:match("^layer_up_sensor") then
    local x, y, layer = hero:get_position()
    if layer < map:get_max_layer() then
      hero:set_position(x, y, layer + 1)
    end
    return
  elseif name:match("^layer_down_sensor") then
    local x, y, layer = hero:get_position()
    if layer > map:get_min_layer() then
      hero:set_position(x, y, layer - 1)
    end
    return
  end

  -- Sensors prefixed by "save_solid_ground_sensor" are where the hero come back
  -- when falling into a hole or other bad ground.
  if name:match("^save_solid_ground_sensor") then
    hero:save_solid_ground()
    return
  end

  -- Sensors prefixed by "reset_solid_ground_sensor" clear any place for the hero
  -- to come back when falling into a hole or other bad ground.
  if name:match("^reset_solid_ground_sensor") then
    hero:reset_solid_ground()
    return
  end

  -- Sensors prefixed by "dungeon_room_N" save the exploration state of the
  -- room "N" of the current dungeon floor.
  local room = name:match("^dungeon_room_(%d+)")
  if room ~= nil then
    game:set_explored_dungeon_room(nil, nil, tonumber(room))
    self:remove()
    return
  end

  -- Sensors named "open_quiet_X_sensor" silently open doors prefixed with "X".
  local door_prefix = name:match("^open_quiet_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:set_doors_open(door_prefix, true)
    return
  end

  -- Sensors named "close_quiet_X_sensor" silently close doors prefixed with "X".
  door_prefix = name:match("^close_quiet_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:set_doors_open(door_prefix, false)
    return
  end

  -- Sensors named "open_loud_X_sensor" open doors prefixed with "X".
  local door_prefix = name:match("^open_loud_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:open_doors(door_prefix)
    return
  end

  -- Sensors named "close_loud_X_sensor" close doors prefixed with "X".
  door_prefix = name:match("^close_loud_([a-zA-X0-9_]+)_sensor")
  if door_prefix ~= nil then
    map:close_doors(door_prefix)
    return
  end

  -- Sensors named "start_dark_sensor" put the map in the dark.
  local dark_prefix = name:match("^start_dark_sensor")
  if dark_prefix ~= nil then
    map:set_light(0)
    return
  end

  -- Sensors named "stop_dark_sensor" put back the map in the light.
  local dark_prefix = name:match("^stop_dark_sensor")
  if dark_prefix ~= nil then
    map:set_light(1)
    return
  end

end

function sensor_meta:on_activated_repeat()

  local hero = self:get_map():get_hero()
  local game = self:get_game()
  local map = self:get_map()
  local name = self:get_name()

  -- Sensors called open_house_xxx_sensor automatically open an outside house door tile.
  local door_name = name:match("^open_house_([a-zA-X0-9_]+)_sensor")
  if door_name ~= nil then
    local door = map:get_entity(door_name)
    if door ~= nil then
      if hero:get_direction() == 1
	         and door:is_enabled() then
        door:set_enabled(false)
        sol.audio.play_sound("door_open")
      end
    end
  end
end

return true
