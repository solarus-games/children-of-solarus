--[[
 Adds pushing functions to hero and enemies.
 This is used by the shield script, but can be used independently too.
 Usage:
 require("scripts/pushing_manager")
--]]
--[[
This is defined for entities of types: "hero" and "enemy".
It can be extended to other types of entities.
-------- FUNCTIONS:
hero/enemy:push(table)
hero/enemy:is_being_pushed()
hero/enemy:set_being_pushed(boolean)
hero/enemy:is_being_pushed_by(pushing_entity)
hero/enemy:set_being_pushed_by(pushing_entity, boolean)

-------- VARIABLES in tables of properties:
-distance
-speed
-sound_id
-pushing_entity or angle
-push_delay
-num_directions: 4 or "any".
-on_pushing, on_pushed (callback functions)
--]]
local hero_meta = sol.main.get_metatable("hero")
local enemy_meta = sol.main.get_metatable("enemy")
local game_meta = sol.main.get_metatable("game")

-- Set/get pushing state for hero.
function hero_meta:is_being_pushed()
  return self.being_pushed or false
end
function hero_meta:set_being_pushed(pushed)
  self.being_pushed = pushed or false
end
function hero_meta:is_being_pushed_by(pushing_entity)
  return self.being_pushed_by == pushing_entity
end
function hero_meta:set_being_pushed_by(pushing_entity, pushed)
  self.being_pushed = pushed or false
  self.being_pushed_by = nil
  if pushed and pushing_entity then self.being_pushed_by = pushing_entity end
end
-- Reset hero pushing state when changing maps.
game_meta:register_event("on_map_changed", function(self)
  self:get_hero():set_being_pushed_by(nil, false)
end)

-- Set/get pushing state for enemies.
function enemy_meta:is_being_pushed()
  return self.being_pushed or false
end
function enemy_meta:set_being_pushed(pushed)
  self.being_pushed = pushed or false
end
function enemy_meta:is_being_pushed_by(pushing_entity)
  return self.being_pushed_by == pushing_entity
end
function enemy_meta:set_being_pushed_by(pushing_entity, pushed)
  self.being_pushed = pushed or false
  self.being_pushed_by = nil
  if pushed and pushing_entity then self.being_pushed_by = pushing_entity end
end

-- Pushing function.
for _, entity_meta in pairs({enemy_meta, hero_meta}) do
  function entity_meta:push(properties)
    local e = self
    local map = self:get_map()
    local hero = map:get_hero()
    -- Check if entity can be pushed. Get properties.
    if e:is_being_pushed() then return end
    local p = properties or {}
    local push_delay = p.push_delay or 200
    local sound_id = p.sound_id
    local distance = p.distance or 16
    local speed = p.speed or 120
    local num_directions = p.num_directions or "any"
    local pushing_entity = p.pushing_entity
    local on_pushing, on_pushed = p.on_pushing, p.on_pushed
    local angle = (pushing_entity and pushing_entity:get_angle(e)) or p.angle or 0
    if num_directions == 4 then
      angle = pushing_entity:get_direction4_to(e) * math.pi / 2
    end
    local pos = {x = 0, y = 0, x0 = 0, y0 = 0} -- Movement coordinates.
    -- Disable push temporarily.
    e:set_being_pushed(true)
    sol.timer.start(map, push_delay, function()
      e:set_being_pushed(false)
    end)
    -- Prepare behavior on each case.
    local obstacle_behavior
    if e == hero then
      e:freeze() -- Freeze hero during push.
    elseif e:get_type() == "enemy" then
      -- Modify obstacle behavior for enemies to allow falling on bad grounds.
      obstacle_behavior = e:get_obstacle_behavior()
      e:set_obstacle_behavior("flying")
    end
    -- Play sound if any.
    if sound_id then
      sol.audio.play_sound(sound_id)
    end
    -- Create movement.
    local m = sol.movement.create("straight")
    m:set_angle(angle)
    m:set_speed(speed)
    m:set_max_distance(distance)
    -- Apply movement indirectly (using a list) to avoid direction change.
    function m:on_position_changed()
      local dx, dy = pos.x - pos.x0, pos.y - pos.y0 -- Get movement shift.
      pos.x0, pos.y0 = pos.x, pos.y -- Update origin coordinates.
      -- Force movement if possible.
      local x, y, layer = e:get_position()
      if e:test_obstacles(dx, dy, layer) then return end
      e:set_position(x + dx, y + dy, layer) -- Shift position.
    end
    -- Finish movement.
    local function finish_push(prop)
      if e == hero then
        -- Unfreeze hero.
        self:unfreeze()
      elseif e:get_type() == "enemy" then        
        -- Restart enemy and traversable properties.
        e:restart()
        e:set_obstacle_behavior(obstacle_behavior)
        -- Make enemy fall on bad grounds if necessary.
        map:ground_collision(e, nil, nil)
      end
      -- Second callback.
      if on_pushed then on_pushed() end 
    end
    function m:on_finished() finish_push() end
    function m:on_obstacle_reached() finish_push() end
    m:start(pos) -- Start movement.
    -- First callback.
    if on_pushing then on_pushing() end
  end
end
