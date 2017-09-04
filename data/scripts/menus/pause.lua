-- Script that creates a pause menu for a game.

-- Usage:
-- require("scripts/menus/pause")

require("scripts/multi_events")

-- Creates a pause menu for the specified game.
local function initialize_pause_features(game)

  if game.pause_menu ~= nil then
    -- Already done.
    return
  end

  local inventory_builder = require("scripts/menus/pause_inventory")
  local map_builder = require("scripts/menus/pause_map")
  local quest_status_builder = require("scripts/menus/pause_quest_status")
  local options_builder = require("scripts/menus/pause_options")

  local pause_menu = {}
  game.pause_menu = pause_menu

  function pause_menu:on_started()

    -- Define the available submenus.

    game.pause_submenus = {  -- Array of submenus (inventory, map, etc.).
      inventory_builder:new(game),
      map_builder:new(game),
      quest_status_builder:new(game),
      options_builder:new(game),
    }

    -- Select the submenu that was saved if any.
    local submenu_index = game:get_value("pause_last_submenu") or 1
    if submenu_index <= 0
        or submenu_index > #game.pause_submenus then
      submenu_index = 1
    end
    game:set_value("pause_last_submenu", submenu_index)

    -- Play the sound of pausing the game.
    sol.audio.play_sound("pause_open")

    -- Start the selected submenu.
    sol.menu.start(pause_menu, game.pause_submenus[submenu_index])
  end

  function pause_menu:open()
    sol.menu.start(game, pause_menu, false)
  end

  function pause_menu:close()
    sol.menu.stop(pause_menu)
  end

  function pause_menu:on_finished()

    -- Play the sound of unpausing the game.
    sol.audio.play_sound("pause_closed")

    game.pause_submenus = {}

    -- Restore the built-in effect of action and attack commands.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      game:set_custom_command_effect("attack", nil)
    end
  end

  game:register_event("on_paused", function(game)
    pause_menu:open()
  end)
  game:register_event("on_unpaused", function(game)
    pause_menu:close()
  end)

end

-- Set up the pause menu on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_pause_features)

return true
