-- Lua script for sunset effect.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

-------------------------------------------------------------------------------

local sunset_effect = {}

local game = sol.main.game

-- Overlay surfaces for changing colors.
local quest_w, quest_h = sol.video.get_quest_size()
local overlay_surface_yellow = sol.surface.create(quest_w, quest_h)
overlay_surface_yellow:set_opacity(64)
overlay_surface_yellow:set_blend_mode("add")
overlay_surface_yellow:fill_color({245, 128, 33})
local overlay_surface_red = sol.surface.create(quest_w, quest_h)
overlay_surface_red:set_opacity(64)
overlay_surface_red:set_blend_mode("multiply")
overlay_surface_red:fill_color({255, 209, 221})

-- Draw
function sunset_effect:draw(dst_surface)
   overlay_surface_red:draw(dst_surface)
   overlay_surface_yellow:draw(dst_surface)
end

-- Return
return sunset_effect
