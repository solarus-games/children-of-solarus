-- Provides additional camera features for this quest.

local camera_meta = sol.main.get_metatable("camera")

function camera_meta:shake(config, callback)

  local shaking_count_max = config ~= nil and config.count or 9
  local amplitude = config ~= nil and config.amplitude or 4
  local speed = config ~= nil and config.speed or 60

  local camera = self
  local map = camera:get_map()
  local hero = map:get_hero()

  local shaking_to_right = true
  local shaking_count = 0

  local function shake_step()

    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_smooth(false)
    movement:set_ignore_obstacles(true)

    -- Determine direction.
    if shaking_to_right then
      movement:set_angle(0)  -- Right.
    else
      movement:set_angle(math.pi)  -- Left.
    end

    -- Max distance.
    movement:set_max_distance(amplitude)

    -- Inverse direction for next time.
    shaking_to_right = not shaking_to_right
    shaking_count = shaking_count + 1

    -- Launch the movement and repeat if needed.
    movement:start(camera, function()

      -- Repeat shaking until the count_max is reached.
      if shaking_count <= shaking_count_max then
        -- Repeat shaking.
        shake_step()
      else
        -- Finished.
        camera:start_tracking(hero)
        if callback ~= nil then
          callback()
        end
      end
    end)
  end

  shake_step()
end

return true
