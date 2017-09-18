-- Initialize hero behavior specific to this quest.

local hero_meta = sol.main.get_metatable("hero")

function hero_meta:on_created()

  local hero = self
  hero:set_tunic_sprite_id("hero/eldran")
  hero:initialize_fixing_functions() -- Used to fix direction and animations.
end

--------------------------------------------------
-- Functions to fix tunic animation and direction.
--------------------------------------------------
local fixed_direction, fixed_stopped_animation, fixed_walking_animation

-- Return true if the hero is walking.
function hero_meta:is_walking()

  local m = self:get_movement()
  return m and m.get_speed and m:get_speed() > 0
end

-- Get fixed direction for the hero.
function hero_meta:get_fixed_direction()

  return fixed_direction
end

-- Get fixed stopped/walking animations for the hero.
function hero_meta:get_fixed_animations()

  return fixed_stopped_animation, fixed_walking_animation
end

-- Set a fixed direction for the hero (or nil to disable it).
function hero_meta:set_fixed_direction(new_direction)

  fixed_direction = new_direction
  if fixed_direction then self:get_sprite("tunic"):set_direction(fixed_direction) end
end

-- Set fixed stopped/walking animations for the hero (or nil to disable them).
function hero_meta:set_fixed_animations(new_stopped_animation, new_walking_animation)

  fixed_stopped_animation = new_stopped_animation
  fixed_walking_animation = new_walking_animation
  -- Initialize fixed animations if necessary.
  local state = self:get_state()
  if state == "free" then
    if self:is_walking() then self:set_animation(fixed_walking_animation or "walking")
    else self:set_animation(fixed_stopped_animation or "stopped") end
  end
end

-- Initialize events to fix direction and animation for the tunic sprite of the hero.
-- For this purpose, we redefine on_created and set_tunic_sprite_id events for the hero metatable.
function hero_meta:initialize_fixing_functions()

  local hero = self
  local sprite = hero:get_sprite("tunic")

  -- Define events for the tunic sprite.
  function sprite:on_animation_changed(animation)
    local tunic_animation = sprite:get_animation()
    if tunic_animation == "stopped" and fixed_stopped_animation ~= nil then 
      if fixed_stopped_animation ~= tunic_animation then
        sprite:set_animation(fixed_stopped_animation)
      end
    elseif tunic_animation == "walking" and fixed_walking_animation ~= nil then 
      if fixed_walking_animation ~= tunic_animation then
        sprite:set_animation(fixed_walking_animation)
      end
    --elseif tunic_animation == "pushing" then
      --local pushing_animation = hero:get_pushing_animation()
      --if pushing_animation then hero:set_animation(pushing_animation) end
    --end
  end
  function sprite:on_direction_changed(animation, direction)
    local fixed_direction = fixed_direction
    local tunic_direction = sprite:get_direction()
    if fixed_direction ~= nil and fixed_direction ~= tunic_direction then
      sprite:set_direction(fixed_direction)
    end
  end
end

-- Initialize fixing functions for the new sprite when the tunic sprite is changed.
local old_set_tunic = hero_meta.set_tunic_sprite_id -- We redefine this function.
function hero_meta:set_tunic_sprite_id(sprite_id)
    old_set_tunic(self, sprite_id)
    self:initialize_fixing_functions()
  end
end


return true