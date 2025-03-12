local IInput = require("api.gui.IInput")
local IConfigMenu = require("api.gui.menu.config.IConfigMenu")
local InputHandler = require("api.gui.InputHandler")
local UiTheme = require("api.gui.UiTheme")
local Ui = require("api.Ui")
local Draw = require("api.Draw")
local UiWindow = require("api.gui.UiWindow")
local ConfigMenuList = require("api.gui.menu.config.ConfigMenuList")
local data = require("internal.data")

local ConfigMenu = class.class("ConfigMenu", IConfigMenu)

ConfigMenu:delegate("input", IInput)

function ConfigMenu:init(config_menu_id)
   local config_menu = data["base.config_menu"]:ensure(config_menu_id)

   self.config_menu = config_menu

   self.list = ConfigMenuList:new(config_menu.items)

   local key_hints = self:make_key_hints()
   self.win = UiWindow:new("config.menu." .. config_menu_id .. ".name", true, key_hints)

   self.input = InputHandler:new()
   self.input:forward_to(self.list)
   self.input:bind_keys(self:make_keymap())
end

function ConfigMenu:make_keymap()
   return {
      escape = function() self.canceled = true end,
      cancel = function() self.canceled = true end
   }
end

function ConfigMenu:make_key_hints()
   local hints = self.list:make_key_hints()

   hints[#hints+1] = {
      action = "ui.key_hint.action.close",
      keys = { "cancel", "escape" }
   }

   return hints
end

function ConfigMenu:on_query()
   self.canceled = false
   self.list:refresh_localized_text()
   self.win:set_title("config.menu." .. self.config_menu._id .. ".name")
end

function ConfigMenu:relayout()
   self.width = self.config_menu.menu_width or 440
   self.height = self.config_menu.menu_height or 300

   local item_count = math.min(self.list:len(), self.list.model.page_size)
   if item_count > 8 then
      self.height = self.height + 10 + 30 * (item_count - 9)
   end

   self.x, self.y = Ui.params_centered(self.width, self.height)
   self.y = self.y - 12

   self.t = UiTheme.load(self)

   self.win:relayout(self.x, self.y, self.width, self.height)
   if self.list.page_max > 1 then
      self.win:set_pages(self.list.model)
   end
   self.list:relayout(self.x + 56, self.y + 66)
end

function ConfigMenu:draw()
   -- >>>>>>>> elona122/shade2/help.hsp:936 	redraw 0 ...
   self.win:draw()

   Ui.draw_topic("config.common.menu", self.x + 34, self.y + 36)

   local bg_width = self.width / 5 * 3
   local bg_height = self.height - 80
   Draw.set_color(255, 255, 255, 50)
   self.t.base.g2:draw(
      self.x + self.width / 3,
      self.y + self.height / 2,
      bg_width,
      bg_height,
      nil,
      true)

   self.list:draw()
   -- <<<<<<<< elona122/shade2/help.hsp:979 	cs_list s,wX+56+x ,wY+66+cnt*19-1,19,0 ..
end

function ConfigMenu:update(dt)
   local canceled = self.canceled
   local chosen = self.list.chosen
   local changed = self.list.changed

   self.canceled = false
   self.win:update(dt)
   self.list:update(dt)

   if chosen then
      return self.list:selected_item().menu
   end
   if changed then
      if self.list.page_max > 0 then
         self.win:set_pages(self.list)
      end
   end

   if canceled then
      return nil, "canceled"
   end
end

return ConfigMenu
