local item = ...

local direction_fix_enabled = true
local shield_state, shield_command_released

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
  -- Unfreeze the hero if necessary.
  hero:unfreeze() -- This updates direction too, preventing moonwalk!
end
