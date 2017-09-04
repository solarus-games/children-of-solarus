-- The money counter shown in the game screen.

local money_builder = {}

function money_builder:new(game, config)

  local money_hud = {}

  money_hud.dst_x, money_hud.dst_y = config.x, config.y

  money_hud.surface = sol.surface.create(48, 12)
  money_hud.digits_text = sol.text_surface.create{
    font = "white_digits",
    horizontal_alignment = "left",
  }
  money_hud.digits_text:set_text(game:get_money())
  money_hud.money_icons_img = sol.surface.create("hud/money_icon.png")
  money_hud.money_bag_displayed = game:get_item("money_bag"):get_variant()
  money_hud.money_displayed = game:get_money()

  function money_hud:check()

    local need_rebuild = false
    local money_bag = game:get_item("money_bag"):get_variant()
    local money = game:get_money()

    -- Max money.
    if money_bag ~= money_hud.money_bag_displayed then
      need_rebuild = true
      money_hud.money_bag_displayed = money_bag
    end

    -- Current money.
    if money ~= money_hud.money_displayed then
      need_rebuild = true
      local increment
      if money > money_hud.money_displayed then
        increment = 1
      else
        increment = -1
      end
      money_hud.money_displayed = money_hud.money_displayed + increment

      -- Play a sound if we have just reached the final value.
      if money_hud.money_displayed == money then
        sol.audio.play_sound("money_counter_end")

      -- While the counter is scrolling, play a sound every 3 values.
      elseif money_hud.money_displayed % 3 == 0 then
        sol.audio.play_sound("money_counter_end")
      end
    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      money_hud:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(money_hud, 40, function()
      money_hud:check()
    end)
  end

  function money_hud:rebuild_surface()

    money_hud.surface:clear()

    -- Max money (icon).
    money_hud.money_icons_img:draw_region((money_hud.money_bag_displayed - 1) * 12, 0, 12, 12, money_hud.surface)

    -- Current money (counter).
    local max_money = game:get_max_money()
    if money_hud.money_displayed == max_money then
      money_hud.digits_text:set_font("green_digits")
    else
      money_hud.digits_text:set_font("white_digits")
    end
    money_hud.digits_text:set_text(money_hud.money_displayed)
    money_hud.digits_text:draw(money_hud.surface, 16, 5)
  end

  function money_hud:get_surface()
    return money_hud.surface
  end

  function money_hud:on_draw(dst_surface)

    local x, y = money_hud.dst_x, money_hud.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    money_hud.surface:draw(dst_surface, x, y)
  end

  function money_hud:on_started()
    money_hud:check()
    money_hud:rebuild_surface()
  end

  return money_hud
end

return money_builder
