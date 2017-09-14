-- Create ground effects: falling on holes, falling leaves, water and lava splash, etc.
-- Use:
-- require("scripts/ground_effects")

local map_meta = sol.main.get_metatable("map")

-- Create ground effect.
function map_meta:create_ground_effect(effect, x, y, layer, sound_id)
  local map = self
  local sprite_id = "ground_effects/" .. effect
  local effect = map:create_custom_entity({direction=0,
    layer=layer, x=x, y=y, width = 16, height = 16})
  local sprite = effect:create_sprite(sprite_id)
  function sprite:on_animation_finished()
    effect:remove()
  end
  if sound_id then -- Play sound.
    sol.audio.play_sound(sound_id)
  end  
  return ground_effect
end

-- Display effects when an entity falls to the ground.
function map_meta:ground_collision(entity, collision_sound, callback_bad_ground)
  local x, y, layer = entity:get_position()
  local ground = entity:get_ground_below()
  local min_layer = self:get_min_layer()
  local hero = self:get_hero()
  local game = self:get_game()
  while ground == "empty" and layer > min_layer do
    -- If ground is empty, fall to lower layer and check ground again.
     layer = layer-1
     entity:set_position(x, y, layer)
     ground = entity:get_ground_below()
  end
  -- If the entity falls on hole, water or lava, remove entity and create effect.
  if ground == "hole" and entity ~= hero then  
    self:create_ground_effect("fall_on_hole", x, y, layer, "falling_on_hole")
    if callback_bad_ground then callback_bad_ground() end
  elseif ground == "deep_water" then
    if entity ~= hero or game:has_ability("swim") then
      self:create_ground_effect("water_splash", x, y, layer, "walk_on_water")
      if callback_bad_ground then callback_bad_ground() end
    end
  elseif ground == "lava" and entity ~= hero then
    self:create_ground_effect("lava_splash", x, y, layer, "walk_on_water")
    if callback_bad_ground then callback_bad_ground() end
  else -- The ground is solid ground. Make ground effect and sound of ground.
    if ground == "shallow_water" then
      self:create_ground_effect("water_splash", x, y, layer, "walk_on_water")
    elseif ground == "grass" then
      self:create_ground_effect("leaves", x, y, layer, "walk_on_grass")
    else -- Normal traversable ground. No ground effect, just a sound.
       local sound = collision_sound or "hero_lands"
       sol.audio.play_sound(sound)
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
