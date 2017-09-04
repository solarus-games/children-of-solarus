-- The icon that shows what the pause command does.

local pause_icon_builder = {}

function pause_icon_builder:new(game, config)

  local pause_icon = {}

  local dst_x, dst_y = config.x, config.y

  pause_icon.game = game
  pause_icon.is_game_paused = false
  pause_icon.surface = sol.surface.create(72, 24)
  pause_icon.icons_img = sol.surface.create("pause_icon.png", true)
  pause_icon.icon_region_y = 24
  pause_icon.icon_flip_sprite = sol.sprite.create("hud/pause_icon_flip")

  function pause_icon.icon_flip_sprite:on_animation_finished()
    if pause_icon.icon_region_y == nil then
      pause_icon.icon_region_y = 24
      if game:is_paused() then
        pause_icon.icon_region_y = 48
      end
      pause_icon:rebuild_surface()
    end
  end

  function pause_icon.icon_flip_sprite:on_frame_changed()
    pause_icon:rebuild_surface()
  end

  function pause_icon:on_paused()
    pause_icon.icon_region_y = nil
    pause_icon.icon_flip_sprite:set_frame(0)
    pause_icon:rebuild_surface()
  end

  function pause_icon:on_unpaused()
    pause_icon.icon_region_y = nil
    pause_icon.icon_flip_sprite:set_frame(0)
    pause_icon:rebuild_surface()
  end

  function pause_icon:rebuild_surface()

    pause_icon.surface:clear()

    if pause_icon.icon_region_y ~= nil then
      -- Draw the static image of the icon: "Pause" or "Back".
      pause_icon.icons_img:draw_region(0, self.icon_region_y, 72, 24, pause_icon.surface)
    else
      -- Draw the flipping sprite
      pause_icon.icon_flip_sprite:draw(self.surface, 24, 0)
    end
  end

  function pause_icon:get_surface()
    return pause_icon.surface
  end

  function pause_icon:on_draw(dst_surface)

    if not game:is_dialog_enabled() then
      local x, y = dst_x, dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      pause_icon.surface:draw(dst_surface, x, y)
    end
  end

  pause_icon:rebuild_surface()

  return pause_icon
end

return pause_icon_builder
