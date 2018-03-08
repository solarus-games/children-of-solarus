-- Adds functions to test dialogs.

-- Usage:
-- require("scripts/debug_dialogs")

require("scripts/menus/dialog_box")
local language_manager = require("scripts/language_manager")
local game_meta = sol.main.get_metatable("game")


--[[ Get dialog ids list, ordered alphabetically. Default variables:
language (string, optional): if nil, the default language is used. 
prefix (string, optional): prefix required for dialog ids.
start_dialog (string, optional): start from this one; by default: first dialog.
end_dialog (string, optional): ends in this one; by default: last dialog.
--]]
function game_meta:start_dialogs_debug(dialog_properties)

  -- Open dialogs file if possible. Initialize properties.
  if self.is_dialogs_debug_started then return end
  self.is_dialogs_debug_started = true
  local prop = dialog_properties or {}
  local lan = prop.language or language_manager:get_default_language()
  local filename = "languages/".. lan .."/text/dialogs.dat"
  if not sol.file.exists(filename) then
    error("The language file <<" .. ">> does not exist.")
    return
  end
  local file = sol.file.open(filename)
  local start_dialog = prop.start_dialog
  local end_dialog = prop.end_dialog
  local prefix = prop.prefix
  local dialog_ids = {}
  print("-----Dialogs debug started-----")
  print("start_dialog id: " .. (start_dialog or ""))
  print("end_dialog id: " .. (end_dialog or ""))
  print("prefix: " .. (prefix or ""))
  print("-------------------------------")

  -- Get list of good string ids.
  for line in file:lines() do
    local _, index_1 = line:find("id = \"")
    if index_1 then
      index_1 = index_1 + 1
      local index_2 = line:find("\"", index_1)
      if index_2 then
        index_2 = index_2 - 1
        local id = line:sub(index_1, index_2)
        -- Add id to the list if conditions are satisfied.
        if (start_dialog == nil or start_dialog <= id)
        and (end_dialog == nil or end_dialog >= id)
        and (prefix == nil or prefix == id:sub(1, #prefix)) then
          dialog_ids[#dialog_ids + 1] = id
          -- print(id) -- Use this to debug the debug script. :p
        end
      end
    end
  end

  -- Start dialogs for ids in the list.
  local function dialog_loop(index)
    -- Stop if no more ids remaining or if debug aborted.
    if not self.is_dialogs_debug_started then return end
    local id = dialog_ids[index]
    if id == nil then
      self:finish_dialogs_debug()
      return
    end
    -- Start dialog. Callback: next dialog.
    print("Current dialog id: " .. id)
    self:start_dialog(id, function()
      dialog_loop(index + 1)
    end)
  end
  dialog_loop(1)
end

function game_meta:finish_dialogs_debug()
  self.is_dialogs_debug_started = nil
  print("-----Dialogs debug finished-----")
  return true
end

return true