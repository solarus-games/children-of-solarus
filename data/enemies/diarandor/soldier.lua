-- Lua script of enemy soldier.
-- This script is executed every time an enemy with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

sol.main.load_file("enemies/generic_soldier")(enemy)
enemy:set_properties({
 main_sprite = "enemies/diarandor/soldier",
 sword_sprite = "enemies/diarandor/soldier_sword",
 life = 40,
 damage = 2,
 play_hero_seen_sound = false,
 normal_speed = 32,
 faster_speed = 48,
 hurt_style = "normal"
})

-- Create feather on the helmet.
enemy:register_event("on_created", function()
  local feather = enemy:create_sprite("enemies/diarandor/soldier_feather")
  feather:set_xy(0, -24)
  enemy:set_invincible_sprite(feather)
  enemy:bring_sprite_to_front(feather)
  enemy:set_default_behavior_on_hero_shield("block_push")
end)