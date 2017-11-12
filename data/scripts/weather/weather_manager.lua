-- Weather script: enable/disable different scripts for weather.
-- Author: Diarandor (Solarus Team).
-- License: GPL v3-or-later.
-- Donations: solarus-games.org, diarandor at gmail dot com.

local rain_script_enabled = true

local game_meta = sol.main.get_metatable("game")

if rain_script_enabled then
  require("scripts/weather/rain_manager")
else -- Redefine methods to avoid errors.
  function game_meta:get_rain_mode() return nil end
  function game_meta:set_rain_mode(rain_mode) end
  function game_meta:get_world_rain_mode(world) return nil end
  function game_meta:set_world_rain_mode(world, rain_mode) end
end