-- This script opens doors with common conditions like killing enemies,
-- based on the name of the door and of enemies.
-- Doors with prefix auto_door are automatically opened when killing
-- the last enemy with prefix auto_enemy_<door_name>,
-- or when activating the switch auto_switch_<door_name>,
-- or when lighting the last torch auto_torch_<door_name>.
-- or when unlighting the last torch auto_torch_lit_<door_name>.

local door_manager = {}

function door_manager:manage_map(map)

  -- Find doors with prefix auto_door.
  for door in map:get_entities("auto_door") do
    -- If there are enemies whose name matches the door, link them to the door.
    door_manager:open_when_enemies_dead(door)

    -- If there is a switch whose name matches the door, link it to the door.
    door_manager:open_when_switch_activated(door)

    -- If there are torches whose name matches the door, link them to the door.
    door_manager:open_when_torches_lit(door)
    door_manager:open_when_torches_unlit(door)
  end
end

-- Returns whether there exists at least one entity with the specified
-- prefix in the region of the hero.
local function has_entities_with_prefix_in_region(map, prefix)

  local hero = map:get_hero()
  for entity in map:get_entities(prefix) do
    if entity:is_in_same_region(hero) then
      return true
    end
  end
  return false
end

function door_manager:open_when_enemies_dead(door)

  local door_prefix = door:get_name()
  local enemy_prefix = "auto_enemy_" .. door_prefix

  local map = door:get_map()
  local enemies = {}
  local function enemy_on_dead()
    if door:is_closed() and not has_entities_with_prefix_in_region(map, enemy_prefix) then
      sol.audio.play_sound("secret")
      map:open_doors(door_prefix)
    end
  end

  for enemy in map:get_entities(enemy_prefix) do
    enemy.on_dead = enemy_on_dead
  end
end

function door_manager:open_when_switch_activated(door)

  local map = door:get_map()
  local door_prefix = door:get_name()
  local switch_name = "auto_switch_" .. door_prefix
  local switch = map:get_entity(switch_name)
  if switch ~= nil then
    switch:register_event("on_activated", function()
      sol.audio.play_sound("secret")
      map:open_doors(door_prefix)
    end)
    switch:register_event("on_inactivated", function()
      map:close_doors(door_prefix)
    end)

    if door:is_open() then
      -- Door saved in state open.
      switch:set_activated(true)
    end
  end
end

function door_manager:open_when_torches_lit(door)

  local door_prefix = door:get_name()
  local torch_prefix = "auto_torch_" .. door_prefix

  local map = door:get_map()
  local remaining = 0
  local function torch_on_lit()
    if door:is_closed() then
      remaining = remaining - 1
      if remaining == 0 then
        sol.audio.play_sound("secret")
        map:open_doors(door_prefix)
      end
    end
  end

  local has_torches = false
  for torch in map:get_entities(torch_prefix) do
    if not torch:is_lit() then
      remaining = remaining + 1
    end
    torch.on_lit = torch_on_lit
    has_torches = true
  end
  if has_torches and remaining == 0 then
    -- All torches of this door are already lit.
    map:set_doors_open(door_prefix, true)
  end
end

function door_manager:open_when_torches_unlit(door)

  local door_prefix = door:get_name()
  local torch_prefix = "auto_torch_lit_" .. door_prefix

  local map = door:get_map()
  local remaining = 0
  local function torch_on_unlit()
    if door:is_closed() then
      remaining = remaining - 1
      if remaining == 0 then
        sol.audio.play_sound("secret")
        map:open_doors(door_prefix)
      end
    end
  end

  local has_torches = false
  for torch in map:get_entities(torch_prefix) do
    if torch:is_lit() then
      remaining = remaining + 1
    end
    torch.on_unlit = torch_on_unlit
    has_torches = true
  end
  if has_torches and remaining == 0 then
    -- All torches of this door are already unlit.
    map:set_doors_open(door_prefix, true)
  end
end

return door_manager
