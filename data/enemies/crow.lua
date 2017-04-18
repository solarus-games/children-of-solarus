-- Enemy crow script.

-- These enemies can throw entities like pots. 
-- For customization, modify the list "throwable_entities".
-- Enemies of type explosion are required for explosions of thrown things.

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local sprite, shadow, shadow_sprite, state
local detection_distance = 72 -- Distance to detect the hero.
local throwables_detection_distance = 150 -- Distance to detect throwable stuff.
local flying_height = 48 -- Height before each attack.
local movement_speed = 90 -- Speed during attack (pixels per second).
local movement_carrying_speed = 120 -- Speed while carrying an object.
local ascending_time = 2000 -- Time duration to ascend (milliseconds).
local can_throw_things = true -- Do not change this!
local throwable -- Destructible entity that can be lifted/thrown.
local lifted_entity -- Custom entity that is being lifted.

-- List of sprite names of destructibles that can be lifted and thrown.
local throwable_entities = {"entities/pot"}

-- Event called when the enemy is initialized.
function enemy:on_created()
  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = self:create_sprite("enemies/crow")
  self:set_obstacle_behavior("flying") -- Fly over bad grounds.
  self:set_layer_independent_collisions(true) -- Detect collisions from any layer.
  self:set_life(2)
  self:set_damage(1)
  -- Create shadow.
  local x, y, layer = self:get_position()
  local prop = {x = x, y = y, layer = layer, direction = 0, width = 16, height = 16}
  shadow = self:get_map():create_custom_entity(prop)
  shadow_sprite = shadow:create_sprite("shadows/shadow_huge_dynamic")
  -- Do not use the animation. Frames are calculated depending on the height.
  shadow_sprite:set_frame_delay(100000) 
  -- Make shadow follow the crow.
  sol.timer.start(shadow, 10, function()
    shadow:set_position(self:get_position())
    return true
  end)
end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()
  if state == nil then
    self:wait_for_hero()
  else
    self:prepare_attack()
  end
end

-- Remove the shadow when the enemy is dying.
function enemy:on_dying() shadow:remove() end
-- Remove the shadow when the enemy is removed.
function enemy:on_removed() shadow:remove() end

-- Starts checking if the hero is close.
function enemy:wait_for_hero()
  state = "waiting"
  sprite:set_animation("stopped")
  local hero = map:get_hero()
  sol.timer.start(self, 10, function() 
    local dist = self:get_distance(hero)
    if dist <= detection_distance then
      self:prepare_attack()
      return
    end
    return true
  end)
end

-- Prepare attack.
function enemy:prepare_attack()
  state = "prepare_attack"
  sprite:set_animation("flying")
  local _, current_height = sprite:get_xy()
  -- Stop movement and timers, if any.
  sol.timer.stop_all(self)
  self:stop_movement()
  -- Change position to a lower layer if possible (layer is changed to carry objects).
  repeat
    local x, y, layer = self:get_position()
    local ground = map:get_ground(x, y, layer)
    if ground == "empty" then
      self:set_position(x, y, layer - 1)
    end
  until ground ~= "empty"
  -- Ascending delay in milliseconds per pixel.
  local ascending_delay = ascending_time /(flying_height - current_height)
  -- Look for nearby destructibles that can be lifted/thrown.
  if can_throw_things then
    throwable = self:get_destructible_nearby()
  end
  -- Start the ascension.
  sol.timer.start(self, ascending_delay, function()
    local dx, dy = sprite:get_xy()
    if dy > -flying_height then
      sprite:set_xy(dx, dy - 1)
      self:update_shadow() -- Update shadow size.
      self:update_invincibility() -- Update invincibility.
      return true
    else
      -- Go for nearby throwable if any, or attack otherwise.
      if throwable then
        self:go_for_throwable()  
      else
        self:attack_hero()
      end
      return
    end
  end)
end

-- Set direction towards certain entity.
function enemy:set_direction_towards(other_entity)
  local angle = self:get_angle(other_entity)
  if angle >= math.pi/2 and angle < 3*math.pi/2 then
    sprite:set_direction(2)
  else
    sprite:set_direction(0)
  end
end

-- Attack hero.
function enemy:attack_hero()
  state = "attack"
  local hero = map:get_hero()
  local max_distance = self:get_distance(hero)
  -- Stop movement and timers, if any.
  sol.timer.stop_all(self)
  self:stop_movement()
  -- Turn enemy sprite towards hero. Start animation.
  self:set_direction_towards(hero)
  sprite:set_animation("attack")
  -- Create movement towards hero.
  local angle = self:get_angle(map:get_hero())
  local m = sol.movement.create("straight")
  m:set_angle(angle)
  m:set_max_distance(max_distance)
  m:set_speed(movement_speed)
  function m:on_obstacle_reached() enemy:prepare_attack() end
  function m:on_finished() enemy:prepare_attack() end
  m:start(enemy)
  -- Create descending movement (shift the sprite).
  local max_duration = math.floor(1000 * max_distance / movement_speed) -- In milliseconds.  
  local descend_delay = math.floor(max_duration / flying_height) -- In milliseconds.
  descend_delay = math.max(descend_delay, 10) -- Necessary if the enemy is too close (to slow down!).
  sol.timer.start(self, descend_delay, function()
    -- Stop descending if the state has changed.
    if state ~= "attack" then return false end
    -- Stop descending if already down.
    local dx, dy = sprite:get_xy()
    if dy == 0 then
      self:prepare_attack()
      return
    end
    -- Descend (shift sprite down).
    sprite:set_xy(dx, dy + 1)
    self:update_shadow() -- Update shadow size.
    self:update_invincibility() -- Update invincibility.
    return true
  end)
end

-- Show the correct size of the shadow, depending on the height.
function enemy:update_shadow()
  local num_frames = shadow_sprite:get_num_frames()
  local _, dy = sprite:get_xy()
  local height = -dy
  local frame = math.floor( (height / flying_height) * (num_frames / 2 - 1) )
  shadow_sprite:set_frame(frame)
end

-- Update invincibility properties, depending on the height.
function enemy:update_invincibility()
  local _, dy = sprite:get_xy()
  local height = -dy
  if height <= 24 then
    self:set_default_attack_consequences() -- Stop invincibility.
    self:set_can_attack(true) -- Allow to attack.
  else
    self:set_invincible() -- Start invincibility.
    self:set_can_attack(false) -- Do not allow to attack.
  end
end

-- Return true if the entity can be lifted/thrown by the crow.
function enemy:can_lift(other_entity)
  local e = other_entity
  if (not e) or (not e:exists()) then return end
  if e:get_type() ~= "destructible" then return end
  local sprite = e:get_sprite()
  if not e then return end
  local sprite_id = sprite:get_animation_set()
  for _, name in pairs(throwable_entities) do
    if sprite_id == name then return true end
  end
  return nil
end

-- Look for throwable destructibles. Return the closest one, or nil otherwise.
function enemy:get_destructible_nearby()
  local x, y, layer = self:get_position()
  local d = throwables_detection_distance
  local width = 2 * d
  local height = 2 * d
  x = x - d
  y = y - d
  local destructible
  for e in map:get_entities_in_rectangle(x, y, width, height) do
    if self:can_lift(e) then 
      if not destructible then
        destructible = e
      else
        if self:get_distance(e) < self:get_distance(destructible) then
          destructible = e
        end
      end
    end
  end
  return destructible
end

-- Go towards a throwable to lift it.
function enemy:go_for_throwable()
  state = "go_for_throwable"
  self:set_direction_towards(throwable) -- Set correct direction.
  local m = sol.movement.create("target")
  m:set_target(throwable)
  m:set_speed(movement_speed)
  -- Change to upper layer to allow flying over the throwable!
  local x, y, layer = self:get_position()
  layer = map:get_max_layer()
  self:set_position(x, y, layer)
  -- If we have reached the throwable, descend ot lift it.
  local max_duration = 500 -- Descent speed, in milliseconds.  
  local descend_delay = math.floor(max_duration / flying_height) -- In milliseconds.
  function m:on_finished()
    m:stop() -- Stop target movement!
    sol.timer.start(self, descend_delay, function()
      -- Stop descending if the state has changed.
      if state ~= "go_for_throwable" then return false end
      -- Stop descending if already down.
      local dx, dy = sprite:get_xy()
      if dy == -12 then -- Height for lifting is 12!
        enemy:lift_throwable() -- Lift the throwable!!!
        return
      end
      -- Descend (shift sprite down).
      sprite:set_xy(dx, dy + 1)
      enemy:update_shadow() -- Update shadow size.
      enemy:update_invincibility() -- Update invincibility.
      return true
    end)
  end
  -- Check if the destructible still exists (it may have been taken by other entity).
  sol.timer.start(self, 1, function()
    if state ~= "go_for_throwable" then return end -- Stop timer if state changes.
    if (not throwable) or (not throwable:exists()) then
      m:stop() -- Stop movement.
      sol.timer.stop_all(self) -- Clear timers.
      throwable = nil -- Clear variable.
      self:prepare_attack() -- Restart behavior.
      return
    end
    return true
  end)
  -- If an obstacle is reached (the throwable cannot be reached), stop looking for throwables.
  function m:on_obstacle_reached()
    can_throw_things = false
    m:stop() -- Stop target movement!
    self:prepare_attack()
  end
  -- Start movement.
  m:start(self)
end

-- Lift the throwable (replace it with custom entity) and ascend.
function enemy:lift_throwable()
  state = "lifting_trowable"
  -- Clear throwable variable.
  local thing = throwable
  throwable = nil
  -- If the throwable does not exist anymore, go for the hero.
  if not thing:exists() then
    self:prepare_attack()
    return
  end
  -- Enable invincibility (while carring throwable).
  self:set_invincible() -- Start invincibility.
  self:set_can_attack(false) -- Do not allow to attack.
  -- Get the throwable information and replace it with a custom entity.
  local thing_sprite = thing:get_sprite()
  local sprite_id = thing_sprite:get_animation_set()
  local animation = thing_sprite:get_animation()
  local dir = thing_sprite:get_direction()
  thing:remove() -- Destroy built-in throwable!
  local x, y, layer = self:get_position()
  prop = {x = x, y = y, layer = layer, direction = 0, width = 16, height = 16}
  thing = map:create_custom_entity(prop)
  thing_sprite = thing:create_sprite(sprite_id)
  thing_sprite:set_animation(animation)
  thing_sprite:set_direction(dir)
  lifted_entity = thing -- Save the custom entity in variable.
  -- The custom entity must follow the crow. Update position and shift sprite.
  sol.timer.start(thing, 1, function()
    thing:set_position(self:get_position())
    local dx, dy = sprite:get_xy()
    thing_sprite:set_xy(dx, dy + 12)
    return true
  end)
  -- Ascend with the throwable.
  local max_duration = 500 -- Ascent speed, in milliseconds.
  local _, dy = sprite:get_xy()
  local height = flying_height + dy
  local ascending_delay = max_duration / height -- Time to move each pixel, in milliseconds.
  sol.timer.start(self, ascending_delay, function()
    local dx, dy = sprite:get_xy()
    if dy > -flying_height then
      sprite:set_xy(dx, dy - 1)
      self:update_shadow() -- Update shadow size.
      return true
    else
      -- Go towards hero to throw the throwable.
      self:go_to_hero_with_throwable()
      return
    end
  end)
end

-- Go towards hero to throw the throwable.
function enemy:go_to_hero_with_throwable()
  state = "go_to_hero_with_throwable"
  -- Create movement towards hero.
  local m = sol.movement.create("target")
  m:set_speed(movement_carrying_speed)
  local hero = map:get_hero()
  m:set_target(hero)
  self:set_direction_towards(hero) -- Set correct direction.
  -- When the hero is reached, throw item.
  function m:on_finished()
    enemy:throw_item()
    m:stop() -- Stop target movement!
  end
  -- Start movement.
  m:start(self)
end

-- Throw item and restaure default behavior.
function enemy:throw_item()
  state = "throwing"
  -- Wait before restarting behavior.
  local delay = 500 
  sol.timer.start(self, 2000, function()
    self:prepare_attack()
  end)
  -- Clear variable of lifted entity.
  local thing = lifted_entity
  local thing_sprite = thing:get_sprite()
  lifted_entity = nil
  -- Play throw sound.
  sol.audio.play_sound("throw")
  -- Change to hero layer to detect obstacles again.
  local x, y, _ = self:get_position()
  local _, _, hlayer = map:get_hero():get_position()
  self:set_position(x, y, hlayer)
  -- Thrown entity must stop following the crow.
  sol.timer.stop_all(thing)
  -- Define function to break the thing.
  function thing:explode()
    local thing_sprite = self:get_sprite()
    -- Create an explosion enemy and destroy the thing.
    local x, y, layer = self:get_position()
    local prop = {x = x, y = y, layer = hlayer, direction = 0, breed = "explosion"}
    local explosion = map:create_enemy(prop) -- Create explosion!
    -- Set custom explosion animation.
    local sprite_id = thing_sprite:get_animation_set()
    local sprite_animation = thing_sprite:get_animation()
    local direction = thing_sprite:get_direction()
    explosion:prepare_explosion_sprite(sprite_id, "destroy", direction)
    -- Remove custom entity!
    self:remove()
  end
  -- Throw item. (Move sprite.)
  local falling_delay = 15 -- In milliseconds. Time before moving each pixel.
  sol.timer.start(thing, falling_delay, function()
    local _, dy = thing_sprite:get_xy()
    if dy == 0 then
      thing:explode()
      return
    else
      thing_sprite:set_xy(0, dy + 1)
    end
    return true
  end)
end
