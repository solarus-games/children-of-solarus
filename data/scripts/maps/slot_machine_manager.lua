local slot_machine_manager = {}

local debug_win = false -- Set to true to win every game for debugging purposes.

function slot_machine_manager:create_slot_machine(map, prefix)

  local game = map:get_game()
  local hero = map:get_entity("hero")

  local slot_left = map:get_entity(prefix .. "_left")
  local slot_middle = map:get_entity(prefix .. "_middle")
  local slot_right = map:get_entity(prefix .. "_right")

  local slots = {
    [slot_left] =   {initial_frame = 3, initial_delay = 70, current_delay = 0, symbol = -1},
    [slot_middle] = {initial_frame = 0, initial_delay = 90, current_delay = 0, symbol = -1},
    [slot_right] =  {initial_frame = 15, initial_delay = 60, current_delay = 0, symbol = -1}
  }  -- The key is also the entity.

  local playing = false
  local nb_finished = 0
  local bet

  local function start_choose_bet_dialog()

    game:start_dialog("slot_machine.choose_bet", function(answer)

      if answer == 1 then
        -- bet 5 rupees
        bet = 5
      else
        -- bet 20 rupees
        bet = 20
      end

      if game:get_money() < bet then
        -- Not enough money.
        sol.audio.play_sound("wrong")
        game:start_dialog("slot_machine.not_enough_money")
      else
        -- Enough money: pay and start the game.
        game:remove_money(bet)
        playing = true
        nb_finished = 0

        -- Start the slot machine animations
        for k, v in pairs(slots) do
          v.symbol = -1
          v.current_delay = v.initial_delay
          v.sprite:set_animation("started")
          v.sprite:set_frame_delay(v.current_delay)
          v.sprite:set_frame(v.initial_frame)
          v.sprite:set_paused(false)
        end
      end
    end)

  end

  local function propose_game()
    -- Dialog with the game rules.
    game:start_dialog("slot_machine.intro", function(answer)

      if answer ~= 1 then
        return
      end

      -- Wants to play the game.
      start_choose_bet_dialog()
    end)
  end

  local function finish_game()

    -- See if the player has won.
    local i = 1
    local symbols = {-1, -1, -1}
    for k, v in pairs(slots) do
      symbols[i] = v.symbol
      i = i + 1
    end

    local function give_reward()
      game:add_money(reward)
    end

    local function give_creeper_reward()

      local x, y, layer = slot_middle:get_position()
      sol.audio.play_sound("explosion")
      map:create_explosion({
        x = x,
        y = y,
        layer = layer,
      })
    end

    if symbols[1] == symbols[2] and symbols[2] == symbols[3] then
      -- Three identical symbols.

      if symbols[1] == 0 then -- 3 green rupees.
        game:start_dialog("slot_machine.reward.green_rupees", give_reward)
        reward = 5 * bet
      elseif symbols[1] == 2 then -- 3 pickaxes.
        game:start_dialog("slot_machine.reward.pickaxes", give_reward)
        reward = 7 * bet
      elseif symbols[1] == 3 then -- 3 Creepers.
        game:start_dialog("slot_machine.reward.creeper", give_creeper_reward)
        reward = 10 * bet
      elseif symbols[1] == 4 then -- 3 red rupees.
        game:start_dialog("slot_machine.reward.red_rupees", give_reward)
        reward = 10 * bet
      elseif symbols[1] == 5 then -- 3 Yoshi.
        game:start_dialog("slot_machine.reward.yoshi", give_reward)
        reward = 20 * bet
      else -- Other symbol.
        game:start_dialog("slot_machine.reward.same_any", give_reward)
        reward = 4 * bet
      end

    else
      game:start_dialog("slot_machine.reward.none", function(answer)
        if answer == 1 then
          start_choose_bet_dialog()
        end
      end)
      reward = 0
    end

    if reward ~= 0 then
      sol.audio.play_sound("secret")
    else
      sol.audio.play_sound("wrong")
    end

    hero:unfreeze()
  end

  local function slot_on_interaction(slot_npc)

    if not playing then
      propose_game()
      return
    end

    local slot = slots[slot_npc]
    local sprite = slot.sprite
    if slot.symbol == -1 then
      -- Stop this reel.
      local current_symbol = math.floor(sprite:get_frame() / 3)
      slot.symbol = (current_symbol + math.random(2)) % 7
      slot.current_delay = slot.current_delay + 100
      sprite:set_frame_delay(slot.current_delay)

      if debug_win then
        -- Win every game.
        for _, v in pairs(slots) do
          v.symbol = slot.symbol
          v.current_delay = slot.current_delay + 100
          v.sprite:set_frame_delay(v.current_delay)
        end
      end

      sol.audio.play_sound("switch")
      hero:freeze()

      sol.timer.start(map, 100, function()

        -- Stop the reels when necessary
        for k, v in pairs(slots) do
          local frame = v.sprite:get_frame()
          if not v.sprite:is_paused() and frame == v.symbol * 3 then
            v.sprite:set_paused(true)
            v.initial_frame = frame
            nb_finished = nb_finished + 1

            if nb_finished < 3 then
              hero:unfreeze()
            else
              playing = false
              sol.timer.start(map, 500, finish_game)
              return false
            end
          end
        end
        return true  -- Repeat the timer.
      end)
    end
  end

  for npc, v in pairs(slots) do
    v.sprite = npc:get_sprite()
    v.sprite:set_frame(v.initial_frame)
    npc.on_interaction = slot_on_interaction
  end

end

return slot_machine_manager
