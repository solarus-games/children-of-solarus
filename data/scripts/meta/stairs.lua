-- Initialize stairs behavior specific to this quest.

-- This script provides functions that don't exist in the Solarus API (yet)
-- but that we can try to implement in Lua using heuristics.

local stairs_meta = sol.main.get_metatable("stairs")

-- Returns whether these are inner stairs (platform stairs in a single room)
-- or stairs between two floors.
function stairs_meta:is_inner()

  if self.inner ~= nil then
    -- Information already cached (not the first call).
    return self.inner
  end

  -- First call.
  -- We can try to deduce if these are inner stairs by detecting
  -- if there is a teletransporter nearby.
  local inner = true
  local map = self:get_map()
  for entity in map:get_entities_in_rectangle(self:get_bounding_box()) do
    if entity:get_type() == "teletransporter" then
      inner = false
    end
  end
  self.inner = inner
  return inner
end

-- Returns the climbing direction of the stairs.
function stairs_meta:get_direction()

  if self.direction ~= nil then
    return self.direction
  end

  -- First call.
  -- Try to deduce the direction from what is traversable nearby the stairs.
  local map = self:get_map()
  local hero = map:get_hero()
  local traversable_sides = {}

  local stairs_x, stairs_y, stairs_layer = self:get_position()
  stairs_x, stairs_y = stairs_x + 8, stairs_y + 13
  local hero_x, hero_y = hero:get_position()
  local dx, dy = stairs_x - hero_x, stairs_y - hero_y

  local obstacle_sides = {
    [0] = hero:test_obstacles(dx + 16, dy, stairs_layer),
    [1] = hero:test_obstacles(dx, dy - 16, stairs_layer),
    [2] = hero:test_obstacles(dx - 16, dy, stairs_layer),
    [3] = hero:test_obstacles(dx, dy + 16, stairs_layer),
  }

  local result
  for i = 0, 3 do
    if not obstacle_sides[i] then
      result = 4 - i
    end
  end
  self.direction = result or 3
  return result
end

return true
