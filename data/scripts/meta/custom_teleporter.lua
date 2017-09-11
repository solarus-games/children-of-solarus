--[[
Function to replace built-in teletransporters with custom teleporters.
This is called when the maps are loaded. Custom teleporters, unlike the built-in
teletransporters, allow to abort the teleportation if some condition is satisfied.
In our case, we abort the teleportation if the hero is jumping, so we avoid the use
of the teleporter if the hero is jumping over it.
---
Use: Load the file from the game manager or other script using:
    require("scripts/meta/custom_teleporter.lua")
--]]

local teleporter_meta = sol.main.get_metatable("teletransporter")

function teleporter_meta:on_created()

  local e = self
  local map = e:get_map()
  -- Get general properties.
  local x, y, layer = e:get_position()
  local name = e:get_name()
  local enabled = e:is_enabled()
  local origin_x, origin_y = e:get_origin()
  local w, h = e:get_size()
  -- Get teletransporter properties.
  local on_activated = e.on_activated
  local sprite = e:get_sprite()
  local animation, animation_set
  if sprite then
    animation_set = sprite:get_animation_set()
    animation = sprite:get_animation()
  end    
  local sound_id = e:get_sound()
  local destination_map = e:get_destination_map()
  local destination_name = e:get_destination_name()
  local transition = e:get_transition()
  -- Replace teletransporter with custom entity.
  e:remove()
  local properties = {name = name, x = x, y = y, layer = layer,
    width = 16, height = 16, direction = 0}
  local t = map:create_custom_entity(properties)
  teleporter_meta:initialize_custom_teleporter(t)
  t:set_enabled(enabled)
  t:set_origin(origin_x, origin_y)
  t:set_size(w, h)
  -- Mimic initial properties.
  t.on_activated = on_activated -- On activated event.
  if animation_set then
    local new_sprite = t:create_sprite(animation_set)
    new_sprite:set_animation(animation)
  end
  t:set_sound(sound_id)
  t:set_destination_map(destination_map)
  t:set_destination_name(destination_name)
  t:set_transition(transition)
  -- Add teleportation collision test with hero. This requires the hero not to be jumping.
  local test = "center"
  if transition == "scrolling" then test = "facing" end
  t:add_collision_test(test, function(teleporter, other)
    if other:get_type() ~= "hero" then return end
    -- Condition to teleport: hero is not jumping.
    if other:is_jumping() then return end
    -- Start teleportation.
    t:teleport()   
  end)

end

-- Initialize methods for custom teleporter. Mimic the built-in Lua API.
function teleporter_meta:initialize_custom_teleporter(custom_teleporter)

  local entity = custom_teleporter
  local map = entity:get_map()
  local game = map:get_game()
  local hero = map:get_hero()
  
  local sound_id, transition_style, destination_map, destination_name
  
  function entity:teleport()
  
    -- Call teleporting event.
    if self.on_activated then self:on_activated() end
    -- If there is bad ground under the hero, abort teleportation. 
    local ground = map:get_ground(self:get_position())
    if ground == "hole" or ground == "lava" or 
      ( (not game:has_ability("swim")) and
        ground == "deep_water"
        or ground == "wall_top_right_water"
        or ground == "wall_top_left_water"
        or ground == "wall_bottom_right_water"
        or ground == "wall_bottom_left_water"
      )
    then
      return
    end
    
    -- Repair destination name obtained from side scrolling teletransporters.
    if destination_name == "_side" then
      local x, y, _ = self:get_position()
      local w, h = self:get_map():get_size()
      local dir = nil
      if x < 0 then dir = 0
      elseif x >= w then dir = 2
      elseif y < 0 then dir = 3
      elseif y >= h then dir = 1
      end
      if dir == nil then 
        -- A scrolling teleporter must be on the border of the map!
        error("Wrong position for custom scrolling teleporter"); return  
      end
      destination_name = "_side" .. dir
    end
  
    -- Teleport.
    hero:teleport(destination_map, destination_name, transition_style) 
  end
  
  function entity:set_sound(new_sound_id) sound_id = new_sound_id end
  function entity:get_sound() return sound_id end
  function entity:set_transition(transition) transition_style = transition end
  function entity:get_transition() return transition_style end
  function entity:set_destination_map(map_id) destination_map = map_id end
  function entity:get_destination_map() return destination_map end
  function entity:set_destination_name(destination) destination_name = destination end
  function entity:get_destination_name() return destination_name end
  return true
end
