local Draw = require("api.Draw")
local Env = require("api.Env")
local Gui = require("api.Gui")
local Object = require("api.Object")
local SaveFs = require("api.SaveFs")
local Log = require("api.Log")
local CircularBuffer = require("api.CircularBuffer")
local Queue = require("api.Queue")
local config = require("internal.config")
local Stopwatch = require("api.Stopwatch")
local MemoryProfiler = require("api.MemoryProfiler")

local IUiLayer = require("api.gui.IUiLayer")
local IInput = require("api.gui.IInput")
local InputHandler = require("api.gui.InputHandler")
local LuaReplMode = require("api.gui.menu.LuaReplMode")
local TextHandler = require("api.gui.TextHandler")
local ReplCompletion = require("api.gui.menu.ReplCompletion")
local UiTheme = require("api.gui.UiTheme")

local ReplLayer = class.class("ReplLayer", IUiLayer)

ReplLayer:delegate("input", IInput)

function ReplLayer:init(env, params)
   params = params or {}

   self.history = params.history or {}
   self.history_file = params.history_file or nil
   self.color = params.color or {17, 17, 65, 192}
   self.message = params.message or nil

   self.text = ""

   self.env = env or {}

   self.result = ""
   self.size = 10000
   self.font_size = 15

   self.scrollback = CircularBuffer:new(self.size)
   self.scrollback_index = 0

   self.history_index = 0

   self.output = {}

   self.canvas = nil
   self.redraw = false

   -- Modify the size of the REPL inside the REPL, using
   -- `field.repl.height_percentage = 0.5`
   self.height_percentage = 0.3

   -- quake pulldown
   self.pulldown = true
   self.pulldown_y = 0
   self.pulldown_speed = 8
   self.frames = 0

   -- line editing support
   self.cursor_pos = 0
   self.cursor_x = 0

   -- tab completion
   self.completion = nil

   -- history search
   self.search = nil
   self.can_search = true
   self.max_search_size = 1000

   -- formatting options
   self.show_metatables = false

   self.deferred = Queue:new()

   self.print_varargs = false
   self.measure_perf = false
   self.hide_during_execute = true
   self.is_executing = false

   -- mode of operation. could implement Elona-style console if
   -- desired.
   self.mode = LuaReplMode:new(self.env)

   self.input = InputHandler:new(TextHandler:new())
   self.input:bind_keys(self:make_keymap())
   self.input:halt_input()
end

function ReplLayer:default_z_order()
   return 100000000
end

function ReplLayer:make_keymap()
   return {
      text_entered = function(t)
         self:insert_text(t)
      end,
      raw_backspace = function()
         self:delete_char()
      end,
      text_submitted = function()
         self:submit()
         local res, err = pcall(Gui.update_screen)
         if not res then
            Log.error("[DRAW ERROR] %s", err)
         end
         self.input:halt_input()
      end,
      text_canceled = function()
         if self.search then
            self:_reset_completion_and_search()
            self:set_text("")
            self.history_index = 0
         else
            self.finished = true
         end
      end,
      north = function()
         self:history_next()
      end,
      south = function()
         self:history_prev()
      end,
      west = function()
         self:move_cursor(-1)
      end,
      east = function()
         self:move_cursor(1)
      end,
      repl_page_up = function()
         self:scrollback_up()
      end,
      repl_page_down = function()
         self:scrollback_down()
      end,
      repl_first_char = function()
         self:set_cursor_pos(0)
      end,
      repl_last_char = function()
         self:set_cursor_pos(#self.text)
      end,
      repl_paste = function()
         self:insert_text(Env.clipboard_text())
      end,
      repl_cut = function()
         Env.set_clipboard_text(self.text)
         self:set_text("")
         self:_reset_completion_and_search()
      end,
      repl_copy = function()
         Env.set_clipboard_text(self.text)
      end,
      repl_clear = function()
         self:clear()
      end,
      repl_toggle_fullscreen = function()
         if not self.finished and self.pulldown_y == 0 then
            if self.height_percentage >= 1.0 then
               self.height_percentage = 0.3
            else
               self.height_percentage = 1.0
            end
            self:relayout()
         end
      end,
      repl_complete = function()
         local function complete(cand)
            local text = self.completion.base .. cand.text
            if cand.type == "function" then
               local rest = "("
               local mod_name = string.match(self.completion.base, "^([a-zA-Z_]+)")
               if mod_name then
                  local has_zero_args = false -- TODO
                  if has_zero_args then
                     rest = "()"
                  end
               end
               text = text .. rest
            end
            self:set_text(text)
         end

         if not self.completion then
            local cp = ReplCompletion:new()
            local ok, completion = xpcall(cp.complete, debug.traceback, cp, self.text, self.env)
            if ok then
               self.completion = completion
            end
            if self.completion then
               local complete_single = true
               if #self.completion.candidates == 1 and complete_single then
                  complete(self.completion.candidates[1])
                  self.completion = nil
               else
                  local concat = function(acc, s) return (acc and (acc .. "  ") or "") .. s end
                  self.completion.text = fun.iter(self.completion.candidates):extract("text"):foldl(concat)
                  self.redraw = true
               end
            end
         else
            self.completion.selected =
               (self.completion.selected + 1) % #self.completion.candidates
            local cand = self.completion.candidates[self.completion.selected+1]
            complete(cand)
         end
      end,

      -- BUG: We can't input '~' as text.
      repl = function() end
   }
end

function ReplLayer:_reset_completion_and_search()
   self.completion = nil
   self.search = nil
   self.can_search = true
   self.redraw = true
end

function ReplLayer:on_query()
   self.completion = nil
   if self.scrollback:len() == 0 then
      if self.message then
         self:print(self.message)
      else
         self:print(string.format("OpenNefia REPL\nVersion: %s  LÖVE version: %s  Lua version: %s  OS: %s",
                                  Env.version(), Env.love_version(), Env.lua_version(), Env.os()))
      end
   end
end

function ReplLayer:history_prev()
   if self.can_search and self.search == nil and self.text ~= "" then
      self.search = {
            text = string.escape_for_gsub(self.text),
            status = "failure"
      }
   end

   self.scrollback_index = 0
   if self.search then
      local prev = self.history_index
      self.search.status = "failure"
      for _=1,self.max_search_size do
         self.history_index = math.max(self.history_index - 1, 1)
         local text = self.history[self.history_index]
         if text then
            local match_start, match_end = string.find(text, self.search.text)
            if match_start then
               self.search.status = "success"
               self.search.match_start = match_start
               self.search.match_end = match_end
               self:set_text(text)
               break
            end
            if self.history_index == 1 then
               break
            end
         else
            self.history_index = 0
         end
      end
      if self.search.status ~= "success" then
         self.history_index = prev
      end
      self.redraw = true
   else
      if self.history_index - 1 < 1 then
         self:set_text("")
         self.history_index = 0
      else
         self.history_index = self.history_index - 1
         self:set_text(self.history[self.history_index])
      end
   end

   self.completion = nil
   self.can_search = false
end

function ReplLayer:history_next()
   if self.can_search and self.search == nil and self.text ~= "" then
      self.search = {
            text = string.escape_for_gsub(self.text),
            status = "failure"
      }
   end

   self.scrollback_index = 0
   if self.search then
      local prev = self.history_index
      for _=1,self.max_search_size do
         self.search.status = "failure"
         self.history_index = math.min(self.history_index + 1, #self.history)
         local text = self.history[self.history_index]
         if text then
            local match_start, match_end = string.find(text, self.search.text)
            if match_start then
               self.search.status = "success"
               self.search.match_start = match_start
               self.search.match_end = match_end
               self:set_text(text)
               break
            end
            if self.history_index == #self.history then
               break
            end
         else
            self.history_index = #self.history+1
         end
      end
      if self.search.status ~= "success" then
         self.history_index = prev
      end
      self.redraw = true
   else
      if self.history_index + 1 > #self.history then
         self:set_text("")
         self.history_index = #self.history+1
      else
         self.history_index = self.history_index + 1
         self:set_text(self.history[self.history_index])
      end
   end

   self.completion = nil
   self.can_search = false
end

function ReplLayer:set_text(text)
   self.text = text or ""
   self.redraw = true

   self:set_cursor_pos(#self.text)
end

function ReplLayer:scrollback_up()
   self.scrollback_index = math.clamp(self.scrollback_index + math.floor(self.max_lines / 2),
                                      0,
                                      math.max(self.scrollback:len() - self.max_lines, 0))
   self.redraw = true
end

function ReplLayer:scrollback_down()
   self.scrollback_index = math.clamp(self.scrollback_index - math.floor(self.max_lines / 2),
                                      0,
                                      math.max(self.scrollback:len() - self.max_lines, 0))
   self.redraw = true
end

function ReplLayer:clear()
   self.scrollback = CircularBuffer:new(self.size)
   self.scrollback_index = 0
   self.redraw = true
end

function ReplLayer:move_cursor(codepoints)
   local pos = utf8.find_next_pos(self.text, self.cursor_pos, codepoints)
   if codepoints > 0 and pos == 0 then
      pos = utf8.offset(self.text, codepoints)
   end
   if pos < 1 then
      self.cursor_pos = 0
      self.cursor_x = 0
      return
   end

   self:_reset_completion_and_search()

   self:set_cursor_pos(pos)
end

function ReplLayer:insert_text(t)
   if self.cursor_pos == #self.text then
      self.text = self.text .. t
   elseif self.cursor_pos == 0 then
      self.text = t .. self.text
   else
      local a, b = string.split_at_pos(self.text, self.cursor_pos)
      self.text = a .. t .. b
   end

   self:_reset_completion_and_search()

   self:move_cursor(utf8.len(t))
   self.redraw = true
end

function ReplLayer:delete_char()
   if self.cursor_pos == 0 then
      return
   end

   if self.cursor_pos == #self.text then
      self.text = utf8.pop(self.text)
   elseif self.cursor_pos == 1 then
      self.text = utf8.sub(self.text, 2)
   else
      local a, b = string.split_at_pos(self.text, self.cursor_pos)
      a = utf8.sub(a, 1, utf8.len(a)-1)
      self.text = a .. b
   end

   self:move_cursor(-1)
   self.redraw = true
end

function ReplLayer:set_cursor_pos(byte)
   self.cursor_pos = math.clamp(0, byte, #self.text)

   Draw.set_font(self.font_size)
   local rest = string.sub(self.text, 0, self.cursor_pos)

   -- handle failures on decoding invalid UTF-8.
   local ok, x = pcall(Draw.text_width, rest)
   if not ok then
      Log.error("Display error: %s", x)
      self:set_text("")
   else
      self.cursor_x = x
   end

   self.frames = 0
end

function ReplLayer:relayout(x, y, width, height)
   self.x = 0
   self.y = 0
   self.width = Draw.get_width()
   local win_height = Draw.get_height()
   self.height = math.floor(math.clamp(win_height * self.height_percentage, win_height / 3, win_height - 1))
   Draw.set_font(self.font_size)
   self.max_lines = math.floor((self.height - 5) / Draw.text_height())

   self.t = UiTheme.load(self)
   self.color = self.color or self.t.base.repl_bg_color

   if self.canvas == nil or width ~= self.width or height ~= self.height then
      self.canvas = Draw.create_canvas(self.width, self.height)
      self.redraw = true
   end

   if self.pulldown then
      self.pulldown = false
      self.pulldown_y = self.max_lines
   end
end

function ReplLayer:print(text, color)
   color = color or {255, 255, 255}

   Draw.set_font(self.font_size)
   local success, err, wrapped = xpcall(function() return Draw.wrap_text(text, self.width) end, debug.traceback)
   if not success then
      self.scrollback:push({text="[REPL] error printing result: " .. string.split(err)[1], color=nil})
      Log.error("%s", err)
   else
      for _, line in ipairs(wrapped) do
         self.scrollback:push({text=line, color=color})
      end
   end
   self.redraw = true
end

function ReplLayer:execute(code)
   self:set_text(code)
   self:submit()
end

local function remove_all_metatables(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
end

local function try(f)
   local ok, result = pcall(f)
   return ok and result
end

function ReplLayer.format_repl_result(result, show_metatables)
   local inspect_opts = {max_length=config.base.max_inspect_length}
   if not show_metatables then
      inspect_opts.process = remove_all_metatables
   end
   local result_text
   local stop = false

   if type(result) == "table" then
      -- HACK: Don't print out unnecessary class fields. In the future
      -- `inspect` should be modified to account for this.
      local mt = getmetatable(result)

      if try(function() return result.__enum end) then
         result_text = inspect(result, inspect_opts)
      elseif try(function() return result._type and result._id end) then
         result_text = inspect(Object.make_prototype(result), inspect_opts)
      elseif tostring(result) == "<generator>" then
         -- Wrap in a protected function in case running the generator
         -- returns an error
         local _, rest = xpcall(function()
               local text
               local max = 10
               local list = result:take(max + 1)
               local first = list:nth(1)
               if type(first) == "table" and first._type then
                  list = list:map(Object.make_prototype)
               end
               if list:length() == max + 1 then
                  text = "(iterator): " .. inspect(list:take(10):to_list(), inspect_opts)
                  text = string.strip_suffix(text, " }")
                  text = text .. ", <...> }"
               else
                  text = "(iterator): " .. inspect(list:to_list(), inspect_opts)
               end

               return text
         end, debug.traceback)
         result_text = rest
         stop = true
      else
         result_text = inspect(result, inspect_opts)
      end
   elseif type(result) == "string" then
      result_text = ("\"%s\""):format(result)
   else
      result_text = tostring(result)
   end

   return result_text, stop
end

function ReplLayer.format_results(results, print_varargs, show_metatables)
   local result_text

   if type(results) == "table" then
      if print_varargs then
         -- `results` could have nil values in the middle, so iterate
         -- by index.
         local tbl = {}
         local count = results.n
         if tostring(results[1]) == "<generator>" then
            -- Don't print out the state and index of iterators.
            count = 1
         end
         for i=1, count do
            tbl[i] = ReplLayer.format_repl_result(results[i], show_metatables)
         end
         if #tbl == 0 then
            result_text = "nil"
         else
            result_text = table.concat(tbl, "\t")
         end
      else
         result_text = ReplLayer.format_repl_result(results[1], show_metatables)
      end

      if result_text == nil then
         result_text = tostring(result_text)
      end
   else
      result_text = results
   end

   return result_text
end

function ReplLayer:submit()
   local text = self.text
   self.text = ""
   self.scrollback_index = 0
   self.history_index = 0
   self.cursor_pos = 0
   self.cursor_x = 0
   self:_reset_completion_and_search()

   self:print(self.mode.caret .. text)
   if string.nonempty(text) then
      table.insert(self.history, 1, text)
   end

   self.is_executing = true
   local success, results = self.mode:submit(text, self.measure_perf)
   self.is_executing = false

   local result_text = ReplLayer.format_results(results, true, self.show_metatables)

   local color
   if not success then
      print(result_text)
      color = self.t.base.repl_error_color
   else
      color = self.t.base.repl_result_color
   end

   self.output[#self.output+1] = result_text

   self:print(result_text, color)

   self:save_history()
end

function ReplLayer:save_history()
   if self.history_file then
      SaveFs.write(self.history_file, self.history, "global")
   end
end

function ReplLayer:last_input()
   local line = self.history[2]
   if line then
      return line
   end

   return nil
end

function ReplLayer:last_output()
   local output = self.output[#self.output]
   if output then
      return output
   end

   return nil
end

function ReplLayer:defer_execute(code)
   self.deferred:push(code)
end

function ReplLayer:execute_all_deferred()
   local code = self.deferred:pop()
   local success, results
   while code do
      if type(code) == "function" then
         success, results = xpcall(code, debug.traceback)
      else
         success, results = self.mode:submit(code)
      end
      code = self.deferred:pop()

      if not success then
         error(results[1])
      end
   end
   return success, results
end

function ReplLayer:redraw_window()
   Draw.clear()
   Draw.set_font(self.font_size)

   -- background
   local top = self.height -- - self.pulldown_y * Draw.text_height()
   Draw.filled_rect(self.x, self.y, self.width, top, self.color)

   -- caret
   Draw.set_color(255, 255, 255)
   Draw.text(self.mode.caret, self.x + 5, self.y + top - Draw.text_height() - 5)

   -- text
   local color
   if self.search then
      if self.search.status == "failure" then
         color = self.t.base.repl_error_color
      elseif self.search.status == "success" then
         color = self.t.base.repl_search_color
      end
      local char_width = Draw.text_width(".")
      if self.search.match_start then
         Draw.filled_rect(self.x + 5 + Draw.text_width(self.mode.caret) + char_width * (self.search.match_start - 1),
                          self.y + top - Draw.text_height() - 5,
                          Draw.text_width(self.search.text),
                          Draw.text_height(),
                          self.t.base.repl_match_color)
      end
   end
   Draw.text(self.text, self.x + 5 + Draw.text_width(self.mode.caret), self.y + top - Draw.text_height() - 5, color)

   -- scrollback counter
   if self.scrollback_index > 0 then
      local scrollback_count = string.format("%d/%d",self.scrollback_index + self.max_lines, self.scrollback:len())
      Draw.text(scrollback_count, self.width - Draw.text_width(scrollback_count) - 5, self.y + top - Draw.text_height() - 5)
   end

   -- completion candidates
   local offset = 0
   if self.completion and #self.completion.candidates > 1 then
      Draw.text(self.completion.text, self.x + 5, self.y + top - Draw.text_height() * 2 - 5, self.t.base.repl_completion_color)
      offset = 1
      Draw.set_color(255, 255, 255)
   end

   -- scrollback display
   for i=1,self.max_lines do
      local t = self.scrollback:get(self.scrollback_index + i)
      if t == nil then
         break
      end
      Draw.text(t.text, self.x + 5, self.y + top - Draw.text_height() * (i+1+offset) - 5, t.color)
   end
end

function ReplLayer:draw()
   if self.is_executing and self.hide_during_execute then
      return
   end

   if self.redraw then
      Draw.with_canvas(self.canvas, function() self:redraw_window() end)
      self.redraw = false
   end

   local top = -self.pulldown_y * Draw.text_height()

   Draw.set_color(255, 255, 255)
   Draw.image(self.canvas, self.x, self.y + top)

   Draw.set_font(self.font_size)

   -- blinking cursor
   if math.floor(self.frames * 2) % 2 == 0 then
      local top = self.height - self.pulldown_y * Draw.text_height()
      local x = self.x + 8 + Draw.text_width(self.mode.caret) + self.cursor_x
      local y = self.y + top - Draw.text_height() - 5
      Draw.line(x, y, x, y + Draw.text_height() - 1)
   end
end

function ReplLayer:update(dt)
   self.frames = self.frames + dt

   if self.finished then
      -- delay closing until pullup finishes
      self.pulldown = true
      if self.pulldown_y > self.max_lines then
         self.finished = false
         self.pulldown = true
         return true
      end
   end

   if self.finished then
      self.pulldown_y = math.min(self.pulldown_y + self.pulldown_speed, self.max_lines + 1)
   else
      if self.pulldown_y > 0 then
         self.pulldown_y = math.max(self.pulldown_y - self.pulldown_speed, 0)
      end
   end
end

function ReplLayer.on_hotload(old, new)
   -- Sometimes we'll want to reconstruct the REPL so :init() gets
   -- called again. Set it to nil and the field layer will do so.
   require("game.field").repl = nil
   class.hotload(old, new)
end

return ReplLayer
