-- Rain manager script.
--[[
To add this script to your game, call from game_manager script:
    require("scripts/weather/rain_manager")

The functions here defined are:
    game:get_rain_type(world)
    game:set_rain_type(world, rain_type)

Rain types: nil (no rain), "rain", "storm".
--]]

-- This script requires the multi_event script:
require("scripts/multi_events")
local rain_manager = {}

local game_meta = sol.main.get_metatable("game")
local map_meta = sol.main.get_metatable("map")


  -- Initialize menu.
  sol.menu.start(map, rain_manager)

-- Default settings. Change these for testing.
local rain_enabled = true -- Do not change this property, unless you are testing.
-- local lightning_enabled = true
local rain_speed = 100 -- Default drop speed 100.
local storm_speed = 300 -- Default drop speed 300.
local drop_speed -- Local variable to store the speed.
local drop_max_distance = 300 -- Max possible distance for drop movements.
local rain_drop_delay = 10 -- Delay between drops for rain, in milliseconds.
local storm_drop_delay = 5 -- Delay between drops for storms, in milliseconds.
local min_lightning_delay = 2000
local max_lightning_delay = 10000
local drop_sprite = sol.sprite.create("weather/rain")
local thunder_sounds = {"thunder1", "thunder2", "thunder3", "thunder_far", "thunder_double"}
local rain_surface, flash_surface -- Surfaces to draw rain and lightning flash.
local draw_flash_surface = false -- Used by the lightning menu.
local current_drop_number = 0
local max_drop_number = 200
local drop_list = {} -- List of properties for each drop.
local timers = {}


-- Initialize rain on maps when necessary.
game_meta:register_event("on_map_changed", function(game)
  local map = game:get_map()
  rain_manager:update_rain(map)
end)

-- Get/set the raining state for a given world.
function game_meta:get_rain_type(world)
  local rain_type = nil 
  if world then
    rain_type = self:get_value("rain_state_" .. world)
  end
  return rain_enabled and rain_type
end
-- Set the raining state for a given world.
function game_meta:set_rain_type(world, rain_type)
  -- Update savegame variable.
  self:set_value("rain_state_" .. world, rain_type)
  -- Check if rain is necessary: if we are in that world and rain is needed.  
  local current_world = self:get_map():get_world()
  local rain_needed = (current_world == world) and rain_enabled and rain_type
  if (not rain_needed) then return end -- Do nothing if rain is not needed!
  -- We need to start the rain in the current map.
  local map = self:get_map()
  rain_manager:update_rain(map)
end

-- Define on_draw event for the rain_manager menu (if it is initialized).
function rain_manager:on_draw(dst_surface)
print("draw!")
  if rain_surface then
    rain_surface:clear()
    for _, drop in pairs(drop_list) do -- Draw drops.
      drop_sprite:set_frame(drop.frame)
      drop_sprite:draw(rain_surface, drop.x, drop.y)

    end
    rain_surface:draw(dst_surface) -- Draw rain.
  end
  if draw_flash_surface then
    flash_surface:draw(dst_surface) -- Draw lightning if necessary.
  end
end

-- Create rain if necessary when entering a new map.
function rain_manager:update_rain(map)
  -- Get rain state in this world.
  local world = map:get_world()
  local rain_type = map:get_game():get_rain_type(world)
  -- Start rain if necessary.
  if rain_type == "rain" then
    self:start_rain(map)
  elseif rain_type == "storm" then
    self:start_storm(map)
  end
end

--[[
-- Define function to create splash effects.
-- If no parameters x, y are given, the position is random.
local function create_drop_splash(map, x, y)
  local max_layer = map:get_max_layer()
  local min_layer = map:get_min_layer()
  local camera = map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  local drop_properties = {direction = 0, x = 0, y = 0, layer = max_layer,
    width = 16, height = 16, sprite = drop_sprite_id}
  -- Initialize parameters.
  local x = x or cx + cw * math.random()
  local y = y or cy + ch * math.random()
  local layer = max_layer
  while map:get_ground(x,y,layer) == "empty" and layer > min_layer do
    layer = layer - 1 -- Draw the splash at the lower layer we can.
  end
  -- Do not draw splash over some bad grounds: "hole" and "lava".
  local ground = map:get_ground(x, y, layer)
  if ground ~= "hole" and ground ~= "lava" then
    drop_properties.x = x
    drop_properties.y = y
    drop_properties.layer = layer
    local drop_splash = map:create_custom_entity(drop_properties)
    local splash_sprite = drop_splash:get_sprite()
    splash_sprite:set_animation("drop_splash")
    splash_sprite:set_direction(0)
    function splash_sprite:on_animation_finished() drop_splash:remove() end
  end
end
--]]


-- Create properties list for water drop at random position.
function rain_manager:create_drop(map)
  local camera = map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  -- Initialize properties for new drop.
  local drop = {} -- Drop properties.
  drop.x = cx + cw * math.random() + 30
  drop.y = cy + ch * math.random() - 100
  drop.frame = 0
  drop.index = current_drop_number
  current_drop_number = (current_drop_number + 1) % max_drop_number
  drop_list[drop.index] = drop
  -- Initialize drop movement.
  local m = sol.movement.create("straight")
  m:set_angle(7 * math.pi / 5)
  m:set_speed(drop_speed)
  local random_max_distance = math.random(1, drop_max_distance)
  m:set_max_distance(random_max_distance)
  m:start(drop, function() -- Callback.
    --rain_manager:create_drop_splash(drop.x, drop.y)
    drop_list[drop.index] = nil
  end)
  return drop
end


-- Stop rain effects for the current map.
function rain_manager:stop()
  -- Stop rain timers if already started.
  for k, timer in pairs(timers) do
    timer:stop()
    timers[k] = nil
  end
end

-- Start rain in the current map.
function rain_manager:start_rain(map)
  drop_speed = rain_speed -- Initialize drop speed.
  self:stop() -- Stop rain timers if already started.
  -- Start timer to draw rain drops.
  timers["drop_timer"] = sol.timer.start(map, rain_drop_delay, function()
    rain_manager:create_drop(map) -- Create drops at random positions.
    return true -- Repeat loop.
  end)
end

-- Start lighnings in the current map.
local function create_lightnings(map)
  -- Play thunder sound after a random delay.
  local lightning_delay = math.random(min_lightning_delay, max_lightning_delay)
  timers["lightning_timer"] = sol.timer.start(map, lightning_delay, function()
    -- Create lightning flash.
    draw_flash_surface = true
    sol.timer.start(map, 150, function()
      draw_flash_surface = false -- Stop drawing lightning flash.
    end)
    -- Play random thunder sound after a delay.
    local thunder_delay = math.random(200, 1500)
    sol.timer.start(map, thunder_delay, function()
      local random_index = math.random(1, #thunder_sounds)
      local sound_id = thunder_sounds[random_index]
      sol.audio.play_sound(sound_id)
    end)
    -- Prepare next lightning.
    create_lightnings(map)
  end)
end

-- Start storm in the current map.
function rain_manager:start_storm(map)
  -- Initialize drop speed.
  drop_speed = storm_speed
  -- Stop rain timers if already started.
  self:stop()
  -- Create lightning surface.
  local camera = map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  flash_surface = sol.surface.create(cw, ch)
  flash_surface:fill_color({255, 255, 100})
  flash_surface:set_opacity(170)
  -- Initialize menu to draw lightning surface.
  sol.menu.start(map, rain_manager)

  -- Start timer to draw rain drops.
  timers["drop_timer"] = sol.timer.start(map, storm_drop_delay, function()
    -- Create drops on random positions.
    create_drop(map)
    -- Repeat loop.
    return true
  end)
  -- Start lightning effects.
  create_lightnings(map)
end

-- Return rain manager.
return rain_manager