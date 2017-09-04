-- Statistics screen about completing the game.

local statistics_manager = {}

local language_manager = require("scripts/language_manager")

local title_color = { 242, 241, 229 }
local text_color = { 115, 59, 22 }

local max_hearts = 20

-- List of strings (savegame variable names) or
-- pairs (savegame variable name + minimum value)
local treasure_savegame_variables = {
  -- Inventory items: ifeather, lamp, pegasus shoelaces, lens of truth,
  -- hookshot, boomerang, fire rod, pains au chocolat counter, croissants counter,
  -- cat food, mail counter, perfume counter, banana counter, VIP card, flippers,
  -- Library award.
  { "possession_feather", 2 },
  "possession_lamp",
  { "possession_pegasus_shoes", 2 },
  "possession_lens_of_truth",
  "possession_hookshot",
  "i1103",  -- Boomerang.
  "possession_fire_rod",
  "possession_pains_au_chocolat_counter",
  "possession_croissants_counter",
  "possession_cat_food",
  "possession_mail_counter",
  "possession_perfume_counter",
  "possession_banana_skin_counter",
  "possession_vip_card",
  "possession_flippers",
  "possession_library_award",
  -- Equipment: sword 4, shield 2.
  { "possession_sword", 4 },
  "dungeon_2_1f_shield_chest",
  -- Dungeons: map, compass, big key, boss key, small keys, big chest, other treasures.
  "dungeon_1_map",
  "dungeon_1_compass",
  "dungeon_1_big_key",
  "dungeon_1_small_key_1",
  "dungeon_1_small_key_2",
  "dungeon_1_glove",
  "dungeon_1_rupee_chest_A",
  "dungeon_1_rupee_chest_B",
  "dungeon_1_rupee_chest_C",
  "dungeon_1_rupee_chest_D",
  "dungeon_1_rupee_chest_E",
  "dungeon_1_rupee_chest_F",
  "dungeon_2_1f_map_chest",
  "dungeon_2_1f_sw_key",
  "dungeon_2_1f_ne_key_chest",
  "dungeon_2_1f_ne_key_vase",
  "dungeon_2_1f_compass_chest", -- Actually 2F.
  "dungeon_2_2f_chest_game_key",
  "dungeon_2_2f_vegas_key",
  "dungeon_2_2f_e_key_vase",
  "dungeon_2_2f_pickable_under_piece_6",
  "dungeon_2_2f_pickable_under_piece_11",
  "dungeon_2_3f_s_key_chest",
  "dungeon_2_3f_n_key_chest",
  "dungeon_2_5f_n_key_chest",
  "dungeon_2_5f_nw_enemy_key",
  "dungeon_2_5f_se_key_chest",
  "dungeon_2_5f_se_croissant_chest",
  "dungeon_2_6f_big_key_chest",
  "dungeon_2_7f_nw_key_chest",
  "dungeon_2_8f_c_key_chest",
  "dungeon_2_boss_key_chest",
  -- Other treasure chests.
  "forest_invisible_rupee_chest",
  "forest_50_rupee_chest",
  "swamp_rupee_chest",
  "desert_east_house_rupees_chest",
  "tunnels_50_rupee_chest",
  "stupid_chest_cave_rupees_chest",
}
local max_treasures = #treasure_savegame_variables

function statistics_manager:new(game)

  local statistics = {}
  local tr = sol.language.get_string

  local bosses = {
    game:get_value("dungeon_1_miniboss_clear") or false,
    game:get_value("dungeon_1_finished") or false,
    game:get_value("dungeon_2_miniboss") or false,
    game.prehistoric_tyrannosaurus_happy or false,
  }
  local max_bosses = #bosses

  local menu_font, menu_font_size = language_manager:get_menu_font()

  local title_text = sol.text_surface.create({
    horizontal_alignment = "center",
    font = menu_font,
    font_size = menu_font_size,
    color = title_color,
    text_key = "stats_menu.title",
  })
  title_text:set_xy(160, 54)

  local background_img = sol.surface.create("menus/selection_menu_background.png")
  background_img:set_xy(37, 38)

  local function get_game_time_string()
    return tr("stats_menu.game_time") .. " " .. game:get_time_played_string()
  end

  local function get_death_count_string()
    local death_count = game:get_value("death_count") or 0
    return tr("stats_menu.death_count") .. " " .. death_count
  end

  local function get_pieces_of_heart_string()
    local item = game:get_item("piece_of_heart")
    local num_pieces_of_heart = item:get_total_pieces_of_heart()
    local max_pieces_of_heart = item:get_max_pieces_of_heart()
    return tr("stats_menu.pieces_of_heart") .. " "  ..
        num_pieces_of_heart .. " / " .. max_pieces_of_heart
  end

  local function get_num_hearts()
    return math.floor(game:get_max_life() / 4)
  end

  local function get_hearts_string()

    return tr("stats_menu.hearts") .. " "  ..
        get_num_hearts() .. " / " .. max_hearts
  end

  local function get_num_treasures()

    local num_treasures = 0
    for _, savegame_variable in ipairs(treasure_savegame_variables) do
      if type(savegame_variable) == "string" then
        local value = game:get_value(savegame_variable)
        if value ~= nil then
          if type(value) == "boolean" and value then
            num_treasures = num_treasures + 1
          elseif type(value) == "number" and value > 0 then
            num_treasures = num_treasures + 1
          end
        else
          -- Debug.
          -- print("Missing treasure: ", savegame_variable)
        end
      else  -- Table whose second element is the minimum value.
        local value = game:get_value(savegame_variable[1])
        local minimum = savegame_variable[2]
        if type(value) == "number" and value >= minimum then
          num_treasures = num_treasures + 1
        end
      end
    end
    return num_treasures
  end

  local function get_treasures_string()

    return tr("stats_menu.treasures") .. " "  ..
        get_num_treasures() .. " / " .. max_treasures
  end

  local function get_num_bosses()

    local num_bosses = 0
    for _, boss in ipairs(bosses) do
      if boss then
        num_bosses = num_bosses + 1
      end
    end
    return num_bosses
  end

  local function get_percent_string()

    -- Hearts except the first four ones.
    -- Treasures.
    -- Dungeon minibosses and bosses.
    local max = (max_hearts - 4) + max_treasures + max_bosses
    local current = (get_num_hearts() - 4) + get_num_treasures() + get_num_bosses()
    local percent = math.floor(current / max * 100)
    return tr("stats_menu.percent"):gsub("%$v", percent)
  end

  local function get_quest_version()
    -- Hack because there is no sol.main.get_quest_version() yet.
    -- TODO with Solarus 1.6, use sol.main.get_quest_version() instead.
    local quest_version = sol.video.get_window_title():match("Mercuris Chess ([0-9.]+)")
    return quest_version
  end

  local function get_version_string()

    return tr("stats_menu.solarus_version") .. sol.main.get_solarus_version() ..
        " - " .. tr("stats_menu.quest_version") .. get_quest_version()
  end

  local y = 75
  local diff_y = 18

  local time_played_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_game_time_string(),
  })
  time_played_text:set_xy(45, y)
  y = y + diff_y

  local death_count_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_death_count_string(),
  })
  death_count_text:set_xy(45, y)
  y = y + diff_y

  local pieces_of_heart_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_pieces_of_heart_string(),
  })
  pieces_of_heart_text:set_xy(45, y)
  y = y + diff_y

  local hearts_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_hearts_string(),
  })
  hearts_text:set_xy(45, y)
  y = y + diff_y

  local treasures_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_treasures_string(),
  })
  treasures_text:set_xy(45, y)
  y = y + diff_y

  local percent_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    text = get_percent_string(),
  })
  percent_text:set_xy(45, y)
  y = y + diff_y

  local version_text = sol.text_surface.create({
    font = menu_font,
    font_size = menu_font_size,
    color = text_color,
    horizontal_alignment = "right",
    text = get_version_string(),
  })
  local screen_width, _ = sol.video.get_quest_size()
  version_text:set_xy(screen_width - 45, y)
  y = y + diff_y

  function statistics:on_command_pressed(command)

    local handled = false
    if command == "action" then
      sol.menu.stop(statistics)
      handled = true
    end
    return handled
  end

  function statistics:on_draw(dst_surface)

    background_img:draw(dst_surface)
    title_text:draw(dst_surface)
    time_played_text:draw(dst_surface)
    death_count_text:draw(dst_surface)
    pieces_of_heart_text:draw(dst_surface)
    hearts_text:draw(dst_surface)
    treasures_text:draw(dst_surface)
    percent_text:draw(dst_surface)
    version_text:draw(dst_surface)
  end

  return statistics
end

return statistics_manager
