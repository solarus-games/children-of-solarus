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

-- Default settings. Change these for testing.
local rain_enabled = true -- Do not change this property, unless you are testing.
-- local lightning_enabled = true
local rain_speed = 140 -- Default drop speed 100.
local storm_speed = 300 -- Default drop speed 300.
local drop_speed -- Local variable to store the speed.
local drop_min_distance = 40 -- Min possible distance for drop movements.
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
local current_map
  
-- Initialize rain on maps when necessary.
game_meta:register_event("on_map_changed", function(game)
  local map = game:get_map()
  current_map = map
  rain_manager:update_rain()
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
  if rain_surface then
    rain_surface:clear()
    local camera = current_map:get_camera()
    local cx, cy, cw, ch = camera:get_bounding_box()
    -- Draw drops on surface.
    drop_sprite:set_animation("drop")
    for _, drop in pairs(drop_list) do
      drop_sprite:set_frame(drop.frame)
      local x = (drop.init_x + drop.x - cx) % cw
      local y = (drop.init_y + drop.y - cy) % ch
      drop_sprite:draw(rain_surface, x, y)
    end
    -- Draw splashes on surface.
    drop_sprite:set_animation("drop_splash")
    for _, splash in pairs(splash_list) do 
      drop_sprite:set_frame(splash.frame)
      local x = (splash.x - cx) % cw
      local y = (splash.y - cy) % ch
      drop_sprite:draw(rain_surface, x, y)
    end
    -- Draw the surface.
    rain_surface:draw(dst_surface) -- Draw rain.
  end
  if draw_flash_surface then
    flash_surface:draw(dst_surface) -- Draw lightning if necessary.
  end
end

-- Create rain if necessary when entering a new map.
function rain_manager:update_rain()
  -- Clear variables.
  timers = {}
  drop_list = {}
  splash_list = {}
  -- Get rain state in this world.
  local map = current_map
  local world = map:get_world()
  local rain_type = map:get_game():get_rain_type(world)
  -- Start rain if necessary.
  if rain_type == "rain" then
    self:start_rain()
  elseif rain_type == "storm" then
    self:start_storm()
  end
  -- Draw rain: start menu.
  sol.menu.start(map, rain_manager)
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
function rain_manager:create_drop()
  local map = current_map
  local camera = map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  -- Initialize properties for new drop.
  local drop = {} -- Drop properties.
  drop.init_x = cx + cw * math.random()
  drop.init_y = cy + ch * math.random()
  drop.x = 0
  drop.y = 0
  drop.frame = 0
  drop.index = current_drop_number
  current_drop_number = (current_drop_number + 1) % max_drop_number
  drop_list[drop.index] = drop
  -- Initialize drop movement.
  local m = sol.movement.create("straight")
  m:set_angle(7 * math.pi / 5)
  m:set_speed(drop_speed)
  local random_distance = math.random(drop_min_distance, drop_max_distance)
  m:set_max_distance(random_distance)
  -- Callback: create splash effect.
  m:start(drop, function()
    local index = drop.index
    local splash = {x = drop.init_x + drop.x, y = drop.init_y + drop.y}
    drop_list[index] = nil
    splash.index = index
    splash.frame = 0
    splash_list[index] = splash
    -- Update splash frames.
    sol.timer.start(splash, 100, function()
      splash.frame = splash.frame + 1
      if splash.frame >= 4 then
        -- Destroy splash after last frame.
        splash_list[index] = nil
        return false
      end
      return true
    end)
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
function rain_manager:start_rain()
  -- Create rain surface.
  local map = current_map
  local camera = map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  rain_surface = sol.surface.create(cw, ch)
  -- Start timer to draw rain drops.
  drop_speed = rain_speed -- Initialize drop speed.
  self:stop() -- Stop rain timers if already started.
  timers["drop_timer"] = sol.timer.start(map, rain_drop_delay, function()
    rain_manager:create_drop() -- Create drops at random positions.
    return true -- Repeat loop.
  end)
  -- Update rain frames for all drops at the same time.
  sol.timer.start(map, 75, function()
    for _, drop in pairs(drop_list) do
      drop.frame = (drop.frame + 1) % 3
    end
    return true
  end)  
end

--[[
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
--]]

-- Return rain manager.
return rain_manager