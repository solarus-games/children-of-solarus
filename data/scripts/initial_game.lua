-- This script initializes game values for a new savegame file.
--
-- Usage:
-- local initial_game = require("scripts/initial_game")
-- initial_game:initialize_new_savegame(game)

local initial_game = {}

-- Sets initial values to a new savegame file.
function initial_game:initialize_new_savegame(game)

  game:set_starting_location("out/a3", "from_hero_house")

  game:set_ability("jump_over_water", 1)

  game:set_max_life(4 * 3)
  game:set_life(game:get_max_life())
  game:get_item("money_bag"):set_variant(1)
  game:get_item("tunic"):set_variant(1)
end

return initial_game
