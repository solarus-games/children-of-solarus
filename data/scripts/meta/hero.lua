-- Initialize hero behavior specific to this quest.

local hero_meta = sol.main.get_metatable("hero")

function hero_meta:on_created()

  local hero = self
  hero:set_tunic_sprite_id("hero/eldran")
end

return true
