-- A Lua console that can be enabled with F12 at any time during the program.

local console = {
  font = "minecraftia_mono",            -- Font of the console (monospaced).
  font_size = 9,                        -- Font size in pixels.
  char_width = 6,                       -- Character width in pixels.
  line_spacing = 3,                     -- Space between two lines in pixels.

  margin = 4,                           -- Margin of the console in pixels.
  padding = 6,                          -- Padding of the console in pixels.

  color = {32, 32, 32},                 -- Background color of the console.
  opacity = 248,                        -- Background opacity of the console.
  selection_color = {64, 128, 192},     -- Color of the selection.
  selection_opacity = 80,               -- Selection opacity.

  cursor_sprite_id = "console/cursor",  -- Cursor sprite.
  icons_sprite_id = "console/icons",    -- Icons sprite, require animations:
                                        -- "return" and "error".

  history_capacity = 50,                -- Maximum size of the history.
  history_filename = "_history",        -- Name of the history file.

  debug_filename = "debug",             -- Name of the debug file.
                                        -- The debug file can return a table
                                        -- that will be accessible in the
                                        -- console environment.
}

-- Returns the first argument and the list of the others.
-- This function is used to get results of the 'pcall' function.
local function get_results(...)

  -- get the number of arguments
  local num_args = select("#", ...)

  -- get success (first argument)
  local success = false
  if num_args > 0 then
    success = select(1, ...)
  end

  -- build the list
  local list = {}
  for i = 2, num_args do
    local arg = select(i, ...)
    if arg ~= nil then
      table.insert(list, arg)
    else
      table.insert(list, "nil")
    end
  end

  return success, list
end

-- Environement index function.
local function environment_index(environment, key)

  if key == "print" then
    return console.print
  elseif key == "clear" then
    return console.clear
  end

  local game = sol.main.game
  if game ~= nil then
    if key == "game" then
      return game
    elseif key == "map" then
      return game:get_map()
    elseif key == "tp" then
      return function(...)
        game:get_hero():teleport(...)
      end
    end

    local entity = game:get_map():get_entity(key)
    if entity ~= nil then
      return entity
    end
  end


  local debug = console.debug_env[key]
  if debug ~= nil then
    return debug
  end

  return _G[key]
end

-- Prints text at the end of the last line.
function console.print(...)

  -- get the number of arguments
  local num_args = select("#", ...)

  -- get the current text of the line
  local text = ""
  if console.last_line <= console.max_lines then
    text = console.text_surfaces[console.last_line]:get_text()
  end

  -- for each argument
  for i = 1, num_args do
    local arg = select(i, ...)

    -- if text is not empty, add a space
    if text ~= "" then
      text = text .. " "
    end

    -- check type of the argument and add to text
    local type_name = sol.main.get_type(arg)
    if type_name == "string" or type_name == "number" then
      text = text .. arg
    elseif type_name == "boolean" then
      text = text .. (arg and "true" or "false")
    else
      text = text .. type_name
    end
  end

  -- print the text at the last line
  console:print_text(console.last_line, text)
end

-- Clears the console.
function console.clear()

  -- clear text surfaces and icons
  for i = 1 , #console.text_surfaces do
    console.text_surfaces[i]:set_text("")
    console.icons[i] = ""
  end

  -- reset position
  console.last_line = 1
  console.current_line = 1
  console.current_command = {}

  -- clear the temp history
  console:reset_temp_history()

  -- reset cursor sprite
  console.cursor_sprite:set_frame(0)
end

-- Initializes the console.
function console:init()

  self.enabled = false

  -- compute dimensions
  local width, height = sol.video.get_quest_size()
  local dmargin = self.margin * 2
  local dpadding = self.padding * 2

  local console_width = width - dmargin
  local console_height = height - dmargin

  local inner_width = console_width - dpadding
  local inner_height = console_height - dpadding

  -- create main surface
  self.main_surface = sol.surface.create(console_width, console_height)
  self.main_surface:fill_color(self.color)
  self.main_surface:set_opacity(self.opacity)

  -- compute constraints
  self.max_chars = math.floor(inner_width / self.char_width)

  self.line_height = self.font_size + self.line_spacing
  self.max_lines = math.floor(inner_height / self.line_height)

  local spacing = inner_height - (self.font_size * self.max_lines)
  self.line_height = self.font_size + math.floor(spacing / self.max_lines)

  -- create text surfaces and icons
  self.text_surfaces = {}
  self.icons = {}
  for i = 1, self.max_lines do
    self.text_surfaces[i] = sol.text_surface.create({
      font = self.font,
      font_size = self.font_size,
      vertical_alignment = "top"
    })
    self.icons[i] = ""
  end

  -- init position
  self.last_line = 1
  self.current_line = 1
  self.current_command = {}

  -- cursor sprite
  self.cursor_sprite = sol.sprite.create(self.cursor_sprite_id)

  -- icons sprite
  self.icons_sprite = sol.sprite.create(self.icons_sprite_id)

  -- create history
  self.history = {}
  self.temp_history = {{}}
  self.history_position = 1
  self.cursor = 0
  self.selection = 0
  self.selection_surface = sol.surface.create(width, height)
  self.selection_surface:set_opacity(self.selection_opacity)

  self.clipboard = {}

  self:load_history()
  self.history_is_saved = true

  -- debug environment
  self.debug_env = {}
  local debug = sol.main.load_file(self.debug_filename)
  -- if cannot be loaded, try with the .lua extension
  if type(debug) ~= "function" then
    debug = sol.main.load_file(self.debug_filename .. ".lua")
  end
  if type(debug) == "function" then
    self.debug_env = debug(self) or {}
  end

  -- environment
  self.environment = {}
  setmetatable(self.environment, {
    __index = environment_index,
    __newindex = _G
  })

  -- build the first line
  self:build_line()
end

-- Builds the current line.
function console:build_line()

  -- get the current line with his prompt
  local line = "> " .. table.concat(self:get_current_line())
  if #self.current_command > 0 then
    line = ">" .. line
  end

  -- print the current line
  self.last_line = self.current_line
  self:print_text(self.current_line, line)

  -- clear all next lines
  for i = self.last_line, self.max_lines do
    self.text_surfaces[i]:set_text("")
  end

  -- rebuild the selection surface
  self:build_selection()
end

-- Builds the selection surface.
function console:build_selection()

  self.selection_surface:clear()

  if self.cursor ~= self.selection then

    local origin = self.margin + self.padding
    local cursor = math.min(self.cursor, self.selection)
    local selection = math.max(self.cursor, self.selection)
    local cur_line, cur_char = self:get_cursor_position(cursor)
    local sel_line, sel_char = self:get_cursor_position(selection)

    if cur_line == sel_line then
      -- print simple selection
      local x = origin + (cur_char * self.char_width)
      local y = origin + ((cur_line - 1) * self.line_height)
      local w = origin + (sel_char * self.char_width) - x
      self.selection_surface:fill_color(
        self.selection_color, x, y, w, self.font_size)
    else
      -- print first selection line
      local x = origin + (cur_char * self.char_width)
      local y = origin + ((cur_line - 1) * self.line_height)
      local w = (self.max_chars * self.char_width) - x + origin
      if w > 0 then
        self.selection_surface:fill_color(
          self.selection_color, x, y, w, self.font_size)
      end
      -- print intermediate selection lines
      x = origin
      w = self.max_chars * self.char_width
      for i = cur_line + 1, sel_line - 1 do
        y = y + self.line_height
        self.selection_surface:fill_color(
          self.selection_color, x, y, w, self.font_size)
      end
      -- print last selection line
      y = y + self.line_height
      w = sel_char * self.char_width
      if w > 0 then
        self.selection_surface:fill_color(
          self.selection_color, x, y, w, self.font_size)
      end
    end
  end
end

-- Returns the current line.
function console:get_current_line()

  return self.temp_history[self.history_position]
end

-- Prints text at specific line.
function console:print_text(line_nb, text)

  -- split in lines
  local lines = {}
  for ln in string.gmatch(text .. "\n", "[^\n]*\n") do
    while #ln > self.max_chars do
      table.insert(lines, string.sub(ln, 1, self.max_chars))
      ln = string.sub(ln, self.max_chars + 1)
    end
    table.insert(lines, ln)
  end

  -- set text of surfaces
  for i, ln in pairs(lines) do

    local index = math.min(line_nb + i - 1, self.max_lines)

    if self:go_to_line() and self.current_line > 1 then
      self.current_line = self.current_line - 1
    end

    self.text_surfaces[index]:set_text(ln)
  end
end

-- Prints error message.
function console:print_error(message)
  -- set error icon at the last line
  self.icons[self.last_line] = "error"
  -- print the message
  message = message:gsub("^.*%]:", "")
  self.print("  " .. message)
end

-- Go to the next line.
function console:go_to_line()

  local shifted = false

  if self.last_line > self.max_lines then

    self.last_line = self.max_lines
    shifted = true

    -- shift text surfaces
    table.insert(self.text_surfaces, table.remove(self.text_surfaces, 1))
    self.text_surfaces[self.last_line]:set_text("")

    -- shift icons
    table.remove(self.icons, 1)
    table.insert(self.icons, "")
  end

  self.last_line = self.last_line + 1
  return shifted
end

-- Appends characters at the cursor position.
function console:append_chars(chars)

  if self.cursor ~= self.selection then
    console:remove_chars()
  end

  local line = self:get_current_line()

  for _, ch in pairs(chars) do
    self.cursor = self.cursor + 1
    table.insert(line, self.cursor, ch)
  end

  self.selection = self.cursor

  -- rebuild current line
  self:build_line()

  -- reset cursor sprite
  self.cursor_sprite:set_frame(0)
end

-- Removes a character at the cursor position or the selection.
function console:remove_chars(after)

  local line = self:get_current_line()

  if self.cursor ~= self.selection then
    local cursor = math.min(self.cursor, self.selection)
    local selection = math.max(self.cursor, self.selection)
    for i = cursor + 1, selection do
      table.remove(line, cursor + 1)
    end
    self.cursor = cursor
    self.selection = cursor
  elseif after then
    table.remove(line, self.cursor + 1)
  else
    table.remove(line, self.cursor)
    self:shift_cursor(-1)
  end

  -- rebuild current line
  self:build_line()

  -- reset cursor position
  self.cursor_sprite:set_frame(0)
end

-- Moves the cursor position.
function console:shift_cursor(shift, select)

  self.cursor =
    math.min(math.max(self.cursor + shift, 0), #self:get_current_line())
  if not select then
    self.selection = self.cursor
  end

  -- rebuild selection surface
  self:build_selection()

  -- reset cursor sprite
  self.cursor_sprite:set_frame(0)
end

-- Returns the cursor line number and character position.
function console:get_cursor_position(cursor)

  local line = self:get_current_line()
  local char_nb = #self.current_command > 0 and 3 or 2
  local line_nb = self.current_line

  for i = 1, cursor do
    if line[i] == "\n" then
      line_nb = line_nb + 1
      char_nb = 0
    elseif char_nb >= self.max_chars then
      line_nb = line_nb + 1
      char_nb = 1
    else
      char_nb = char_nb + 1
    end
  end

  return line_nb, char_nb
end

-- Adds the current line to the current command.
function console:add_line()

  -- if the command is not empty, add a new line
  if self.current_command[1] then
    table.insert(self.current_command, "\n")
  end

  -- add the current line to the command
  for _, ch in pairs(self:get_current_line()) do
    table.insert(self.current_command, ch)
  end

  -- try to execute the command
  self:execute_command()

  -- if at the end, go to next line (shift text surfaces)
  if self.last_line > self.max_lines or self.current_line == self.max_lines then
    self:go_to_line()
  end

  -- set the current line after prints
  self.current_line = math.min(self.last_line, self.max_lines)

  -- rebuild current line
  self:build_line()

  -- reset cursor sprite
  self.cursor_sprite:set_frame(0)
end

-- Executes the current command.
function console:execute_command()

  -- get the code
  local line = table.concat(self.current_command)
  local code, error_msg = loadstring(line)
  local autoprint = false

  -- if error, try auto print
  if code == nil then
    code = loadstring("print(' ', " .. line .. ")")
    autoprint = true

  -- else, try auto return
  else
    local retcode, err = loadstring("return " .. line)
    if not err then
      code = retcode
    end
  end

  -- if valid code
  if code ~= nil then

    -- set return icon at the last line
    if autoprint then
      self.icons[self.last_line] = "return"
    end

    -- add the command to history
    self:add_to_history()

    -- execute the code
    setfenv(code, self.environment)
    local success, results = get_results(pcall(code))

    -- if success
    if not success then
      -- print error
      self:print_error(results[1])

    -- else if has results
    elseif results[1] then
      -- set return icon at the last line
      self.icons[self.last_line] = "return"
      -- print results
      self.print(" ", unpack(results))
    end

  -- else if incomplete
  elseif error_msg:sub(-7) == "'<eof>'" then
    self:reset_temp_history()

  -- else
  else
    -- add the command to history
    self:add_to_history()
    -- print error
    self:print_error(error_msg)
  end
end

-- Adds the current command to the history and reset the temp history.
function console:add_to_history()

  -- add to history
  table.insert(self.history, self.current_command)
  if #self.history > self.history_capacity then
    table.remove(self.history, 1)
  end
  self.history_is_saved = false

  -- clear the current command
  self.current_command = {}

  -- reset temp history
  self:reset_temp_history()
end

-- Resets the temp history.
function console:reset_temp_history()

  -- reset
  self.temp_history = {}
  for _, line in pairs(self.history) do
    local ln = {}
    for _, ch in pairs(line) do
      table.insert(ln, ch)
    end
    table.insert(self.temp_history, ln)
  end

  -- add new empty line and set as current
  table.insert(self.temp_history, {})
  self.history_position = #self.temp_history
  self.cursor = 0
  self.selection = 0
end

-- Moves to the history.
function console:shift_history(shift)

  -- move to the temp history
  self.history_position =
      math.min(math.max(self.history_position + shift, 1), #self.temp_history)
  self.cursor = #self:get_current_line()
  self.selection = self.cursor

  -- rebuild current line
  self:build_line()

  -- reset cursor sprite
  self.cursor_sprite:set_frame(0)
end

-- Loads the history from the write directory.
function console:load_history()

  local history = sol.main.load_file(self.history_filename)

  if type(history) == "function" then
    self.history = history() or {}
    self:reset_temp_history()
  end
end

-- Saves the history in the write directory.
function console:save_history()

  if self.history_is_saved then
    return
  end

  local file = sol.file.open(self.history_filename, "w")

  if file == nil then
    return
  end

  file:write("return {\n")
  for _, command in pairs(self.history) do
    file:write("  {")
    for _, ch in pairs(command) do
      file:write("\"")
      if ch == "\"" then
        file:write("\\\"")
      elseif ch == "\n" then
        file:write("\\n")
      elseif ch == "\\" then
        file:write("\\\\")
      else
        file:write(ch)
      end
      file:write("\",")
    end
    file:write("},\n")
  end
  file:write("}")

  file:close()
  self.history_is_saved = true
end

-- Copy the current selection to the clipboard.
function console:copy_to_clipboard()

  if self.cursor == self.selection then
    return false
  end

  local line = self:get_current_line()
  local cursor = math.min(self.cursor, self.selection)
  local selection = math.max(self.cursor, self.selection)

  self.clipboard = {}
  for i = cursor + 1, selection do
    table.insert(self.clipboard, line[i])
  end

  -- reset cursor position
  self.cursor_sprite:set_frame(0)

  return true
end

-- Paste the clipboard on the current selection.
function console:paste_from_clipboard()

  if #self.clipboard > 0 then
    self:append_chars(self.clipboard)
  end
end

-- Called when the console is started.
function console:on_started()
  self.enabled = true
end

-- Called when the console is stopped.
function console:on_finished()
  self.enabled = false
  self:save_history()
end

-- Called when the user presses a keyboard key while the console is active.
function console:on_key_pressed(key, modifiers)

  if key == "f12" or key == "escape" then
    sol.menu.stop(self)
  elseif key == "backspace" then
    self:remove_chars()
  elseif key == "delete" then
    self:remove_chars(true)
  elseif key == "return" or key == "kp return" then
    if modifiers.control then
      self:append_chars({"\n"})
    else
      self:add_line()
    end
  elseif key == "left" then
    self:shift_cursor(-1, modifiers.shift)
  elseif key == "right" then
    self:shift_cursor(1, modifiers.shift)
  elseif key == "home" then
    self.cursor = 0
    if not modifiers.shift then
      self.selection = 0
    end
    -- rebuild selection surface
    self:build_selection()
  elseif key == "end" then
    self.cursor = #self:get_current_line()
    if not modifiers.shift then
      self.selection = self.cursor
    end
    -- rebuild selection surface
    self:build_selection()
  elseif key == "up" then
    self:shift_history(-1)
  elseif key == "down" then
    self:shift_history(1)
  elseif key == "x" and modifiers.control then
    if self:copy_to_clipboard() then
      self:remove_chars()
    end
  elseif key == "c" and modifiers.control then
    self:copy_to_clipboard()
  elseif key == "v" and modifiers.control then
    self:paste_from_clipboard()
  end

  return true
end

-- Called when the user enters text while the console is active.
function console:on_character_pressed(character)

  local handled = false
  if not character:find("%c") then
    self:append_chars({character})
    handled = true
  end

  return handled
end

-- Called when the console has to be redrawn.
function console:on_draw(dst_surface)

  local origin = self.margin + self.padding

  -- draw main surface
  self.main_surface:draw(dst_surface, self.margin, self.margin)

  -- draw text surfaces
  local x = origin
  local y = x
  for i = 1, #self.text_surfaces do
    self.text_surfaces[i]:draw(dst_surface, x, y)
    if self.icons[i] ~= "" then
      self.icons_sprite:set_animation(self.icons[i])
      self.icons_sprite:draw(dst_surface, origin, y)
    end
    y = y + self.line_height
  end

  -- draw selection
  self.selection_surface:draw(dst_surface)

  -- draw cursor
  local line, char = self:get_cursor_position(self.cursor)
  x = origin + ((char - 1) * self.char_width)
  y = origin + ((line - 1) * self.line_height)

  self.cursor_sprite:draw(dst_surface, x, y)
end

console:init()
return console
