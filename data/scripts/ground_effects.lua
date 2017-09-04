-- Create ground effects: falling on holes, falling leaves, water and lava splash, etcs.
-- Use:
-- require("scripts/ground_manager/ground_effects")

local map_meta = sol.main.get_metatable("map")

-- Create ground effect.
function map_meta:create_ground_effect(effect, x, y, layer, sound_id)
  local map = self
  local model = "ground_effects/" .. effect
  -- local ground_effect = map:create_custom_entity({direction=0, layer=layer, x=x, y=y, width = 16, height = 16, model=model})
  if sound_id then -- Play sound.
    sol.audio.play_sound(sound_id)
  end  
  return ground_effect
end

--[[ Function called when an entity needs to check the ground.
The entity may fall on holes, water or lava. In that case,
the entity is removed and a ground effect is created.
--]] 
function map_meta:ground_collision(entity, collision_sound, callback_bad_ground)
  local x, y, layer = entity:get_position()
  local ground = entity:get_ground_below()
  local min_layer = self:get_min_layer()
  while ground == "empty" and layer > min_layer do
    -- If ground is empty, fall to lower layer and check ground again.
     layer = layer-1
     entity:set_position(x, y, layer)
     ground = entity:get_ground_below()
  end
  -- If the entity falls on hole, water or lava, remove entity and create effect.
  if ground == "hole" then  
    entity:remove()
    self:create_ground_effect("fall_on_hole", x, y, layer, "hero_falls")
    if callback_bad_ground then callback_bad_ground() end
  elseif ground == "deep_water" then
    entity:remove()
    self:create_ground_effect("water_splash", x, y, layer, "splash")
    if callback_bad_ground then callback_bad_ground() end
  elseif ground == "lava" then
    entity:remove()
    self:create_ground_effect("lava_splash", x, y, layer, "splash")
    if callback_bad_ground then callback_bad_ground() end
  else -- The ground is solid ground. If falling, make sound and effect.
    -- Bouncing sound. Used for bounces, when the entity is thrown.
    if collision_sound then sol.audio.play_sound(collision_sound) end
    -- Ground effect and sound of ground.
    if ground == "shallow_water" then
      self:create_ground_effect("water_splash", x, y, layer, "item_in_water")
    elseif ground == "grass" then
      self:create_ground_effect("falling_leaves", x, y, layer, "bush")
    end
  end
end

-- Return true if there is solid ground.
function map_meta:is_solid_ground(x, y, layer)
  local ground = self:get_ground(x, y, layer)
  if ground == "hole" or ground == "deep_water" or ground == "lava" then
    return false
  else
    return true
  end  
end
