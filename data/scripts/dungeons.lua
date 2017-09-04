-- Defines the dungeon information of a game.

-- Usage:
-- require("scripts/dungeons")

require("scripts/multi_events")

local function initialize_dungeon_features(game)

  if game.get_dungeon ~= nil then
    -- Already done.
    return
  end

  -- Define the existing dungeons and their floors for the minimap menu.
  local dungeons_info = {

    [1] = {
      floor_width = 1920,
      floor_height = 1200,
      lowest_floor = -2,
      highest_floor = 1,
      maps = {
        "dungeon_1/b2",
        "dungeon_1/b1",
        "dungeon_1/1f",
        "dungeon_1/2f",
      },
      boss = {
        floor = 1,
        savegame_variable = "dungeon_1_boss",
        x = 960,
        y = 480 + 224,
      },
    },

    [2] = {
      floor_width = 960,
      floor_height = 720,
      lowest_floor = 0,
      highest_floor = 8,
      maps = {
        "dungeon_2/1f",
        "dungeon_2/2f",
        "dungeon_2/3f",
        "dungeon_2/4f",
        "dungeon_2/5f",
        "dungeon_2/6f",
        "dungeon_2/7f",
        "dungeon_2/8f",
        "dungeon_2/9f",
      },
      boss = {
        floor = 8,
        savegame_variable = "dungeon_2_boss",
        x = 320,
        y = 240,
      },
    },
  }

  -- Returns the index of the current dungeon if any, or nil.
  function game:get_dungeon_index()

    local world = game:get_map():get_world()
    if world == nil then
      return nil
    end
    local index = tonumber(world:match("^dungeon_([0-9]+)$"))
    return index
  end

  -- Returns the current dungeon if any, or nil.
  function game:get_dungeon()

    local index = game:get_dungeon_index()
    return dungeons_info[index]
  end

  function game:is_dungeon_finished(dungeon_index)
    return game:get_value("dungeon_" .. dungeon_index .. "_finished")
  end

  function game:set_dungeon_finished(dungeon_index, finished)
    if finished == nil then
      finished = true
    end
    game:set_value("dungeon_" .. dungeon_index .. "_finished", finished)
  end

  function game:has_dungeon_map(dungeon_index)

    dungeon_index = dungeon_index or game:get_dungeon_index()
    return game:get_value("dungeon_" .. dungeon_index .. "_map")
  end

  function game:has_dungeon_compass(dungeon_index)

    dungeon_index = dungeon_index or game:get_dungeon_index()
    return game:get_value("dungeon_" .. dungeon_index .. "_compass")
  end

  function game:has_dungeon_big_key(dungeon_index)

    dungeon_index = dungeon_index or game:get_dungeon_index()
    return game:get_value("dungeon_" .. dungeon_index .. "_big_key")
  end

  function game:has_dungeon_boss_key(dungeon_index)

    dungeon_index = dungeon_index or game:get_dungeon_index()
    return game:get_value("dungeon_" .. dungeon_index .. "_boss_key")
  end

  -- Returns the name of the boolean variable that stores the exploration
  -- of dungeon room, or nil.
  function game:get_explored_dungeon_room_variable(dungeon_index, floor, room)

    dungeon_index = dungeon_index or game:get_dungeon_index()
    room = room or 1

    if floor == nil then
      if game:get_map() ~= nil then
        floor = game:get_map():get_floor()
      else
        floor = 0
      end
    end

    local room_name
    if floor >= 0 then
      room_name = tostring(floor + 1) .. "f_" .. room
    else
      room_name = math.abs(floor) .. "b_" .. room
    end

    return "dungeon_" .. dungeon_index .. "_explored_" .. room_name
  end

  -- Returns whether a dungeon room has been explored.
  function game:has_explored_dungeon_room(dungeon_index, floor, room)

    return self:get_value(
      self:get_explored_dungeon_room_variable(dungeon_index, floor, room)
    )
  end

  -- Changes the exploration state of a dungeon room.
  function game:set_explored_dungeon_room(dungeon_index, floor, room, explored)

    if explored == nil then
      explored = true
    end

    self:set_value(
      self:get_explored_dungeon_room_variable(dungeon_index, floor, room),
      explored
    )
  end

end

-- Set up dungeon features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_dungeon_features)

return true
