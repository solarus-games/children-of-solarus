-- Defines the elements to put in the HUD
-- and their position on the game screen.

-- You can edit this file to add, remove or move some elements of the HUD.

-- Each HUD element script must provide a method new()
-- that creates the element as a menu.
-- See for example scripts/hud/hearts.lua.

-- Negative x or y coordinates mean to measure from the right or bottom
-- of the screen, respectively.

local hud_config = {

  -- Hearts meter.
  {
    menu_script = "scripts/hud/hearts",
    x = -87,
    y = 6,
  },

  -- Magic bar.
  {
    menu_script = "scripts/hud/magic_bar",
    x = -52,
    y = 27,
  },

  -- Rupee counter.
  {
    menu_script = "scripts/hud/rupees",
    x = 8,
    y = -20,
  },

  -- Small key counter.
  {
    menu_script = "scripts/hud/small_keys",
    x = -30,
    y = -19,
  },

  -- Floor view.
  {
    menu_script = "scripts/hud/floor",
    x = 6,
    y = 70,
  },

  -- Prehistoric label.
  {
    menu_script = "scripts/hud/prehistoric",
    x = -58,
    y = -22,
  },

  -- Pause icon.
  {
    menu_script = "scripts/hud/pause_icon",
    x = 0,
    y = 6,
  },

  -- Item icon for slot 1.
  {
    menu_script = "scripts/hud/item_icon",
    x = 11,
    y = 28,
    slot = 1,  -- Item slot (1 or 2).
  },

  -- Item icon for slot 2.
  {
    menu_script = "scripts/hud/item_icon",
    x = 63,
    y = 28,
    slot = 2,  -- Item slot (1 or 2).
  },

  -- Attack icon.
  {
    menu_script = "scripts/hud/attack_icon",
    x = 13,
    y = 28,
  },

  -- Action icon.
  {
    menu_script = "scripts/hud/action_icon",
    x = 26,
    y = 50,
  },
}

return hud_config
