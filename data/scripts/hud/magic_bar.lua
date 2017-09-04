-- The magic bar shown in the game screen.

local magic_bar_builder = {}

function magic_bar_builder:new(game, config)

  local magic_bar = {}

  magic_bar.dst_x, magic_bar.dst_y = config.x, config.y

  magic_bar.surface = sol.surface.create(88, 8)
  magic_bar.magic_bar_img = sol.surface.create("hud/magic_bar.png")
  magic_bar.container_sprite = sol.sprite.create("hud/magic_bar")
  magic_bar.magic_displayed = game:get_magic()
  magic_bar.max_magic_displayed = 0

  -- Checks whether the view displays the correct info
  -- and updates it if necessary.
  function magic_bar:check()

    local max_magic = game:get_max_magic()
    local magic = game:get_magic()

    -- Maximum magic.
    if max_magic ~= magic_bar.max_magic_displayed then
      if magic_bar.magic_displayed > max_magic then
        magic_bar.magic_displayed = max_magic
      end
      magic_bar.max_magic_displayed = max_magic
      if max_magic > 0 then
        magic_bar.container_sprite:set_direction(max_magic / 42 - 1)
      end
    end

    -- Current magic.
    if magic ~= magic_bar.magic_displayed then
      local increment
      if magic < magic_bar.magic_displayed then
        increment = -1
      elseif magic > magic_bar.magic_displayed then
        increment = 1
      end
      if increment ~= 0 then
        magic_bar.magic_displayed = magic_bar.magic_displayed + increment

        -- Play the magic bar sound.
        if (magic - magic_bar.magic_displayed) % 10 == 1 then
          sol.audio.play_sound("magic_bar")
        end
      end
    end

    -- Magic decreasing animation.
    if game.is_magic_decreasing ~= nil then
      local sprite = magic_bar.container_sprite
      if game:is_magic_decreasing() and sprite:get_animation() ~= "decreasing" then
        sprite:set_animation("decreasing")
      elseif not game:is_magic_decreasing() and sprite:get_animation() ~= "normal" then
        sprite:set_animation("normal")
      end
    end

    -- Schedule the next check.
    sol.timer.start(magic_bar, 20, function()
      magic_bar:check()
    end)
  end

  function magic_bar:get_surface()
    return magic_bar.surface
  end

  function magic_bar:on_draw(dst_surface)

    -- Is there a magic bar to show?
    if magic_bar.max_magic_displayed > 0 then
      local x, y = magic_bar.dst_x, magic_bar.dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      -- Max magic.
      magic_bar.container_sprite:draw(dst_surface, x, y)

      -- Current magic.
      magic_bar.magic_bar_img:draw_region(46, 24, 2 + magic_bar.magic_displayed, 8, dst_surface, x, y)

      -- Fix left and right borders.
      if magic_bar.magic_displayed == 0 then
        -- Fix darker pixels on the right border.
        dst_surface:fill_color({ 0, 0, 0}, x + 1, y + 1, 1, 6)
      end
      if magic_bar.magic_displayed == magic_bar.max_magic_displayed then
        -- Fix darker pixels on the right border.
        magic_bar.magic_bar_img:draw_region(132, 25, 1, 6, dst_surface, x + 44, y + 1)
      end
    end
  end

  function magic_bar:on_started()
    magic_bar:check()
  end

  return magic_bar
end

return magic_bar_builder
