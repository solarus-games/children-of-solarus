-- This script adds to maps some functions that allow you to put the map
-- into the dark.
--
-- Maps will have the following new functions:
-- map:get_light() and map:set_light().
--
-- Usage:
--
-- require("scripts/maps/light_manager")
--
-- your_map:set_light(0)  -- Put the map into the dark.
-- your_map:set_light(1)  -- Restore normal light.

local light_manager = {}

require("scripts/multi_events")

-- Dark overlay for each hero direction.
local dark_surfaces = {
  [0] = sol.surface.create("entities/dark0.png"),
  [1] = sol.surface.create("entities/dark1.png"),
  [2] = sol.surface.create("entities/dark2.png"),
  [3] = sol.surface.create("entities/dark3.png")
}
local black = {0, 0, 0}

local map_meta = sol.main.get_metatable("map")

local function dark_map_on_draw(map, dst_surface)

  if map:get_light() ~= 0 then
    -- Normal light: nothing special to do.
    return
  end

  -- Map normally dark but maybe there are torches.
  if map.lit_torches ~= nil then
    for torch in pairs(map.lit_torches) do
      if torch:exists() and
          torch:is_enabled() then
        return
      end
    end
  end

  -- Dark room.
  local screen_width, screen_height = dst_surface:get_size()
  local hero = map:get_entity("hero")
  local hero_x, hero_y = hero:get_center_position()
  local camera_x, camera_y = map:get_camera():get_bounding_box()
  local x = 320 - hero_x + camera_x
  local y = 240 - hero_y + camera_y
  local dark_surface = dark_surfaces[hero:get_direction()]
  dark_surface:draw_region(
      x, y, screen_width, screen_height, dst_surface)

  -- dark_surface may be too small if the screen size is greater
  -- than 320x240. In this case, add black bars.
  if x < 0 then
    dst_surface:fill_color(black, 0, 0, -x, screen_height)
  end

  if y < 0 then
    dst_surface:fill_color(black, 0, 0, screen_width, -y)
  end

  local dark_surface_width, dark_surface_height = dark_surface:get_size()
  if x > dark_surface_width - screen_width then
    dst_surface:fill_color(black, dark_surface_width - x, 0,
        x - dark_surface_width + screen_width, screen_height)
  end

  if y > dark_surface_height - screen_height then
    dst_surface:fill_color(black, 0, dark_surface_height - y,
        screen_width, y - dark_surface_height + screen_height)
  end
end

function map_meta:get_light()

  return self.light or 1
end

function map_meta:set_light(light)
  
  self.light = light

  if light ~= 0 then
      -- Normal light: nothing special to do.
    return
  end

  self:register_event("on_draw", dark_map_on_draw)
end

-- Function called by the torch script when a torch state has changed.
function map_meta:torch_changed(torch)

  self.lit_torches = self.lit_torches or {}

  local lit = torch:is_lit()
  if lit then
    self.lit_torches[torch] = true
  else
    self.lit_torches[torch] = nil
  end
end

return light_manager
