-- Lua script of enemy diarandor/goblin.
-- This script is executed every time an enemy with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite, weapon_sprite
local movement
-- CUSTOM PROPERTY "weapon" has values: "club", "axe", "none" (or nil), "random".

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
  enemy:set_can_be_pushed_by_shield(true)
  enemy:set_can_push_hero_on_shield(true)
  -- Initialize weapon from custom properties.
  local weapon_name = self:get_property("weapon")
  if weapon_name ~= nil and weapon_name ~= "none" then
    enemy:set_weapon(weapon_name)
  end
end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()

  movement = sol.movement.create("target")
  movement:set_target(hero)
  movement:set_speed(48)
  movement:start(enemy)
end

-- Weapon names: "club", "axe", "slingshot", "random".
function enemy:set_weapon(weapon_name)
  -- Choose randon weapon, if necessary.
  local weapon_list = {"club", "axe", "slingshot"}
  if weapon_name == "random" then
    local index = math.random(1, #weapon_list)
    weapon_name = weapon_list[index]
  end
  -- Set sprites and properties for each weapon.
  local sprite_id = sprite:get_animation_set()
  local weapon_damage = 0
  if weapon_name == "club" then weapon_damage = 2
  elseif weapon_name == "axe" then weapon_damage = 3
  elseif weapon_name == "slingshot" then
    -- Replace main sprite.
    self:remove_sprite(self:get_sprite())
    self:create_sprite(sprite_id .. "_green_slingshot")
  end
  if weapon_name == "club" or weapon_name == "axe" then
    local weapon_sprite = enemy:create_sprite(sprite_id .. "_" .. weapon_name)
    self:set_sprite_damage(weapon_sprite, weapon_damage)
    self:set_invincible_sprite(weapon_sprite)
  end
end

-- Update direction.
function enemy:on_movement_changed(movement)
  local direction4 = movement:get_direction4()
  if direction4 then
    for _, s in enemy:get_sprites() do
      s:set_direction(direction4)
    end
  end
end