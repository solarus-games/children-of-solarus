-- Clucko script.
-- Solarus Lua API documentation: http://www.solarus-games.org/doc/latest

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local sprite, shadow_sprite, shadow_timer
local speed = 50
local max_height, current_height = 16, 0
local state

-- Event called when the custom enemy is initialized.
function enemy:on_created()
  -- Create sprites.
  sprite = self:get_sprite()
  if not sprite then
    sprite = self:create_sprite("animals/clucko_white")
  end
  shadow_sprite = self:create_sprite("shadows/shadow_big")
  self:bring_sprite_to_back(shadow_sprite)
  -- Set properties.
  self:set_invincible_sprite(shadow_sprite)
  self:set_life(1)
  self:set_can_be_pushed_by_shield(true)
  -- Define attack consequences.
  for _, attack in pairs({"sword", "thrown_item", "explosion",
      "arrow", "hookshot", "boomerang", "fire"}) do
    -- Call event "enemy.on_custom_attack_received".
    enemy:set_attack_consequence(attack, "custom")
  end
end

-- Create random movement and animations.
function enemy:on_restarted()
  enemy:set_can_attack(false) -- Do not allow to attack the hero.
  enemy:update_shadow() -- Update frame for shadow sprite.
  state = "walking" -- TODO: THIS NEEDS TO BE CHANGED.
end

-- Kill the enemy if hurt by fire. Otherwise, do not hurt but show hurt animation.
function enemy:on_custom_attack_received(attack, sprite)
  if attack == "fire" then self:hurt(1) -- Kill enemy.
  else self:hurt(0) end -- Do not hurt, but show a hurt animation.
end

-- Update shadow frame and animation.
function enemy:update_shadow()
  -- Stop shadow timers.
  if shadow_timer then shadow_timer:stop() end
  -- Update shadow frame while ascending or descending.
  ----shadow_sprite:set_animation("ascend")
  local num_frames = shadow_sprite:get_num_frames()
  shadow_timer = sol.timer.start(enemy, 10, function()
    local frame = math.floor((current_height / max_height) * num_frames)
    frame = math.min(frame, num_frames - 1)
    shadow_sprite:set_frame(frame)
    return true
  end)  
end
