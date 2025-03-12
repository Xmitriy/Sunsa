local I18N = require("api.I18N")
local Draw = require("api.Draw")
local Gui = require("api.Gui")
local Ui = require("api.Ui")

local UiTheme = require("api.gui.UiTheme")
local IUiLayer = require("api.gui.IUiLayer")
local TopicWindow = require("api.gui.TopicWindow")
local InputHandler = require("api.gui.InputHandler")
local IInput = require("api.gui.IInput")
local TextHandler = require("api.gui.TextHandler")
local config = require("internal.config")

local TextPrompt = class.class("TextPrompt", IUiLayer)

TextPrompt:delegate("input", IInput)

--- val(0): x
--- val(1): y
--- val(2): limit_length
--- val(3): can_cancel
--- val(4)>1: this is actually a NumberPrompt, initial input
--- val(5): maximum number
function TextPrompt:init(length, can_cancel, limit_length, autocenter, y_offset, initial_text, shadow)
   self.length = length or 16
   self.width = math.max(16 * 16 + 60, utf8.wide_len(self.length) * 8) + 10
   self.height = 36
   self.can_cancel = can_cancel
   if can_cancel == nil then self.can_cancel = true end
   self.limit_length = limit_length
   if limit_length == nil then self.limit_length = true end
   self.autocenter = autocenter
   if autocenter == nil then self.autocenter = true end
   self.shadow = shadow
   if shadow == nil then self.shadow = true end
   self.y_offset = y_offset or 0

   self.text = initial_text or ""
   self.display_text = ""
   self.cut_off = false
   self.frames = 0
   self.caret_alpha = 2

   self.win = TopicWindow:new(0, 2)

   self.input = InputHandler:new(TextHandler:new())
   self.input:bind_keys(self:make_keymap())
   self.input:halt_input()

   self:update_display_text()
end

function TextPrompt:make_keymap()
   return {
      text_entered = function(t)
         self.text = self.text .. t
         self:update_display_text()
      end,
      raw_backspace = function()
         self.text = utf8.pop(self.text)
         self:update_display_text()
      end,
      text_submitted = function() self.finished = true end,
      ["\t"] = function() self:cancel() end,
      text_canceled = function() self:cancel() end,
      west = function()
         -- prompt text forward
      end,
      east = function()
         -- prompt text backward
      end,
      repl_first_char = function()
      end,
      repl_last_char = function()
      end,
   }
end

function TextPrompt:get_text()
   return self.text
end

function TextPrompt:focus()
   self.input:focus()
end

function TextPrompt:on_query()
   Gui.play_sound("base.pop2")
end

function TextPrompt:cancel()
   if self.can_cancel then self.canceled = true end
end

function TextPrompt:relayout(x, y)
   if self.autocenter then
      x, y = Ui.params_centered(self.width, self.height + 54) -- or + 84 (= 120)
   end
   self.x = x
   self.y = y
   self.t = UiTheme.load(self)
   self.win:relayout(self.x, self.y, self.width, self.height)
end

function TextPrompt:update_display_text()
   self.cut_off = false
   local len = utf8.wide_len(self.text)

   if not self.limit_length then
      if len > self.length - 2 then
         local dots = "..."
         if I18N.is_fullwidth() then
            dots = "…"
         end
         self.display_text = utf8.wide_sub(self.text, 0, self.length - 2) .. dots
      else
         self.display_text = self.text
      end

      return
   end

   if len > self.length then
      self.text = utf8.wide_sub(self.text, 0, self.length)
      self.cut_off = true
   end

   self.display_text = self.text
end

function TextPrompt:ime_status_quad()
   local stat = "ime_status_english"
   if self.cut_off then
      stat = "ime_status_none"
   end
   return stat
end

function TextPrompt:draw()
   if self.shadow then
      Draw.filled_rect(self.x + 4, self.y + 4, self.width - 1, self.height - 1, {0, 0, 0, 127})
   end

   self.win:draw()
   self.t.base.label_input:draw(self.x + self.width / 2 - 60, self.y - 32)
   local ime_status = self:ime_status_quad()
   self.t.base[ime_status]:draw(self.x + 8, self.y + 4)

   Draw.text(self.display_text,
             self.x + 36,
             self.y + 9, -- self.y + vfix + 9
             {255, 255, 255},
             16) -- 16 - en * 2

   self.t.base.input_caret:draw(
      self.x + Draw.text_width(self.display_text) + 34,
      self.y + 5,
      nil,
      nil,
      {255, 255, 255, self.caret_alpha / 2 + 50})
end

function TextPrompt:update(dt)
   self.frames = self.frames + (dt / (config.base.screen_refresh * (16.66 / 1000))) * 4
   self.caret_alpha = math.sin(self.frames) * 255 * 2 -- TODO

   if self.finished then
      self.finished = false
      return self.text
   end

   if self.canceled then
      return nil, "canceled"
   end
end

return TextPrompt
