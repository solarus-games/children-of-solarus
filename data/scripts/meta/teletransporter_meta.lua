-- Add new features to the teletransporters metatable.
local tele_meta = sol.main.get_metatable("teletransporter")

-- Get direction of a scrolling teleporter.
function tele_meta:get_scrolling_direction()
  if self:get_transition() ~= "scrolling" then return nil end
  local x, y, w, h = self:get_bounding_box()
  if h == 16 and w > 16 then -- Vertical direction.
    if y < 0 then return 1 else return 3 end
  elseif w == 16 and h > 16 then -- Horizontal direction.
    if x < 0 then return 2 else return 0 end
  end
  return
end