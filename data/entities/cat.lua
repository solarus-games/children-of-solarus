local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite, tail

-- Event called when the custom entity is initialized.
function entity:on_created()
  sprite = self:get_sprite()
  if not sprite then
    sprite = self:create_sprite("animals/kitten_orange")
  end
  tail = self:create_sprite("animals/kitten_orange")
  -- Update tail sprite when necessary (animation and direction).
  tail:set_animation(sprite:get_animation() .. "_tail")
  tail:set_direction(sprite:get_direction())
  function sprite:on_animation_changed(anim)
    tail:set_animation(anim .. "_tail")
  end
  function sprite:on_direction_changed(anim, dir)
    tail:set_direction(dir)
  end
  function sprite:on_frame_changed(anim, frame)
    if frame < tail:get_num_frames() then tail:set_frame(frame) end
  end
end
