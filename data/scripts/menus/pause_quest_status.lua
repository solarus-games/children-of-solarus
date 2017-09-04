local submenu = require("scripts/menus/pause_submenu")
local quest_status_submenu = submenu:new()

local language_manager = require("scripts/language_manager")

function quest_status_submenu:on_started()

  submenu.on_started(self)
  self.quest_items_surface = sol.surface.create(320, 240)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.caption_text_keys = {}

  local item_sprite = sol.sprite.create("entities/items")

  -- Draw the items on a surface.
  self.quest_items_surface:clear()

  -- Tunic.
  local tunic = self.game:get_item("tunic"):get_variant()
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(tunic - 1)
  item_sprite:draw(self.quest_items_surface, 185, 177)
  self.caption_text_keys[6] = "quest_status.caption.tunic_" .. tunic

  -- Sword.
  local sword = self.game:get_item("sword"):get_variant()
  if sword > 0 then
    item_sprite:set_animation("sword")
    item_sprite:set_direction(sword - 1)
    item_sprite:draw(self.quest_items_surface, 219, 177)
    self.caption_text_keys[7] = "quest_status.caption.sword_" .. sword
  end

  -- Shield.
  local shield = self.game:get_item("shield"):get_variant()
  if shield > 0 then
    item_sprite:set_animation("shield")
    item_sprite:set_direction(shield - 1)
    item_sprite:draw(self.quest_items_surface, 253, 177)
    self.caption_text_keys[8] = "quest_status.caption.shield_" .. shield
  end

  -- Wallet.
  local rupee_bag = self.game:get_item("rupee_bag"):get_variant()
  if rupee_bag > 0 then
    item_sprite:set_animation("rupee_bag")
    item_sprite:set_direction(rupee_bag - 1)
    item_sprite:draw(self.quest_items_surface, 68, 84)
    self.caption_text_keys[0] = "quest_status.caption.rupee_bag_" .. rupee_bag
  end

  -- Bomb bag.
  local bomb_bag = self.game:get_item("bomb_bag"):get_variant()
  if bomb_bag > 0 then
    item_sprite:set_animation("bomb_bag")
    item_sprite:set_direction(bomb_bag - 1)
    item_sprite:draw(self.quest_items_surface, 68, 113)
    self.caption_text_keys[1] = "quest_status.caption.bomb_bag_" .. bomb_bag
  end

  -- Quiver.
  local quiver = self.game:get_item("quiver"):get_variant()
  if quiver > 0 then
    item_sprite:set_animation("quiver")
    item_sprite:set_direction(quiver - 1)
    item_sprite:draw(self.quest_items_surface, 68, 143)
    self.caption_text_keys[2] = "quest_status.caption.quiver_" .. quiver
  end

  -- World map.
  item_sprite:set_animation("world_map")
  item_sprite:set_direction(0)
  item_sprite:draw(self.quest_items_surface, 107, 177)
  self.caption_text_keys[3] = "quest_status.caption.world_map"

  -- Library award.
  if self.game:has_item("library_award") then
    item_sprite:set_animation("library_award")
    item_sprite:set_direction(0)
    item_sprite:draw(self.quest_items_surface, 146, 177)
    self.caption_text_keys[4] = "quest_status.caption.library_award"
  end

  -- Pieces of heart.
  local pieces_of_heart_img = sol.surface.create("menus/quest_status_pieces_of_heart.png")
  local num_pieces_of_heart = self.game:get_item("piece_of_heart"):get_num_pieces_of_heart()
  local x = 51 * num_pieces_of_heart
  pieces_of_heart_img:draw_region(x, 0, 51, 50, self.quest_items_surface, 101, 81)
  self.caption_text_keys[5] = "quest_status.caption.pieces_of_heart"

  -- Game time.
  local menu_font, menu_font_size = language_manager:get_menu_font()
  self.chronometer_txt = sol.text_surface.create({
    horizontal_alignment = "center",
    vertical_alignment = "bottom",
    font = menu_font,
    font_size = menu_font_size,
    color = { 115, 59, 22 },
    text = self.game:get_time_played_string()
  })
  sol.timer.start(self.game, 1000, function()
    self.chronometer_txt:set_text(self.game:get_time_played_string())
    return true  -- Repeat the timer.
  end)

  -- Cursor.
  self:set_cursor_position(0)
end

function quest_status_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then
    self.cursor_position = position
    if position <= 2 then
      -- Rupee bag, bomb bag, quiver.
      self.cursor_sprite_x = 68
    elseif position == 3 then
      -- World map.
      self.cursor_sprite_x = 107
    elseif position == 4 then
      -- Library award.
      self.cursor_sprite_x = 146
    elseif position == 5 then
      -- Pieces of heart.
      self.cursor_sprite_x = 126
      self.cursor_sprite_y = 107
    else
      -- Tunic, sword, shield.
      self.cursor_sprite_x = -19 + 34 * position
    end

    if position == 0 then
      self.cursor_sprite_y = 79
    elseif position == 1 then
      self.cursor_sprite_y = 108
    elseif position == 2 then
      self.cursor_sprite_y = 138
    elseif position == 5 then
      self.cursor_sprite_y = 107
    else
      self.cursor_sprite_y = 172
    end

    self:set_caption(self.caption_text_keys[position])
  end
end

function quest_status_submenu:on_command_pressed(command)

  local handled = submenu.on_command_pressed(self, command)

  if not handled then

    if command == "left" then
      if self.cursor_position <= 3 then
        self:previous_submenu()
      else
        sol.audio.play_sound("cursor")
        if self.cursor_position == 5 then
          -- Pieces of heart to rupee bag.
          self:set_cursor_position(0)
        elseif self.cursor_position == 6 then
          -- Tunic to library award.
          self:set_cursor_position(4)
        else
          self:set_cursor_position(self.cursor_position - 1)
        end
      end
      handled = true

    elseif command == "right" then
      if self.cursor_position == 5 or self.cursor_position == 8 then
        self:next_submenu()
      else
        sol.audio.play_sound("cursor")
        if self.cursor_position <= 2 then
          self:set_cursor_position(5)
        elseif self.cursor_position == 4 then
          self:set_cursor_position(6)
        else
          self:set_cursor_position(self.cursor_position + 1)
        end
      end
      handled = true

    elseif command == "down" then
      sol.audio.play_sound("cursor")
      if self.cursor_position <= 2 then
        self:set_cursor_position((self.cursor_position + 1) % 9)
      elseif self.cursor_position == 5 then
        -- Pieces of heart to world map.
        self:set_cursor_position(3)
      else
        -- Bottom position to pieces of heart.
        self:set_cursor_position(5)
      end
      handled = true

    elseif command == "up" then
      sol.audio.play_sound("cursor")
      if self.cursor_position <= 2 then
        self:set_cursor_position((self.cursor_position + 8) % 9)
      elseif self.cursor_position == 5 then
        -- Pieces of heart to world map.
        self:set_cursor_position(3)
      else
        -- Bottom position to pieces of heart.
        self:set_cursor_position(5)
      end
      handled = true
    end

  end

  return handled
end

function quest_status_submenu:on_draw(dst_surface)

  local width, height = dst_surface:get_size()
  local x = width / 2 - 160
  local y = height / 2 - 120
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.quest_items_surface:draw(dst_surface, x, y)
  self.cursor_sprite:draw(dst_surface, x + self.cursor_sprite_x, y + self.cursor_sprite_y)
  self.chronometer_txt:draw(dst_surface, x + 68, y + 186)
  self:draw_save_dialog_if_any(dst_surface)
end

return quest_status_submenu

