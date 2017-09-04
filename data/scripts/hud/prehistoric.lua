-- Label shown when entering a prehistoric map.

local prehistoric_label_builder = {}

function prehistoric_label_builder:new(game, config)

  local prehistoric_label = {}

  prehistoric_label.dst_x, prehistoric_label.dst_y = config.x, config.y

  prehistoric_label.visible = false
  prehistoric_label.surface = sol.surface.create("hud/prehistoric.png")

  function prehistoric_label:on_map_changed(map)

    if map:get_world() ~= "prehistoric" then
      prehistoric_label.visible = false
    else
      sol.timer.start(prehistoric_label, 1000, function()
        prehistoric_label.visible = true
        prehistoric_label.surface:fade_in()
        sol.timer.start(prehistoric_label, 10000, function()
          prehistoric_label.surface:fade_out(function()
            prehistoric_label.visible = false
          end)
        end)
      end)
    end
    
  end

  function prehistoric_label:on_draw(dst_surface)

    if prehistoric_label.visible then
      local x, y = prehistoric_label.dst_x, prehistoric_label.dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      prehistoric_label.surface:draw(dst_surface, x, y)
    end
  end

  return prehistoric_label
end

return prehistoric_label_builder
