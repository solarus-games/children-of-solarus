-- IMPORTANT: create the butterflies on the upper floor to ignore obstacles!

local entity = ...

function entity:on_created()
  self:set_drawn_in_y_order(true)
  self:set_size(8, 8); self:set_origin(4, 4)
  self:move()
end

-- Create random movement.
function entity:move()
  self:stop_movement()
  local m = sol.movement.create("straight")
  local angle = 2*math.pi*math.random(); m:set_angle(angle)
  m:set_speed(10); m:set_max_distance(10)
  function m:on_finished() entity:move() end
  function m:on_obstacle_reached() entity:move() end
  m:start(self)
end