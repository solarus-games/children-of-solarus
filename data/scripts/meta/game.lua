-- TODO the engine should have an event game:on_world_changed().
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_map_changed", function(game)

  local map = game:get_map()
  local new_world = map:get_world()
  local previous_world = game.previous_world
  local world_changed = previous_world == nil or
      new_world == nil or
      new_world ~= previous_world
  game.previous_world = new_world
  if world_changed then
    if game.on_world_changed ~= nil then
      game:on_world_changed(previous_world, new_world)
    end
  end
end)

return true
