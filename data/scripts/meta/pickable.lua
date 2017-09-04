-- Initialize pickable behavior specific to this quest.

local pickable_meta = sol.main.get_metatable("pickable")

function pickable_meta:on_created()

  local name = self:get_name()
  if name == nil then
    return
  end

  if name:match("^lens_invisible_pickable") then
    self:set_visible(false)
    sol.timer.start(self, 10, function()
      local lens = self:get_game():get_item("lens_of_truth")
      lens:update_invisible_entity(self)
      return true
    end)
  end

end

return true
