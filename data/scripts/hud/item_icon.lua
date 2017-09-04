-- An icon that shows the inventory item assigned to a slot.

local item_icon_builder = {}

function item_icon_builder:new(game, config)

  local item_icon = {}

  local dst_x, dst_y = config.x, config.y

  item_icon.slot = config.slot or 1
  item_icon.surface = sol.surface.create(32, 28)
  item_icon.background_img = sol.surface.create("hud/item_icon_" .. item_icon.slot .. ".png")
  item_icon.item_sprite = sol.sprite.create("entities/items")
  item_icon.item_displayed = nil
  item_icon.item_variant_displayed = 0
  item_icon.amount_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top"
  }
  item_icon.amount_displayed = nil
  item_icon.max_amount_displayed = nil

  function item_icon:check()

    local need_rebuild = false

    -- Item assigned.
    local item = game:get_item_assigned(item_icon.slot)
    if item_icon.item_displayed ~= item then
      need_rebuild = true
      item_icon.item_displayed = item
      item_icon.item_variant_displayed = nil
      if item ~= nil then
        item_icon.item_sprite:set_animation(item:get_name())
      end
    end

    if item ~= nil then
      -- Variant of the item.
      local item_variant = item:get_variant()
      if item_icon.item_variant_displayed ~= item_variant then
        need_rebuild = true
        item_icon.item_variant_displayed = item_variant
        item_icon.item_sprite:set_direction(item_variant - 1)
      end

      -- Amount.
      if item:has_amount() then
        local amount = item:get_amount()
        local max_amount = item:get_max_amount()
        if item_icon.amount_displayed ~= amount
            or item_icon.max_amount_displayed ~= max_amount then
          need_rebuild = true
          item_icon.amount_displayed = amount
          item_icon.max_amount_displayed = max_amount
        end
      elseif item_icon.amount_displayed ~= nil then
        need_rebuild = true
        item_icon.amount_displayed = nil
        item_icon.max_amount_displayed = nil
      end
    elseif item_icon.amount_displayed ~= nil then
      need_rebuild = true
      item_icon.amount_displayed = nil
      item_icon.max_amount_displayed = nil
    end

    -- Redraw the surface only if something has changed.
    if need_rebuild then
      item_icon:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(item_icon, 50, function()
      item_icon:check()
    end)
  end

  function item_icon:rebuild_surface()

    item_icon.surface:clear()

    -- Background image.
    item_icon.background_img:draw(item_icon.surface)

    if item_icon.item_displayed ~= nil then
      -- Item.
      item_icon.item_sprite:draw(item_icon.surface, 12, 17)
      if item_icon.amount_displayed ~= nil then
        -- Amount.
        item_icon.amount_text:set_text(tostring(item_icon.amount_displayed))
        if item_icon.amount_displayed == item_icon.max_amount_displayed then
          item_icon.amount_text:set_font("green_digits")
        else
          item_icon.amount_text:set_font("white_digits")
        end
        item_icon.amount_text:draw(item_icon.surface, 18, 16)
      end
    end
  end

  function item_icon:get_surface()
    return item_icon.surface
  end

  function item_icon:on_draw(dst_surface)

    if not game:is_dialog_enabled() then
      local x, y = dst_x, dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      item_icon.surface:draw(dst_surface, x, y)
    end
  end

  function item_icon:on_started()
    item_icon:check()
    item_icon:rebuild_surface()
  end

  return item_icon
end

return item_icon_builder
