
local entity = ...

local danger_distance = 48
local max_walking_distance = 32
local position

function entity:on_created()
  self:set_drawn_in_y_order(true)
  position, _, _ = self:get_position()
  -- Check for danger.
  sol.timer.start(self, 100, function() if self:is_in_danger() then self:fly() end; return true end)
  -- Start random actions.
  entity:random_action()
end

function entity:random_action()
  local sprite = self:get_sprite()
  local action = math.random(0, 2)
  if action == 0 then 
    self:stop_movement(); sprite:set_animation("stopped")
	sol.timer.start(self, 2000, function() entity:random_action() end)
  elseif action == 1 then
    self:stop_movement(); sprite:set_animation("peck")
	sol.timer.start(self, 2000, function() entity:random_action() end)
  elseif action == 2 then -- Jump to the left or right.
	sprite:set_animation("jump")
	local dir = math.random(0, 1)
	local x, _, _ = self:get_position()
	if math.abs(x - position + 8*math.cos(dir*math.pi)) > max_walking_distance then dir = 1-dir end
	sprite:set_direction(dir)
	local max_dist = math.random(1,8)
	local m = sol.movement.create("straight"); m:set_angle(dir*math.pi)
	m:set_speed(5); m:set_max_distance(max_dist); m:set_smooth(false)
	function m:on_finished() sprite:set_animation("stopped"); entity:random_action() end
	function m:on_obstacle_reached() sprite:set_animation("stopped"); entity:random_action() end
	m:start(self)
  end
end

function entity:is_in_danger()
  return self:get_distance(self:get_map():get_hero()) < danger_distance
end

function entity:fly()
  sol.timer.stop_all(self); self:stop_movement()
  -- Put the bird on high layer to avoid collisions.
  local x,y,z = self:get_position(); self:set_position(x,y,2) 
  self:get_sprite():set_animation("fly")
  -- Get direction opposite to hero, if possible. 
  local dir = self:get_map():get_hero():get_direction4_to(self)
  if dir ~= 0 and dir ~=2 then dir = 2*math.random(0,1) end
  self:set_direction(dir/2) -- (Sprite directions can be 0 and 1.)
  local m = sol.movement.create("straight"); m:set_angle(dir*math.pi/2); m:set_speed(150)
  function m:on_obstacle_reached() entity:remove() end
  function m:on_finished() entity:remove() end
  m:start(self)
end

