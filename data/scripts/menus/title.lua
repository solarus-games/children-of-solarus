local title_screen = {}

local background_img = sol.surface.create("menus/title_background.png")
local logo_img = sol.surface.create("menus/title_logo.png")

function title_screen:on_started()

  sol.audio.play_music("eduardo/title_screen")
end

function title_screen:on_draw(dst_surface)

-- TODO
--  background_img:draw(dst_surface)
--  logo_img:draw(dst_surface, 91, 12)
end

function title_screen:on_key_pressed(key)

  if key == "return" or key == "space" then
    sol.audio.play_sound("pause_closed")
    sol.menu.stop(title_screen)
  end
end

function title_screen:on_joypad_button_pressed(button)

  return self:on_key_pressed("space")
end

return title_screen

