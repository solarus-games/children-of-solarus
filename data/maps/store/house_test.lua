-- Lua script of map store/house_test.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end

-- Test sprites of NPCs with the hero.
function map:on_opening_transition_finished()
  for npc in self:get_entities_by_type("npc") do
    function npc:on_interaction()
      local sprite_id = npc:get_sprite():get_animation_set()
      hero:set_tunic_sprite_id(sprite_id)
    end
  end
end
