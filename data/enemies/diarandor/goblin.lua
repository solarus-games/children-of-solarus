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
local sprite, weapon_sprite, weapon, has_weapon, has_throwable_weapon
local behavior = "passive" -- Values: "passive", "aggressive".
local detection_distance = 64
local throw_distance = 160
local body_damage = 2
local speed_axe = 100

--[[ CUSTOM PROPERTY "weapon" has values:
"club", "axe", "none" (or nil), "slingshot", "random".
--]]

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(body_damage)
  enemy:set_can_be_pushed_by_shield(true)
  enemy:set_can_push_hero_on_shield(true)
  -- Initialize weapon from custom properties.
  local weapon_name = self:get_property("weapon")
  if weapon_name ~= nil and weapon_name ~= "none" then
    enemy:set_weapon(weapon_name)
  end
end

-- Event called when the enemy should start or restart its movements.
function enemy:on_restarted()
  -- Wait a delay when restarted.
  self:stop_movement()
  for _, s in self:get_sprites() do
    if s:has_animation("stopped") then s:set_animation("stopped") end
  end
  local delay = math.random(500, 1000)
  sol.timer.start(enemy, delay, function()
    if behavior == "aggressive" and self:get_distance(hero) <= detection_distance then
      self:start_walking("go_to_hero")
    else
      self:start_walking("wander")
    end
  end)
  -- Check hero for throwing.
  if has_throwable_weapon and self:get_distance(hero) <= throw_distance then
    self:throw()
  end
end

-- Weapon names: "club", "axe", "slingshot", "random".
function enemy:get_weapon() return weapon end
function enemy:set_weapon(weapon_name)
  -- Choose random weapon, if necessary.
  weapon = weapon_name
  local weapon_list = {"club", "axe", "slingshot"}
  if weapon_name == "random" then
    local index = math.random(1, #weapon_list)
    weapon_name = weapon_list[index]
  end
  if weapon_name and weapon_name ~= "none" then
    has_weapon = true
  end
  -- Set sprites and properties for each weapon.
  local sprite_id = sprite:get_animation_set()
  local weapon_damage = 0
  if weapon_name == "club" then
    weapon_damage = 2
    behavior = "aggressive"
  elseif weapon_name == "axe" then
    weapon_damage = 3
    has_throwable_weapon = true
  elseif weapon_name == "slingshot" then
    -- Replace main sprite.
    has_throwable_weapon = true
    self:remove_sprite(self:get_sprite())
    weapon_sprite = self:create_sprite(sprite_id .. "_green_slingshot")
  end
  if weapon_name == "club" or weapon_name == "axe" then
    weapon_sprite = enemy:create_sprite(sprite_id .. "_" .. weapon_name)
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

-- Walking behaviors: "go_to_hero", "wander".
function enemy:start_walking(behavior)
  -- Prepare sprite animations.
  for _, s in self:get_sprites() do
    if s:has_animation("walking") then s:set_animation("walking") end
  end
  -- Start behavior.
  if behavior == "go_to_hero" then
    local m = sol.movement.create("target")
    m:set_target(hero)
    m:set_speed(math.random(50, 65))
    m:start(enemy)
    sol.timer.start(enemy, 1000, function()
      if enemy:get_distance(hero) > detection_distance then
        enemy:restart()
        return
      end
      return true
    end)
    -- Throw axe, if any.
    if weapon == "axe" then self:throw() end
  elseif behavior == "wander" then
    local m = sol.movement.create("straight")
    m:set_smooth(false)
    m:set_angle(math.random(0, 3) * math.pi / 2)
    m:set_speed(math.random(35, 50))
    m:set_max_distance(math.random(16, 80))
    function m:on_obstacle_reached() enemy:restart() end
    function m:on_finished() enemy:restart() end
    m:start(enemy)
  end
end

-- Throw weapons: "axe" or "seed" (slingshot).
function enemy:throw()
  -- Do nothing if there is no weapon.
  if not has_throwable_weapon then return end
  -- Remove enemy sprites if necessary.
  local sprite_id = sprite:get_animation_set() .. "_" .. weapon
  if weapon == "axe" then
    self:remove_sprite(weapon_sprite)
    weapon, weapon_sprite, has_weapon, has_throwable_weapon = nil, nil, nil, nil
    
    -- TEST:
    sol.timer.start(map, 5000, function()
      if not self:get_weapon() then
        self:set_weapon("axe")
      end
    end)
    
  end
  -- Create thrown entity.
  local x, y, layer = self:get_position()
  local dir = sprite:get_direction()
  local prop = {x=x, y=y, layer=layer, direction=dir, width=16, height=16,
    breed="diarandor/generic_projectile"}
  local projectile = map:create_enemy(prop)
  local proj_sprite = projectile:create_sprite(sprite_id)
  proj_sprite:set_animation("thrown")
  -- Create movement for projectile.
  projectile:stop_movement()
  local m = sol.movement.create("straight")
  m:set_smooth(false)
  m:set_angle(projectile:get_angle(hero))
  m:set_speed(speed_axe)
  m:set_max_distance(300)
  function projectile:on_obstacle_reached() projectile:remove() end
  function projectile:on_movement_finished() projectile:remove() end
  m:start(projectile)
  -- Initialize collision properties.
  projectile:set_invincible(true)
  projectile:set_can_be_pushed_by_shield(true)
  projectile:set_can_push_hero_on_shield(true)
  -- Override normal push function.
  function projectile:on_shield_collision()
    -- Hurt enemies after bounce on shield.
    projectile:allow_hurt_enemies(true) 
    -- Override movement.
    local m = projectile:get_movement()
    if not m then return end
    m = sol.movement.create("straight")
    m:set_angle(hero:get_angle(projectile))
    m:set_smooth(false)
    m:set_speed(speed_axe)
    m:set_max_distance(300)
    m:start(self)
  end
end
