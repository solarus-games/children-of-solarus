-- Initialize carried object behavior specific to this quest.
require("scripts/ground_effects")

local carried_object_meta = sol.main.get_metatable("carried_object")

-- Default properties for "custom" portable entities.
local portable_properties = {
  -- Customizable parameters:
  vshift = 0, -- Vertical shift to draw the sprite while lifting/carrying.
  num_bounces = 3, -- Number of bounces when falling (it can be 0).
  bounce_distances = {80, 16, 4}, -- Distances for each bounce.
  bounce_heights = {"same", 4, 2}, -- Heights for each bounce.
  bounce_durations = {400, 160, 70}, -- Duration for each bounce.
  bounce_sound = "bomb", -- Default id of the bouncing sound.
  shadow_type = "normal", -- Type of shadow for the falling trajectory.
  hurt_damage = 1,  -- Damage to enemies.
  -- Non-customizable parameters:
  falling_direction = nil, -- Possible values:  "up", "down", "left", "right".
  sprite = nil,
}

--[[ 
Add custom portable entities feature (used for non-destructible entities).
The animation set must be a string of the form: 
"sprites/portables/" .. TYPE .. "IMAGE_NAME.dat",
where TYPE is an OPTIONAL substring of the form "TYPE/SUBTYPE_1/SUBTYPE_2/.../SUBTYPE_N/",
or maybe the trivial string: "".
The type and subtypes (substrings of the path folder) determine the thrown behavior
of this entity. The function carried_object:set_type(types_list) is used to initialize
the corresponding properties on each case. Subtypes can be used to override general
properties of a given type.
--]]
function carried_object_meta:on_created()
  -- Check if this object is a "custom" portable entity.
  local animation_set = self:get_sprite():get_animation_set()
  portable_properties.sprite = animation_set -- Save this property.
  local initial_index, end_index = animation_set:find("portables/")
  if initial_index ~= 1 then return end -- The entity is a normal destructible.
  -- Get the types substring of the custom portable.
  initial_index = end_index + 1
  end_index = animation_set:len()
  local types_string = animation_set:sub(initial_index, end_index)
  -- Save the types/subtypes in a list.
  local types_list = {}
  local lenght = types_string:len()
  initial_index = 1
  local i = 0
  while (initial_index ~= nil) and initial_index <= lenght do
    i = i + 1
    end_index = animation_set:find("/", initial_index)
    if end_index == nil then
      end_index = lenght
    else
      end_index = end_index - 1
    end
    types_list[i] = animation_set:sub(initial_index, end_index)
    initial_index = end_index + 2
  end
  -- For each type/subtype, set the corresponding properties.
  for _, type in pairs(types_list) do
    self:set_type_properties(type)
  end
  -- Used to start the custom event on_thrown.
  function self:on_movement_changed()
    if getmetatable(self:get_movement()) == sol.main.get_metatable("straight_movement") then
      self:on_throw()
    end
  end
end

-- Initialize the behavior and event of this carried entity.
-- Define this function for types customization!
function carried_object_meta:set_type_properties(type)
  --if type == nil then -- Default type.

  --end
end


-- Function to fix bug: the hero may get stuck with the ball if it falls over him.
-- Modify ground of iron ball with a custom entity above, if necessary.
local function avoid_overlap_with_hero(destructible)
  -- Check if this destructible and hero overlap.
  local d = destructible
  local hero = d:get_map():get_hero()
  if not hero:overlaps(d) then
    return -- No overlapping. No need to move the destructible.
  end
  -- There is an overlap. Put destructible in front of hero.
  local x, y, layer = hero:get_position()
  local dir = hero:get_direction()
  local angle = dir * math.pi / 2
  x, y = x + 16 * math.cos(angle), y - 16 * math.sin(angle)
  d:set_position(x, y, layer)
end

-- Define falling trajectory for a custom entity and the given properties.
local function throw(custom_entity, properties)

  local e = custom_entity
  e:set_can_traverse_ground("hole", true)
  e:set_can_traverse_ground("lava", true)
  e:set_can_traverse_ground("deep_water", true)
  e:set_can_traverse_ground("shallow_water", true)
  e:set_can_traverse_ground("grass", true)
  local args = properties or {}
  local map = e:get_map()
  -- Initialize optional arguments and properties.
  local fdir = args.falling_direction -- Nil means no direction.
  local num_bounces = args.num_bounces
  local bounce_distances = args.bounce_distances
  local bounce_heights = args.bounce_heights
  local bounce_durations = args.bounce_durations
  local bounce_sound = args.bounce_sound
  local current_bounce = 1
  local current_instant = 0
  local sprite = e:get_sprite()
  local dx, dy = 0, 0
  e:set_direction(fdir) 
  dx, dy = math.cos(fdir * math.pi / 2), -math.sin(fdir * math.pi / 2)     
  local vshift = args.vshift
  sprite:set_xy(0, -22 + vshift)
  local shadow_type = args.shadow_type
  -- Create a custom_entity for shadow (this one is drawn below).
  local px, py, pz = e:get_position()
  if shadow_type then
    local shadow_prop = {x = px, y = py, layer = pz, direction = 0, width = 16, height = 16}
    shadow = map:create_custom_entity(shadow_prop)
    if shadow_type == "normal" then
      shadow:create_sprite("entities/shadow_dynamic")
      shadow:bring_to_back()
    end
    -- Remove shadow and/or traversable ground when the entity is removed.
    function e:on_removed() shadow:remove() end
  end
  
  -- Function called when the entity has fallen.
  -- Remove custom entity and create again a liftable destructible.
  function e:finish_bounce()
    if shadow then shadow:remove() end
    local x, y, layer = e:get_position()
    local animation_set = sprite:get_animation_set()
    local prop = {x = x, y = y, layer = layer, sprite = animation_set}
    local d = map:create_destructible(prop)
    avoid_overlap_with_hero(d) -- Put in front of hero if they overlaps.
    if e.on_finish_throw then e:on_finish_throw() end -- Cal "custom" event, if defined.
    e:remove() -- Destroy this.
  end
    
  --[[ Function to bounce when entity is thrown.
  Parameters of list "prop" are given in pixels (the speed in pixels per second).
  Call: bounce({distance =..., height_y =..., speed_pixels_per_second =..., callback =...})
  --]]
  function e:bounce()
    -- Finish bouncing if we have already done all bounces.
    if current_bounce > num_bounces then 
      e:finish_bounce()    
      return
    end  
    -- Initialize parameters for the bounce.
	  local x, y, z
    local _, sy = sprite:get_xy()
    local dist = bounce_distances[current_bounce]
    local h = bounce_heights[current_bounce]
    if h == "same" then h = -sy end
    local dur = bounce_durations[current_bounce]  
    local speed = 1000 * dist / dur -- Speed of the straight movement (pixels per second).
    local t = current_instant
    local is_obstacle_reached = false
    
    -- Function to compute height for each fall (bounce).
    function e:current_height()
      if current_bounce == 1 then return h * ((t / dur) ^ 2 - 1) end
      return 4 * h * ((t / dur) ^ 2 - t / dur)
    end 
    -- Start straight movement if necessary. Stop movement for collisions with obstacle.
    if fdir then
      local m = sol.movement.create("straight")
      m:set_angle(fdir * math.pi / 2)
      m:set_speed(speed)
      m:set_max_distance(dist)
      m:set_smooth(true)
      function m:on_obstacle_reached() 
        m:stop()
        is_obstacle_reached = true
      end
      m:start(e)
    end
    
    -- Start shifting height of the entity at each instant for current bounce.
    local refreshing_time = 5 -- Time between computations of each position.
    sol.timer.start(self, refreshing_time, function()
      t = t + refreshing_time
      current_instant = t
      if shadow then shadow:set_position(e:get_position()) end
      -- Update shift of sprite.
      if t <= dur then 
        sprite:set_xy(0, e:current_height() + vshift)
      -- Stop the timer. Start next bounce or finish bounces. 
      else -- The entity hits the ground.
        map:ground_collision(e, bounce_sound) -- Check for bad ground.
        -- Check if the entity exists (it can be removed on holes, water and lava).
        if e:exists() then 
          current_bounce = current_bounce + 1
          current_instant = 0
          e:bounce() -- Start next bounce.
        end
        return false
      end
      return true
    end)
  end
  -- Start the bounces in the given direction.
  e:bounce()
end

-- "Custom" event: called when this carried entity is thrown by the hero.
-- Remove the carried_object and replace it with a custom entity with custom thrown trajectory.
function carried_object_meta:on_throw()
  -- Create custom entity.
  local map = self:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  local animation_set = self:get_sprite():get_animation_set()
  local prop = {x = x, y = y, layer = layer, direction = direction,
    width = 16, height = 16, sprite = animation_set, ground = "empty"}
  self:remove() -- Destroy this.
  local ce = map:create_custom_entity(prop)
  -- Add additional properties to the list.
  portable_properties.falling_direction = direction
  -- Throw custom entity for the given properties.
  throw(ce, portable_properties)
end

-- "Custom" event: called when this carried entity has finished falling if thrown by the hero.
function carried_object_meta:on_finish_throw() end

return true
