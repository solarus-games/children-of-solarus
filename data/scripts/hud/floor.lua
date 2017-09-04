-- The floor view shown when entering a map that has a floor.

local floor_view_builder = {}

function floor_view_builder:new(game, config)

  local floor_view = {}

  floor_view.dst_x, floor_view.dst_y = config.x, config.y

  floor_view.visible = false
  floor_view.surface = sol.surface.create(32, 85)
  floor_view.floors_img = sol.surface.create("floors.png", true)  -- Language-specific image
  floor_view.floor = nil

  function floor_view:on_map_changed(map)

    local need_rebuild = false
    local floor = map:get_floor()
    if floor == floor_view.floor
        or (floor == nil and game:get_dungeon() == nil) then
      -- No floor or unchanged floor.
      floor_view.visible = false
    else
      -- Show the floor view during 3 seconds.
      floor_view.visible = true
      local timer = sol.timer.start(floor_view, 3000, function()
        floor_view.visible = false
      end)
      timer:set_suspended_with_map(false)
      need_rebuild = true
    end

    floor_view.floor = floor

    if need_rebuild then
      floor_view:rebuild_surface()
    end
  end

  function floor_view:rebuild_surface()

    floor_view.surface:clear()

    local highest_floor_displayed
    local dungeon = game:get_dungeon()

    if dungeon ~= nil and floor_view.floor ~= nil then
      -- We are in a dungeon: show the neighboor floors before the current one.
      local nb_floors = dungeon.highest_floor - dungeon.lowest_floor + 1
      local nb_floors_displayed = math.min(7, nb_floors)

      -- If there are less 7 floors or less, show them all.
      if nb_floors <= 7 then
        highest_floor_displayed = dungeon.highest_floor
      elseif floor_view.floor >= dungeon.highest_floor - 2 then
        -- Otherwise we only display 7 floors including the current one.
        highest_floor_displayed = dungeon.highest_floor
      elseif floor_view.floor <= dungeon.lowest_floor + 2 then
        highest_floor_displayed = dungeon.lowest_floor + 6
      else
        highest_floor_displayed = floor_view.floor + 3
      end

      local src_y = (15 - highest_floor_displayed) * 12
      local src_height = nb_floors_displayed * 12 + 1

      floor_view.floors_img:draw_region(32, src_y, 32, src_height, floor_view.surface)
    else
      highest_floor_displayed = floor_view.floor
    end

    -- Show the current floor then.
    local src_y
    local dst_y

    if floor_view.floor == nil and dungeon ~= nil then
      -- Special case of the unknown floor in a dungeon.
      src_y = 32 * 12
      dst_y = 0
    else
      src_y = (15 - floor_view.floor) * 12
      dst_y = (highest_floor_displayed - floor_view.floor) * 12
    end

    floor_view.floors_img:draw_region(0, src_y, 32, 13, floor_view.surface, 0, dst_y)
  end

  function floor_view:get_surface()
    return floor_view.surface
  end

  function floor_view:on_draw(dst_surface)

    if floor_view.visible then
      local x, y = floor_view.dst_x, floor_view.dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      floor_view.surface:draw(dst_surface, x, y)
    end
  end

  return floor_view
end

return floor_view_builder
