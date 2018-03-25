--[[ Pushing commands for the shield:
This is defined for entities of types: "hero" and "enemy".
It can be extended to other types of entities.

-------- CUSTOM EVENTS:
enemy:on_shield_collision(shield) -- Overrides push behavior.
enemy:on_pushed_by_shield(shield) -- Called after creating the push.
enemy:on_finished_pushed_by_shield()
enemy:on_finished_pushed_hero_on_shield()
enemy:on_shield_collision_test(shield_collision_mask) -- Test: true to confirm collision.

-------- FUNCTIONS:
enemy:get_can_be_pushed_by_shield()
enemy:set_can_be_pushed_by_shield(boolean)
enemy:get_pushed_by_shield_properties()
enemy:set_pushed_by_shield_properties(properties)
enemy:get_pushed_by_shield_property(property_name)
enemy:set_pushed_by_shield_property(property_name, value)
enemy:get_can_push_hero_on_shield()
enemy:set_can_push_hero_on_shield(boolean)
hero:is_using_shield()
hero:is_shield_protecting_from_enemy(enemy, enemy_sprite)
enemy:get_push_hero_on_shield_properties()
enemy:set_push_hero_on_shield_properties(properties)
item:set_collision_mask() 
item:get_collision_mask_visible() 
item:set_collision_mask_visible(visible)

-------- Default shield BEHAVIORS (string values):
enemy:set_default_behavior_on_hero_shield(behavior)
"normal_shield_push", "enemy_weak_to_shield_push", "enemy_strong_to_shield_push", "block_push", nil.

-------- VARIABLES in tables of properties:
-distance
-speed
-sound_id
-push_delay
-num_directions: 4 or "any".
--]]

local item = ...
require("scripts/ground_effects") -- Used for enemies pushed into bad grounds.
require("scripts/pushing_manager")
local enemy_meta = sol.main.get_metatable("enemy")
local hero_meta = sol.main.get_metatable("hero")
local game = item:get_game()

local direction_fix_enabled = true
local shield_state -- Values: "preparing", "using".
local shield_command_released
local shield, shield_below -- Custom entity shield.
local collision_mask -- Custom entity used to detect collisions.
local path_collision_mask_sprite = "hero/shield_collision_mask"
local collision_mask_visible = false -- Change this to debug.
local normal_sound_id, block_sound_id = "shield_push", "shield2"

function item:on_created()
  self:set_savegame_variable("possession_shield")
  self:set_assignable(true)
  local variant = self:get_variant() or 0
  if variant == 0 then self:set_variant(1) end
end

function item:on_variant_changed(variant)
  -- TODO: change shield variant.
end

function item:on_obtained()
end

-- Program custom shield.
function item:on_using()
  local map = self:get_map()
  local hero = game:get_hero()
  local hero_tunic_sprite = hero:get_sprite()
  local variant = item:get_variant()

  -- Do nothing if game is suspended or if shield is being used.
  if game:is_suspended() or hero:is_using_shield() then return end
  -- Do not use if there is bad ground below or while jumping.
  if not map:is_solid_ground(hero:get_ground_position()) then return end 
  if hero.is_jumping and hero:is_jumping() then return end
    
  -- Play shield sound.
  sol.audio.play_sound("shield_brandish")

  -- Freeze hero and save state.
  hero:set_using_shield(true)
  if hero:get_state() ~= "frozen" then
    hero:freeze() -- Freeze hero if necessary.
  end
  shield_command_released = false
  -- Remove fixed animations (used if jumping).
  hero:set_fixed_animations(nil, nil)
  -- Show "shield_brandish" animation on hero.
  if hero:get_sprite():has_animation("shield_brandish") then
    shield_state = "preparing"
    hero:set_animation("shield_brandish")
  end
  
  -- Disable hero abilities.
  item:set_grabing_abilities_enabled(0)
  
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

  local function start_using_shield_state()
    -- Do not allow walking with shield if the command was released.
    if shield_command_released == true then
      self:finish_using()
      return
    end
    -- Start loading sword if necessary. Fix direction and loading animations.
    shield_state = "using"
    hero:set_fixed_animations("shield_stopped", "shield_walking")
    local dir = direction_fix_enabled and hero:get_direction() or nil
    hero:set_fixed_direction(dir)
    hero:set_animation("shield_stopped")
    hero:unfreeze() -- Allow the hero to walk.
  end
  
  if shield_state == "preparing" then
    -- Start custom shield state when necessary: allow to sidle with shield.
    local num_frames = hero_tunic_sprite:get_num_frames()
    local frame_delay = hero_tunic_sprite:get_frame_delay()
    -- Prevent bug: if frame delay is nil (which happens with 1 frame) stop using shield.
    if not frame_delay then self:finish_using() return end  
    local anim_duration = frame_delay * num_frames
    sol.timer.start(map, anim_duration, function()
      start_using_shield_state()
    end)
  else
    start_using_shield_state()
  end
end

-- Stop using items when changing maps.
function item:on_map_changed(map)
  local hero = game:get_hero()
  if hero and hero:is_using_shield() then self:finish_using() end
end

function item:finish_using()
  -- Stop all timers (necessary if the map has changed, etc).
  sol.timer.stop_all(self)
  -- Finish using item.
  self:set_finished()
  -- Reset fixed animations/direction. (Used while sidling with shield
  local hero = game:get_hero()
  hero:set_fixed_direction(nil)
  hero:set_fixed_animations(nil, nil)
  shield_state = nil
  -- Destroy shield.
  if shield and shield:exists() then
    shield:remove()
    shield = nil
  end
  -- Enable hero abilities.
  item:set_grabing_abilities_enabled(1)
  -- Unfreeze the hero if necessary.
  hero:unfreeze() -- This updates direction too, preventing moonwalk!
  hero:set_using_shield(false)
end


function item:create_shield()

  -- Create shield entities, including collision_mask.
  local map = self:get_map()
  local hero = game:get_hero()
  local hx, hy, hlayer = hero:get_position()
  local hdir = hero:get_direction()
  local prop = {x=hx, y=hy+2, layer=hlayer, direction=hdir, width=2*16, height=2*16}
  shield = map:create_custom_entity(prop) -- (Script variable.)
  shield_below = map:create_custom_entity(prop)
  collision_mask = map:create_custom_entity(prop)
  function shield:on_removed()
    if shield_below then shield_below:remove() end
    collision_mask:remove()
  end
  
  -- Create visible sprites.
  local variant = item:get_variant()
  local shield_below_path = "hero/shield_"..variant.."_below"
  local shield_above_path = "hero/shield_"..variant.."_above"
  local sprite_shield, sprite_shield_below
  if sol.file.exists("sprites/"..shield_below_path..".dat") then
    sprite_shield_below = shield_below:create_sprite(shield_below_path)
    sprite_shield_below:set_direction(hdir)
  else
    shield_below:remove(); shield_below = nil
  end
  sprite_shield = shield:create_sprite(shield_above_path)
  sprite_shield:set_direction(hdir)
  
  -- Create (invisible) collision mask sprite.
  local sprite_collision_mask = collision_mask:create_sprite(path_collision_mask_sprite)
  sprite_collision_mask:set_direction(hdir)
  collision_mask:set_visible(collision_mask_visible)
  
  -- Redefine functions to draw "shield" above hero and "shield_below" below hero.
  shield:set_drawn_in_y_order(true)
  shield.old_set_position = shield.set_position
  function shield:set_position(x, y, layer) self:old_set_position(x, y + 2, layer) end
  sprite_shield.old_set_xy = sprite_shield.set_xy
  function sprite_shield:set_xy(x, y) self:old_set_xy(x, y-2) end
  
  -- Update position and sprites.
  sol.timer.start(shield, 1, function()
    local tunic_sprite = hero:get_sprite()
    local x, y, layer = hero:get_position()
    for _, sh in pairs({shield, shield_below, collision_mask}) do
      sh:set_position(x, y, layer)
      sh:set_direction(hero:get_direction())
      local s = sh:get_sprite()
      local anim = tunic_sprite:get_animation()
      if s:has_animation(anim) then s:set_animation(anim) end
      local frame = tunic_sprite:get_frame()
      if frame > s:get_num_frames()-1 then frame = 0 end
      s:set_frame(frame)
      local x, y = tunic_sprite:get_xy()
      s:set_xy(x, y)
    end
    -- Disable shield on jumpers.
    if hero:get_state() == "jumping" then
      self:finish_using()
      return
    end
    return true
  end)
  -- Define collision test to detect enemies with shield.
  -- A pixel-precise collision between enemy and shield is assumed before calling this test.
  local function shield_collision_test(shield, entity, shield_sprite, entity_sprite)
    -- Check enemies that can be pushed.
    if (not entity) then return end
    if entity.get_can_be_pushed_by_shield
        and entity:get_can_be_pushed_by_shield() and (not entity:is_being_pushed()) then
      local entity_test = (entity.on_shield_collision_test == nil)
          or entity:on_shield_collision_test(collision_mask)
      if entity_test then
        -- Check for overriding event. Do not push if event exists.
        if entity.on_shield_collision then
          entity:on_shield_collision(shield)
          return
        end
        -- Push entity.
        local p = {}
        if entity.get_pushed_by_shield_properties then 
          p = entity:get_pushed_by_shield_properties()
        end
        p.pushing_entity = shield
        p.on_pushed = function()
          if entity.on_finished_pushed_by_shield then
            entity:on_finished_pushed_by_shield()
          end
        end
        entity:push(p)
        -- Custom event.
        if entity.on_pushed_by_shield then
          entity:on_pushed_by_shield(shield)
        end
      end
    end
    -- Check if hero can be pushed.
    if entity.get_can_push_hero_on_shield and entity:get_can_push_hero_on_shield() 
        and (not hero:is_being_pushed()) then
      local p = {}
      if entity.get_push_hero_on_shield_properties then 
        p = entity:get_push_hero_on_shield_properties()
      end
      p.pushing_entity = entity
      p.on_pushed = function()
        if entity.on_finished_pushed_hero_on_shield then
          entity:on_finished_pushed_hero_on_shield()
        end
      end
      hero:push(p)
    end
  end
  -- Initialize collision test on the shield collision mask.
  collision_mask:add_collision_test("sprite",
  function(shield, enemy, shield_sprite, enemy_sprite)
    shield_collision_test(shield, enemy, shield_sprite, enemy_sprite)
  end)
end

function item:set_grabing_abilities_enabled(enabled)
  for _, ability in pairs({"push", "grab", "pull"}) do
    game:set_ability(ability, enabled)
  end
end

-- Get shield collision mask entity, if any.
function item:get_collision_mask() return collision_mask end
-- Set collision mask visible/invisible.
function item:get_collision_mask_visible() return collision_mask_visible end
function item:set_collision_mask_visible(visible) 
  collision_mask_visible = visible
  if collision_mask then collision_mask:set_visible(visible) end
end

-- Detect if hero is using shield.
function hero_meta:is_using_shield()
  return self.using_shield or false
end
function hero_meta:set_using_shield(using_shield)
  self.using_shield = using_shield
end

-- True if there is a pixel collision between shield and enemy.
function hero_meta:is_shield_protecting_from_enemy(enemy, enemy_sprite)
  -- Check use of shield and shield collision.
  local hero = self  
  if not hero:is_using_shield() then return false end
  local shield_collision_mask = self:get_game():get_item("shield"):get_collision_mask()
  if not shield_collision_mask then return false end
  if enemy:overlaps(shield_collision_mask, "sprite") then
    return true -- The shield is protecting
  end
  return false -- The shield is not protecting the hero.
end

-- Properties for being pushed.
function enemy_meta:get_can_be_pushed_by_shield()
  return self.can_be_pushed_by_shield
end
function enemy_meta:set_can_be_pushed_by_shield(boolean)
  self.can_be_pushed_by_shield = boolean
end
function enemy_meta:get_pushed_by_shield_properties()
  return self.pushed_by_shield_properties or {}
end
function enemy_meta:set_pushed_by_shield_properties(properties)
  self.pushed_by_shield_properties = properties
end
function enemy_meta:get_pushed_by_shield_property(property_name)
  return (self.pushed_by_shield_properties)[property_name]
end
function enemy_meta:set_pushed_by_shield_property(property_name, value)
  local p = self.pushed_by_shield_properties
  p[property_name] = value
end

-- Properties for pushing.
function enemy_meta:get_can_push_hero_on_shield()
  return self.can_push_hero_on_shield
end
function enemy_meta:set_can_push_hero_on_shield(boolean)
  self.can_push_hero_on_shield = boolean
end
function enemy_meta:get_push_hero_on_shield_properties()
  return self.push_on_shield_properties or {}
end
function enemy_meta:set_push_hero_on_shield_properties(properties)
  self.push_on_shield_properties = properties
end

--[[ Behavior function: get properties for each behavior. Behaviors:
"normal_shield_push", "enemy_weak_to_shield_push", "enemy_strong_to_shield_push", "block_push", nil.
--]]
function enemy_meta:set_default_behavior_on_hero_shield(behavior)
  -- Define default properties.
  local p_enemy, p_hero
  local normal_push = {distance = 32, speed = 120, sound_id = nil,
    push_delay = 200, num_directions = "any"}
  local weak_push = {distance = 16, speed = 120, sound_id = nil,
    push_delay = 200, num_directions = "any"}
  local block_push = {distance = 1, speed = 80, sound_id = nil,
    push_delay = 30, num_directions = 4}
  self:set_can_push_hero_on_shield(true)
  self:set_can_be_pushed_by_shield(true)
  -- Select properties for each behavior.
  if behavior == nil then
    p_enemy, p_hero = {}, {}
  elseif behavior == "normal_shield_push" then
    p_enemy, p_hero = normal_push, weak_push
    p_enemy.sound_id = sound_id
  elseif behavior == "enemy_weak_to_shield_push" then
    p_enemy, p_hero = normal_push, {}
    self:set_can_push_hero_on_shield(false)
    p_enemy.sound_id = sound_id
  elseif behavior == "enemy_strong_to_shield_push" then
    p_enemy, p_hero = {}, normal_push
    self:set_can_be_pushed_by_shield(false)
    p_enemy.sound_id = sound_id    
  elseif behavior == "block_push" then
    p_enemy, p_hero = block_push, {}
    self:set_can_push_hero_on_shield(false)
    self:set_traversable(false)
    p_enemy.sound_id = block_sound_id
    -- Test condition for pushing like a block: "facing" overlap.
    function self:on_shield_collision_test(shield_collision_mask)
      local hero = self:get_map():get_hero()
      return self:overlaps(hero, "facing")
    end
  end
  -- Set properties to enemy.
  self:set_pushed_by_shield_properties(p_enemy)
  self:set_push_hero_on_shield_properties(p_hero)
end