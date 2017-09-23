local item = ...

local direction_fix_enabled = true
local shield_state, shield_command_released
local shield -- Custom entity shield.

function item:on_created()
  self:set_savegame_variable("i1130")
  self:set_assignable(true)
end

function item:on_variant_changed(variant)
  -- TODO: change shield variant.
end

function item:on_obtained()
end

-- Program custom shield.
function item:on_using()
  local map = self:get_map()
  local game = map:get_game()
  local hero = map:get_hero()
  local hero_tunic_sprite = hero:get_sprite()
  local variant = item:get_variant()

  -- Do not use if there is bad ground below.
  if not hero:is_jumping() and not map:is_solid_ground(hero:get_ground_position()) then return end 
    
  -- Do nothing if game is suspended or if shield is being used.
  if game:is_suspended() then return end
  if shield_state then return end

  -- Play shield sound.
  sol.audio.play_sound("shield_brandish")

  -- Freeze hero and save state. 
  if hero:get_state() ~= "frozen" then
    hero:freeze() -- Freeze hero if necessary.
  end
  shield_state = "preparing"
  shield_command_released = false
  -- Remove fixed animations (used if jumping).
  hero:set_fixed_animations(nil, nil)
  -- Show "shield_brandish" animation on hero.
  hero:set_animation("shield_" .. variant .. "_brandish")
  
  -- Create shield.
  self:create_shield()

  -- Stop using item if there is bad ground under the hero.
  sol.timer.start(item, 5, function()
    if not self:get_map():is_solid_ground(hero:get_ground_position()) then
      self:finish_using()
    end
    return true
  end)

  -- Check if the item command is being hold all the time.
  local slot = game:get_item_assigned(1) == item and 1 or 2
  local command = "item_" .. slot
  sol.timer.start(item, 1, function()
    local is_still_assigned = game:get_item_assigned(slot) == item
    if not is_still_assigned or not game:is_command_pressed(command) then 
      -- Notify that the item button was released.
      shield_command_released = true
      return
    end
    return true
  end)
  
  -- Stop fixed animations if the command is released.
  sol.timer.start(item, 1, function()
    if shield_state == "using" then
      if shield_command_released == true or hero:get_state() == "sword swinging" then 
        -- Finish using item if sword is used or if shield command is released.
        self:finish_using()
        return
      end
    end
    return true
  end)

  -- Start custom shield state when necessary: allow to sidle with shield.
  local anim_duration = hero_tunic_sprite:get_num_frames() * hero_tunic_sprite:get_frame_delay()
  sol.timer.start(item, anim_duration, function()  
    -- Do not allow walking with shield if the command was released.
    if shield_command_released == true then
      self:finish_using()
      return
    end
    -- Start loading sword if necessary. Fix direction and loading animations.
    shield_state = "using"
    hero:set_fixed_animations("shield_" .. variant .. "_stopped", "shield_" .. variant .. "_walking")
    local dir = direction_fix_enabled and hero:get_direction() or nil
    hero:set_fixed_direction(dir)
    hero:set_animation("shield_" .. variant .. "_stopped")
    hero:unfreeze() -- Allow the hero to walk.
  end)

end


-- Stop using items when changing maps.
function item:on_map_changed(map)
  if shield_state ~= nil then self:finish_using() end
end

function item:finish_using()
  -- Stop all timers (necessary if the map has changed, etc).
  sol.timer.stop_all(self)
  -- Finish using item.
  self:set_finished()
  -- Reset fixed animations/direction. (Used while sidling with shield.)
  local hero = self:get_map():get_hero()
  hero:set_fixed_direction(nil)
  hero:set_fixed_animations(nil, nil)
  shield_state = nil
  -- Destroy shield.
  if shield and shield:exists() then
    shield:remove()
    shield = nil
  end
  -- Unfreeze the hero if necessary.
  hero:unfreeze() -- This updates direction too, preventing moonwalk!
end


function item:create_shield()
  local map = self:get_map()
  local hero = map:get_hero()
  local hx, hy, hlayer = hero:get_position()
  local hdir = hero:get_direction()
  local prop = {x=hx, y=hy, layer=hlayer, direction=hdir, width=2*16, height=2*16}
  shield = map:create_custom_entity(prop)
  sol.timer.start(shield, 1, function()
    shield:set_position(hero:get_position())
    shield:set_direction(hero:get_direction())
  end)
  
  -- Create collision test.
  shield:add_collision_test("overlapping", --"sprite",
  function(shield, entity, shield_sprite, entity_sprite)
    -- Push enemies.
    if entity:get_type() ~= "enemy" then return end   
    local p = {}
    p.pushing_entity = shield
    entity:push(p)  
  end)  
  -- TODO: PUSH HERO.
end

--[[ Pushing commands for the shield:
-------- FUNCTIONS:
enemy:get_can_be_pushed_by_shield()
enemy:set_can_be_pushed_by_shield(boolean)
enemy:is_being_pushed_by_shield()
enemy:set_being_pushed_by_shield(boolean)
enemy:get_pushed_by_shield_properties()
enemy:set_pushed_by_shield_properties(properties)
enemy:get_can_push_hero_on_shield()
enemy:set_can_push_hero_on_shield(boolean)
hero:is_being_pushed_on_shield()
hero:set_being_pushed_on_shield(boolean)
enemy:get_push_hero_on_shield_properties()
enemy:set_push_hero_on_shield_properties(properties)
enemy/hero:push(table)

-------- CUSTOM EVENTS:
enemy:on_pushed_by_shield()
enemy:on_finished_pushed_by_shield()
enemy:on_pushing_hero_on_shield()

-------- VARIABLES in tables of properties:
-distance
-speed
-behavior (function or string)
-sound_id
-pushing_entity or angle
--]]
local enemy_meta = sol.main.get_metatable("enemy")
local hero_meta = sol.main.get_metatable("hero")

-- Pushing enemy functions.
function enemy_meta:get_can_be_pushed_by_shield()
  local default = true -- Default value.
  return (self.can_be_pushed_by_shield == nil) and default or self.can_be_pushed_by_shield
end
function enemy_meta:set_can_be_pushed_by_shield(boolean)
  self.can_be_pushed_by_shield = boolean
end
function enemy_meta:is_being_pushed_by_shield()
  return self.pushed_by_shield or false
end
function enemy_meta:set_being_pushed_by_shield(pushed)
  if not self:get_can_be_pushed_by_shield() then return end
  pushed = pushed or false
  if self:is_being_pushed_by_shield() == pushed then return end
  self.pushed_by_shield = pushed
  if pushed and self.on_pushed_by_shield then
    self:on_pushed_by_shield() -- Call custom event.
  end
end
function enemy_meta:get_pushed_by_shield_properties()
  return self.pushed_by_shield_properties or {}
end
function enemy_meta:set_pushed_by_shield_properties(properties)
  self.pushed_by_shield_properties = properties
end

-- Pushing hero functions.
function enemy_meta:get_can_push_hero_on_shield()
  return self.can_push_hero_on_shield or false
end
function enemy_meta:set_can_push_hero_on_shield(boolean)
  self.can_push_hero_on_shield = boolean or false
end
function hero_meta:is_being_pushed_on_shield()
  return self.pushed_on_shield or false
end
function hero_meta:set_being_pushed_on_shield(boolean)
  self.pushed_on_shield = boolean
  if boolean and enemy.on_pushing_hero_on_shield then
    enemy:on_pushing_hero_on_shield()
  end
end
function enemy_meta:get_push_hero_on_shield_properties()
  return self.push_hero_on_shield_properties or {}
end
function enemy_meta:set_push_hero_on_shield_properties(properties)
  self.push_hero_on_shield_properties = properties
end


-- Enemy pushing function.
function enemy_meta:push(properties)

  -- Check if enemy can be pushed.
  local need_push = self:get_can_be_pushed_by_shield()
    and not self:is_being_pushed_by_shield()
  if not need_push then return end
  local p = properties or {}
  local default_behavior = "normal_push" -- Default behavior.
  local behavior = (p.behavior == nil) and default_behavior or p.behavior
  if behavior == nil then return end
  self:set_being_pushed_by_shield(true)   
  -- Immobilize enemy.
  self:immobilize()
  -- Push enemy.
  if type(behavior) == "function" then
    behavior(self, properties)
    return
  elseif type(behavior) == "string" then
    -- Get angle.
    local e = p.pushing_entity
    local a = p.angle or (e and e:get_angle(self))
    if not a then return end
    -- Play sound if any.
    local sound_id = p.sound_id
    if sound_id then 
      sol.audio.play_sound(sound_id)
    end
    -- Create movement.
    local m = sol.movement.create("straight")
    local speed = p.speed or 100
    local distance = p.distance or 100
    m:set_angle(a)
    m:set_speed(speed)
    m:set_max_distance(distance)
    m:set_smooth(true)
    -- Finish movement.
    local function finish_push()
      self:stop_movement()
      self:set_being_pushed_by_shield(false)
      self:restart()
      if self.on_finished_pushed_by_shield then
        self:on_finished_pushed_by_shield(properties)
      end
    end
    function m:on_finished() finish_push(); print("end movement") end
    function m:on_obstacle_reached() finish_push() end
    m:start(self) -- Start movement.
  end
end

