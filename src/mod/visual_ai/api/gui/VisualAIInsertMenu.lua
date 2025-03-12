local IInput = require("api.gui.IInput")
local IUiLayer = require("api.gui.IUiLayer")
local InputHandler = require("api.gui.InputHandler")
local UiTheme = require("api.gui.UiTheme")
local VisualAIBlockList = require("mod.visual_ai.api.gui.VisualAIBlockList")
local Ui = require("api.Ui")
local UiWindow = require("api.gui.UiWindow")
local TopicWindow = require("api.gui.TopicWindow")
local Draw = require("api.Draw")
local I18N = require("api.I18N")
local utils = require("mod.visual_ai.internal.utils")
local VisualAIConfigureBlockMenu = require("mod.visual_ai.api.gui.VisualAIConfigureBlockMenu")
local Gui = require("api.Gui")

local VisualAIInsertMenu = class.class("VisualAIInsertMenu", IUiLayer)

VisualAIInsertMenu:delegate("input", IInput)

function VisualAIInsertMenu:init(title, category_idx, item_id)
   self.list = VisualAIBlockList:new()
   self.category_win = TopicWindow:new(1, 1)
   self.category_text = ""

   local key_hints = self:make_key_hints()
   self.win = UiWindow:new(title or "", true, key_hints)

   self.input = InputHandler:new()
   self.input:forward_to(self.list)
   self.input:bind_keys(self:make_keymap())

   self.list:set_category(category_idx or 1)
   if item_id then
      self.list:select_block(item_id)
   end
   self.category_text = I18N.get("visual_ai.gui.menu.category", "visual_ai.gui.category." .. self.list.category)
end

function VisualAIInsertMenu:make_keymap()
   return {
      escape = function() self.canceled = true end,
      cancel = function() self.canceled = true end
   }
end

function VisualAIInsertMenu:make_key_hints()
   local hints = self.list:make_key_hints()

   hints[#hints+1] = {
      action = "ui.key_hint.action.close",
      key_name = "ui.key_hint.key.cancel",
      keys = { "cancel", "escape" }
   }

   return hints
end

function VisualAIInsertMenu:on_query()
   Gui.play_sound("base.pop2")
   self.canceled = false
end

function VisualAIInsertMenu:relayout(x, y, width, height)
   self.width = 400
   self.height = 520
   self.x, self.y = Ui.params_centered(self.width, self.height)
   self.y = self.y + 20
   self.t = UiTheme.load(self)

   self.win:relayout(self.x, self.y, self.width, self.height)
   self.list:relayout(self.x + 15, self.y + 10 + 50, self.width - 20, self.height - 20 - 40 - 30)
   self.category_win:relayout(self.x + 10 + 50, self.y + 32, self.width - 20 - 100, 40)
end

function VisualAIInsertMenu:draw()
   self.win:draw()
   self.list:draw()
   self.category_win:draw()

   Draw.set_font(15)
   Draw.set_color(0, 0, 0)
   Draw.text_shadowed(self.category_text,
                      self.category_win.x + self.category_win.width / 2 - Draw.text_width(self.category_text) / 2,
                      self.category_win.y + self.category_win.height / 2 - Draw.text_height() / 2)
end

local function make_var_defs(block)
   local values = block.vars
   local defs = block.proto.vars

   local result = {}
   for var_name, def in pairs(defs) do
      result[#result+1] = {
         name = var_name,
         def = def,
         value = assert(values[var_name])
      }
   end
   return result
end

function VisualAIInsertMenu:update(dt)
   local changed = self.list.changed
   local canceled = self.canceled

   local chosen = self.list:update(dt)
   self.win:update(dt)
   self.category_win:update(dt)
   self.canceled = false

   if changed then
      self.category_text = I18N.get("visual_ai.gui.menu.category", "visual_ai.gui.category." .. self.list.category)
   end

   if chosen then
      Gui.play_sound("base.ok1")
      local block = utils.make_block(chosen.block_id)
      if next(block.proto.vars) then
         local var_defs = make_var_defs(block)
         local vars, canceled = VisualAIConfigureBlockMenu:new(block.proto, var_defs):query()
         if not canceled then
            block.vars = vars
            return { last_category = chosen.last_category, block = block }, nil
         end
      else
         return { last_category = chosen.last_category, block = block }, nil
      end
   end
   if canceled then
      return { last_category = self.list.category }, "canceled"
   end
end

return VisualAIInsertMenu
