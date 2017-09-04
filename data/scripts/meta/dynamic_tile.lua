-- Initialize dynamic tile behavior specific to this quest.

local dynamic_tile_meta = sol.main.get_metatable("dynamic_tile")

function dynamic_tile_meta:on_created()

  local name = self:get_name()
  if name == nil then
    return
  end

  if name:match("^invisible_tile") then
    self:set_visible(false)
  end

  if name:match("^lens_invisible_tile") then
    self:set_visible(false)
    sol.timer.start(self, 10, function()
      local lens = self:get_game():get_item("lens_of_truth")
      lens:update_invisible_entity(self)
      return true
    end)
  end

  if name:match("^lens_fake_tile") then
    self:set_visible(true)
    sol.timer.start(self, 10, function()
      local lens = self:get_game():get_item("lens_of_truth")
      lens:update_fake_entity(self)
      return true
    end)
  end
end

return true
