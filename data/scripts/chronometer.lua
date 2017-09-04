-- Adds chronometer features to games.
-- The following functions are provided:
-- - game:get_time_played():            Returns the game time in seconds.
-- - game:get_time_played_string():     Returns a string representation of the game time.

-- Usage:
-- require("scripts/chronometer")

require("scripts/multi_events")

-- Measure the time played.
local function initialize_chronometer_features(game)

  -- Returns the game time in seconds.
  function game:get_time_played()
    local milliseconds = game:get_value("time_played") or 0
    local total_seconds = math.floor(milliseconds / 1000)
    return total_seconds
  end

  -- Returns a string representation of the game time.
  function game:get_time_played_string()
    local total_seconds = game:get_time_played()
    local seconds = total_seconds % 60
    local total_minutes = math.floor(total_seconds / 60)
    local minutes = total_minutes % 60
    local total_hours = math.floor(total_minutes / 60)
    local time_string = string.format("%02d:%02d:%02d", total_hours, minutes, seconds)
    return time_string
  end

  local timer = sol.timer.start(game, 100, function()
    local time = game:get_value("time_played") or 0
    time = time + 100
    game:set_value("time_played", time)
    return true  -- Repeat the timer.
  end)
  timer:set_suspended_with_map(false)
end

-- Set up chronometer features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_chronometer_features)

return true
