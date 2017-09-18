local item = ...

local use_builtin_bow = false -- Change this to switch between built-in and custom bow.
local bow_state, bow_command_released

function item:on_created()

  self:set_savegame_variable("i1102")
  self:set_amount_savegame_variable("i1025")
  self:set_assignable(true)
end

function item:on_amount_changed(amount)

  if self:get_variant() ~= 0 then
    -- update the icon (with or without arrow)
    if amount == 0 then
      self:set_variant(1)
    else
      self:set_variant(2)
    end
  end
end

function item:on_obtaining(variant, savegame_variable)

  local quiver = self:get_game():get_item("quiver")
  if not quiver:has_variant() then
    -- Give the first quiver automatically with the bow.
    quiver:set_variant(1)
  end
end

function item:on_using()

  if self:get_amount() == 0 then
    sol.audio.play_sound("wrong")
  elseif use_builtin_bow then -- Built-in bow.
    -- we remove the arrow from the equipment after a small delay because the hero
    -- does not shoot immediately
    sol.timer.start(300, function()
      self:remove_amount(1)
    end)
    self:get_map():get_entity("hero"):start_bow()
    self:set_finished()
  else -- Custom bow.
    item:use_custom_bow()
  end
end

---------------------------------
-- Program custom bow attack.
---------------------------------
function item:use_custom_bow()
  local map = self:get_map()
  local game = map:get_game()
  local hero = map:get_hero()
  local hero_tunic_sprite = hero:get_sprite()

  -- Do not use if there is bad ground below.
  if not hero:is_jumping() 
  and not map:is_solid_ground(hero:get_ground_position()) then 
    return
  end 

  -- Do nothing if game is suspended.
  if game:is_suspended() then return end
  -- Freeze hero and save state.
  hero:freeze() -- This is necessary, at least for the custom slot 0.
  if not bow_state then bow_state = "preparing" end
  bow_command_released = false
  -- Remove fixed animations (used if jumping).
  hero:set_fixed_animations(nil, nil)
  
  -- Start bow animation on hero.
  hero:get_sprite():set_animation("bow")


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
      bow_command_released = true
      return
    end
    return true
  end)
  
  -- Stop fixed bow animations if the command is released.
  sol.timer.start(item, 1, function()
    if bow_state == "loading" then
      if bow_command_released == true then
        -- Finish using item if arrow is shot.
        self:shoot_arrow()
        return
      elseif hero:get_state() == "sword swinging" then 
        -- Finish using item if sword is used.
        self:finish_using()
        return
      end
    end
    return true
  end)
  
  -- Start custom bow state when necessary: allow to sidle with bow.
  local attack_duration = hero_tunic_sprite:get_num_frames() * hero_tunic_sprite:get_frame_delay()
  sol.timer.start(item, attack_duration, function()  
    -- Do not allow walking with bow if the command was released.
    if bow_command_released == true then
      self:shoot_arrow()
      return
    end
    -- Start loading sword if necessary. Fix direction and loading animations.
    bow_state = "loading"
    hero:set_fixed_animations("bow_stopped", "bow_walking")
    local dir = hero:get_direction()
    hero:set_fixed_direction(dir)
    hero:set_animation("bow_stopped")
    hero:unfreeze() -- Allow the hero to walk.
  end)
  
end

-- Stop using items when changing maps.
function item:on_map_changed(map)
  if bow_state ~= nil then self:finish_using() end
end

function item:finish_using()
  -- Stop all timers (necessary if the map has changed, etc).
  sol.timer.stop_all(self)
  -- Finish using item.
  self:set_finished()
  -- Reset fixed animations/direction. (Used while sidling with bow.)
  local hero = self:get_map():get_hero()
  hero:set_fixed_direction(nil)
  hero:set_fixed_animations(nil, nil)
  bow_state = nil
  if hero:get_state() == "frozen" then
    hero:unfreeze()
  end
end

-- Create custom entity arrow. Shoot arrow!!!
function item:shoot_arrow()
  local map = self:get_map()
  local hero = map:get_hero()
  local dir = hero:get_direction()
  local x, y, layer = hero:get_center_position()
  -- Show arrow shot animation on hero.
  if hero:get_state() ~= "frozen" then
    hero:freeze() -- Freeze hero if necessary.
  end
  hero:set_animation("bow_finished")
  sol.timer.start(hero, 500, function()
    item:finish_using()
  end)
  -- Play bow sound.
  sol.audio.play_sound("bow")
  -- Custom shift for arrow creation.
  local arrow_shift = {
    [0] = {x = 0, y = 0},
    [1] = {x = 0, y = 0},
    [2] = {x = 0, y = 0},
    [3] = {x = 0, y = 0}}
  x = x + arrow_shift[dir].x
  y = y + arrow_shift[dir].y
  -- Create arrow entity.
  local prop = {model = "arrow", x = x, y = y, layer = layer, direction = dir, width = 16, height = 16}
  local arrow = map:create_custom_entity(prop)
  arrow:set_force(2)
  arrow:set_sprite_id("entities/arrow")
  arrow:go()
end