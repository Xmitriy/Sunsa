local Draw = require("api.Draw")
local Gui = require("api.Gui")
local I18N = require("api.I18N")
local Ui = require("api.Ui")

local Event = require("api.Event")
local UiList = require("api.gui.UiList")
local UiWindow = require("api.gui.UiWindow")
local InputHandler = require("api.gui.InputHandler")
local IInput = require("api.gui.IInput")
local UiTheme = require("api.gui.UiTheme")
local ICharaMakeMenu = require("api.gui.menu.chara_make.ICharaMakeMenu")

local SelectAliasMenu = class.class("SelectAliasMenu", ICharaMakeMenu)

SelectAliasMenu:delegate("input", IInput)
SelectAliasMenu:delegate("list", "items")

local UiListExt = function(select_alias_menu)
   local E = {}

   function E:get_item_text(item)
      return item.text
   end
   function E:on_choose(item)
      if item.on_choose then
         self.chosen = false
         item.on_choose()
      end
   end
   function E:draw_item_text(text, item, i, x, y, x_offset)
      UiList.draw_item_text(self, text, item, i, x, y, x_offset)

      if item.locked then
         Draw.set_font(12, "bold") -- 12 - en * 2
         Draw.text("Locked!", x + 216, y + 2, {20, 20, 140})
      end
   end

   return E
end

function SelectAliasMenu:init(charamake_data)
   self.charamake_data = charamake_data
   self.width = 400
   self.height = 458

   local items = {
      { text = I18N.get("chara_make.common.reroll"), type = "reroll", on_choose = function() self:reroll(true) end }
   }
   table.append(items, table.of(function(i) return { text = "alias" .. i, type = "alias" } end, 16))

   self.list = UiList:new(items)
   table.merge(self.list, UiListExt(self))

   self.bg_index = 0

   local key_hints = self:make_key_hints()
   self.win = UiWindow:new("chara_make.select_alias.title", true, key_hints)

   self.input = InputHandler:new()
   self.input:forward_to(self.list)
   self.input:bind_keys(self:make_keymap())

   self.caption = "chara_make.select_alias.caption"
   self.intro_sound = "base.ok1"

   self:reroll(false)
end

function SelectAliasMenu:make_keymap()
   return {
      mode2 = function()
         self:lock(self.list.selected)
      end,
      escape = function() self.canceled = true end,
      cancel = function() self.canceled = true end
   }
end

function SelectAliasMenu:make_key_hints()
   return {
      {
         action = "ui.key_hint.action.back",
         keys = { "cancel", "escape" }
      },
      {
         action = "ui.alias.hint.action.lock_alias",
         keys = "mode2"
      }
   }
end

function SelectAliasMenu:lock(i)
   if not self.items[i] then return end
   if self.items[i].type ~= "alias" then return end

   Gui.play_sound("base.ok1")
   if self.items[i].locked then
      self.items[i].locked = nil
   else
      self.items[i].locked = true
   end
end

function SelectAliasMenu:reroll(play_sound)
   for _, v in ipairs(self.items) do
      if v.type == "alias" and not v.locked then
         v.text = Event.trigger("base.generate_title", {}, "")
      end
   end

   if play_sound then
      Gui.play_sound("base.dice")
   end

   self.bg_index = self.bg_index + 1
end

function SelectAliasMenu:relayout(x, y)
   self.x, self.y = Ui.params_centered(self.width, self.height)
   self.y = self.y + 20

   self.t = UiTheme.load(self)

   self.win:relayout(self.x, self.y, self.width, self.height)
   self.list:relayout(self.x + 38, self.y + 66)
end

function SelectAliasMenu:draw()
   self.win:draw()
   self.list:draw()
   Ui.draw_topic("chara_make.select_alias.alias_list", self.x + 28, self.y + 30)

   local bg = self.t.base["g" .. (math.floor(self.bg_index / 4) % 4 + 1)]
   bg:draw(
      self.x + self.width / 2,
      self.y + self.height / 2,
      self.width / 3 * 2,
      self.height - 80,
      {255, 255, 255, 40},
      true)
end

function SelectAliasMenu:get_charamake_result(charamake_data, retval)
   charamake_data.chara.title = retval
   return charamake_data
end

function SelectAliasMenu:update()
   if self.list.chosen then
      return self.list:selected_item().text
   end

   if self.canceled then
      return nil, "canceled"
   end

   self.win:update()
   self.list:update()
end

return SelectAliasMenu
