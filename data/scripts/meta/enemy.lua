-- Initialize enemy behavior specific to this quest.

local enemy_meta = sol.main.get_metatable("enemy")

-- Redefine how to calculate the damage inflicted by the sword.
function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)

  local game = self:get_game()
  local force = game:get_ability("sword")

  if force > 1 then
    -- Swords 2, 3 and 4 actually have the same force, only their color changes.
    force = 2
  end

  local reaction = self:get_attack_consequence_sprite(enemy_sprite, "sword")
  -- Multiply the sword consequence by the force of the hero.
  local life_lost = reaction * force
  local hero_state = hero:get_state()
  if hero_state == "sword spin attack" or hero_state == "running" then
    -- Multiply this by 2 during a spin attack and while running.
    life_lost = life_lost * 2
  end
  self:remove_life(life_lost)
end

-- Helper function to inflict an explicit reaction from a scripted weapon.
-- TODO this should be in the Solarus API one day
function enemy_meta:receive_attack_consequence(attack, reaction)

  if type(reaction) == "number" then
    self:hurt(reaction)
  elseif reaction == "immobilized" then
    self:immobilize()
  elseif reaction == "protected" then
    sol.audio.play_sound("sword_tapping")
  elseif reaction == "custom" then
    if self.on_custom_attack_received ~= nil then
      self:on_custom_attack_received(attack)
    end
  end

end

return true
