local item = ...

require("scripts/multi_events")
require("scripts/ground_effects")
local hero_meta = sol.main.get_metatable("hero")

-- Initialize parameters for custom jump.
local is_hero_jumping = false
local jump_duration = 600 -- Duration of jump in milliseconds.
local max_height = 16 -- Height of jump in pixels.
local max_distance = 31 -- Max distance of jump in pixels.
local jumping_speed = math.floor(1000 * max_distance / jump_duration)
local disabled_entities -- Nearby streams and teletransporters that are disabled during the jump

function item:on_created()
  self:set_savegame_variable("possession_feather")
  self:set_assignable(true)
  --[[ Redefine event game.on_command_pressed.
  -- Avoids restarting hero animation when feather command is pressed
  -- in the middle of a jump, and using weapons while jumping. --]]
  local game = self:get_game()
  game:set_ability("jump_over_water", 0) -- Disable auto-jump on water border.
  game:register_event("on_command_pressed", function(self, command)
    local item = game:get_item("feather")
    local effect = game:get_command_effect(command)
    local slot = ((effect == "use_item_1") and 1)
        or ((effect == "use_item_2") and 2)
    if slot and game:get_item_assigned(slot) == item then
      if not item:is_jumping() then
        item:on_custom_using()
      end
      return true
    end
  end)
end

-- The custom jump can only be used under certain conditions.
-- We define "item.on_custom_using" instead of "item.on_using", which
-- is directly called by the event "game.on_command_pressed".
function item:on_custom_using()
  local hero = self:get_game():get_hero()
  self:start_custom_jump()
end

-- Used to detect if custom jump is being used.
-- Necessary to determine if other items can be used.
function item:is_jumping() return is_hero_jumping end
function hero_meta:is_jumping()
  return self:get_game():get_item("feather"):is_jumping()
end

-- Function to determine if the hero can jump on this type of ground.
local function is_jumpable_ground(ground_type)
  local is_good_ground = ( (ground_type == "traversable")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water") or (ground_type == "grass")
    or (ground_type == "ice") )
  return is_good_ground
end
-- Returns true if there are "blocking streams" below the hero.
local function blocking_stream_below_hero(map)
  local hero = map:get_hero()
  local x, y, _ = hero:get_position()
  for e in map:get_entities_in_rectangle(x, y, 1 , 1) do
    if e:get_type() == "stream" then
      return (not e:get_allow_movement())
    end
  end
  return false
end

-- Define custom jump on hero metatable.
function item:start_custom_jump()
  local game = self:get_game()
  local map = self:get_map()
  local hero = map:get_hero()

  -- Do nothing if the hero is frozen, carrying, "custom jumping",
  -- or if there is bad ground below. [Add more restrictions if necessary.]
  local hero_state = hero:get_state()
  local is_hero_frozen = hero_state == "frozen"
  local is_hero_carrying = hero_state == "carrying"
  local ground_type = map:get_ground(hero:get_position())
  local is_ground_jumpable = is_jumpable_ground(ground_type)
  local is_blocked_on_stream = blocking_stream_below_hero(map)

  if is_hero_frozen or is_hero_jumping or is_hero_carrying 
      or (not is_ground_jumpable) or is_blocked_on_stream then
    return
  end

  -- Prepare hero for jump.
  is_hero_jumping = true
  hero:unfreeze()  
  hero:save_solid_ground(hero:get_position()) -- Save solid position.
  local ws = hero:get_walking_speed() -- Default walking speed.
  hero:set_walking_speed(jumping_speed)
  hero:set_invincible(true, jump_duration)
  sol.audio.play_sound("jump")

  -- Change and fix tunic animations to display the jump.
  local state = hero:get_state()
  if state == "free" then
    hero:set_fixed_animations("jumping", "jumping")
    hero:set_animation("jumping")
  elseif state == "sword loading" then
    hero:set_fixed_animations("sword_loading_stopped", "sword_loading_stopped")
  elseif state == "sword spin attack" then
    hero:set_fixed_animations("spin_attack", "spin_attack")
  end

  -- Create shadow platform with traversable ground that follows the hero under him.
  local x, y, layer = hero:get_position()
  local platform_properties = {x=x,y=y,layer=layer,direction=0,width=8,height=8}
  local tile = map:create_custom_entity(platform_properties)
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  local sprite = tile:create_sprite("shadows/shadow_big_dynamic")
  local nb_frames = sprite:get_num_frames()
  local frame_delay = math.floor(jump_duration/nb_frames)
  sprite:set_frame_delay(frame_delay)
  -- Shadow platform has to follow the hero.
  sol.timer.start(tile, 1, function()
    tile:set_position(hero:get_position())
    return true
  end)

  -- Shift all sprites during jump with parabolic trajectory.
  local instant = 0
  sol.timer.start(item, 1, function()
    if not is_hero_jumping then return false end
    local tn = instant/jump_duration
    local height = math.floor(4*max_height*tn*(1-tn))
    for _, s in hero:get_sprites() do
      s:set_xy(0, -height)
    end
    -- Continue shifting while jumping.
    instant = instant + 1
    return true
  end)

  -- Disable nearby streams and teletransporters during the jump.
  item:disable_nearby_entities()
  
  -- Finish the jump.
  sol.timer.start(item, jump_duration, function()

    hero:set_walking_speed(ws) -- Restore initial walking speed.
    hero:set_fixed_animations(nil, nil) -- Restore tunic animations.
    tile:remove()  -- Delete shadow platform tile.
    -- If ground is empty, move hero to lower layer.
    local x,y,layer = hero:get_position()
    local ground = map:get_ground(hero:get_position())
    local min_layer = map:get_min_layer()
    while ground == "empty" and layer > min_layer do
      layer = layer-1
      hero:set_position(x,y,layer)
      ground = map:get_ground(hero:get_position())    
    end
    -- Reset sprite shifts.
    for _, s in hero:get_sprites() do s:set_xy(0, 0) end

    -- Create ground effect.
    map:ground_collision(hero)
    
    -- Enable nearby streams and teletransporters that were disabled during the jump.
    item:enable_nearby_entities()

    -- Restore solid ground as soon as possible.
    sol.timer.start(map, 1, function()
      local ground_type = map:get_ground(hero:get_position())    
      local is_good_ground = is_jumpable_ground(ground_type)
      if is_good_ground then
        hero:reset_solid_ground()
        return false
      end
      return true
    end)   

    -- Finish jump.
    item:set_finished()
    sol.timer.stop_all(item)
    is_hero_jumping = false
  end)
end

-- Create ground effects for hero landing after jump.
-- TODO: DELETE THIS FUNCTION AND USE THE ONE IN "SCRIPTS/GROUND_EFFECTS.LUA"
function item:create_ground_effect(x, y, layer)

  local map = item:get_map()
  local ground = map:get_ground(x, y, layer)
  if ground == "deep_water" or ground == "shallow_water" then
    -- If the ground has water, create a splash effect.
    map:create_ground_effect("water_splash", x, y, layer, "splash")
  elseif ground == "grass" then
    -- If the ground has grass, create leaves effect.
    map:create_ground_effect("falling_leaves", x, y, layer, "bush")
  else
    -- For other grounds, make landing sound.
    sol.audio.play_sound("hero_lands")      
  end
end

-- Disable nearby streams and teletransporters during the jump, allowing to jump over them.
function item:disable_nearby_entities()
  local map = item:get_map()
  local hero = map:get_hero()
  local hx, hy = hero:get_position()
  -- Get rectangle coordinates and disable streams on it.
  local x, y = hx - max_distance, hy - max_distance
  local w, h = 24 + 2 * max_distance, 24 + 2 * max_distance
  disabled_entities = {}
  for entity in map:get_entities_in_rectangle(x, y, w, h) do
    if entity:is_enabled() then
      if entity:get_type() == "stream" or
          entity:get_type() == "teletransporter" then
        disabled_entities[#disabled_entities + 1] = entity
        entity:set_enabled(false)
      end
    end
  end
end

-- Enable nearby streams that were disabled during the jump.
function item:enable_nearby_entities()
  for _, entity in pairs(disabled_entities) do
    if entity:exists() then
      entity:set_enabled(true)
    end
  end
  disabled_entities = nil -- Clear list.
end

-- Make streams invisible and use a sprite on custom entities instead.
local function entity_to_hide_on_created(entity)
  local map = entity:get_map()
  entity:set_visible(false)
  local sprite = entity:get_sprite()
  if sprite then -- Create custom entity with sprite.
    local x, y, layer = entity:get_position()
    local w, h = entity:get_size()
    local id = sprite:get_animation_set()
    local anim = sprite:get_animation()
    local dir = sprite:get_direction()
    local prop = {x = x, y = y, layer = layer,
      direction = dir, width = w, height = h, sprite = id}
    local sprite_entity = map:create_custom_entity(prop)
    -- Destroy the sprite entity if the entity is destroyed.
    entity:register_event("on_removed", function(entity)
      if sprite_entity and sprite_entity:exists() then
        sprite_entity:remove()
      end
    end)
  end
end

local stream_meta = sol.main.get_metatable("stream")
stream_meta:register_event("on_created", entity_to_hide_on_created)
local teletransporter_meta = sol.main.get_metatable("teletransporter")
teletransporter_meta:register_event("on_created", entity_to_hide_on_created)
