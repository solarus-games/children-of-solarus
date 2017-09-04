-- Script that creates a head-up display for a game.

-- Usage:
-- require("scripts/hud/hud")

require("scripts/multi_events")
local hud_config = require("scripts/hud/hud_config")

-- Creates and runs a HUD for the specified game.
local function initialize_hud_features(game)

  if game.set_hud_enabled ~= nil then
    -- Already done.
    game:set_hud_enabled(true)
    return
  end

  -- Set up the HUD.
  local hud = {
    enabled = false,
    elements = {},
    showing_dialog = false,
    top_left_opacity = 255,
    custom_command_effects = {},
  }

  local item_icons = {}
  local action_icon
  local attack_icon

  function game:get_hud()
    return hud
  end

  -- Returns whether the HUD is currently shown.
  function game:is_hud_enabled()
    return hud:is_enabled()
  end

  -- Enables or disables the HUD.
  function game:set_hud_enabled(enable)
    return hud:set_enabled(enable)
  end

  function game:get_custom_command_effect(command)

    return hud.custom_command_effects[command]
  end

  -- Make the action (or attack) icon of the HUD show something else than the
  -- built-in effect or the action (or attack) command.
  -- You are responsible to override the command if you don't want the built-in
  -- effect to be performed.
  -- Set the effect to nil to show the built-in effect again.
  function game:set_custom_command_effect(command, effect)

    hud.custom_command_effects[command] = effect
  end

  -- Destroys the HUD.
  function hud:quit()

    if hud:is_enabled() then
      -- Stop all HUD elements.
      hud:set_enabled(false)
    end
  end

  -- Call this function to notify the HUD that the current map has changed.
  local function hud_on_map_changed(game, map)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just paused.
  local function hud_on_paused(game)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just unpaused.
  local function hud_on_unpaused(game)

    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
    end
  end

  -- Called periodically to change the transparency or position of icons.
  local function check_hud()

    local map = game:get_map()
    if map ~= nil then
      -- If the hero is below the top-left icons, make them semi-transparent.
      local hero = map:get_entity("hero")
      local hero_x, hero_y = hero:get_position()
      local camera_x, camera_y = map:get_camera():get_position()
      local x = hero_x - camera_x
      local y = hero_y - camera_y
      local opacity = nil

      if hud.top_left_opacity == 255
        and not game:is_suspended()
        and x < 88
        and y < 80 then
        opacity = 96
      elseif hud.top_left_opacity == 96
        and (game:is_suspended()
        or x >= 88
        or y >= 80) then
        opacity = 255
      end

      if opacity ~= nil then
        hud.top_left_opacity = opacity
        for i, element_config in ipairs(hud_config) do
          if element_config.x >= 0 and element_config.x < 72 and
              element_config.y >= 0 and element_config.y < 64 then
            hud.elements[i]:get_surface():set_opacity(opacity)
          end
        end
      end

      -- During a dialog, move the action icon and the sword icon.
      if not hud.showing_dialog and
        game:is_dialog_enabled() then
        hud.showing_dialog = true
        action_icon:set_dst_position(0, 54)
        attack_icon:set_dst_position(0, 29)
      elseif hud.showing_dialog and
        not game:is_dialog_enabled() then
        hud.showing_dialog = false
        action_icon:set_dst_position(26, 51)
        attack_icon:set_dst_position(13, 29)
      end
    end

    return true  -- Repeat the timer.
  end

  -- Returns whether the HUD is currently enabled.
  function hud:is_enabled()
    return hud.enabled
  end

  -- Enables or disables the HUD.
  function hud:set_enabled(enabled)

    if enabled ~= hud.enabled then
      hud.enabled = enabled

      for _, menu in ipairs(hud.elements) do
        if enabled then
          -- Start each HUD element.
          sol.menu.start(game, menu)
        else
          -- Stop each HUD element.
          sol.menu.stop(menu)
        end
      end

      if enabled then
        sol.timer.start(hud, 50, check_hud)
      end
    end
  end

  -- Changes the opacity of an item icon.
  function hud:set_item_icon_opacity(item_index, opacity)
    item_icons[item_index].get_surface():set_opacity(opacity)
  end

  for _, element_config in ipairs(hud_config) do
    local element_builder = require(element_config.menu_script)
    local element = element_builder:new(game, element_config)
    if element.set_dst_position ~= nil then
      -- Compatibility with old HUD element scripts
      -- whose new() method don't take a config parameter.
      element:set_dst_position(element_config.x, element_config.y)
    end
    hud.elements[#hud.elements + 1] = element

    if element_config.menu_script == "scripts/hud/item_icon" then
      item_icons[element_config.slot] = element
    elseif element_config.menu_script == "scripts/hud/action_icon" then
      action_icon = element
    elseif element_config.menu_script == "scripts/hud/attack_icon" then
      attack_icon = element
    end
  end

  game:register_event("on_map_changed", hud_on_map_changed)
  game:register_event("on_paused", hud_on_paused)
  game:register_event("on_unpaused", hud_on_unpaused)

  -- Start the HUD.
  hud:set_enabled(true)
end

-- Set up the HUD features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hud_features)

return true
