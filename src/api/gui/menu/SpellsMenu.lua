local Gui = require("api.Gui")
local Draw = require("api.Draw")
local I18N = require("api.I18N")
local Skill = require("mod.elona_sys.api.Skill")
local Ui = require("api.Ui")
local data = require("internal.data")
local save = require("internal.global.save")
local Shortcut = require("mod.elona.api.Shortcut")

local IUiLayer = require("api.gui.IUiLayer")
local UiList = require("api.gui.UiList")
local UiWindow = require("api.gui.UiWindow")
local InputHandler = require("api.gui.InputHandler")
local IInput = require("api.gui.IInput")
local UiTheme = require("api.gui.UiTheme")

local SpellsMenu = class.class("SpellsMenu", IUiLayer)

SpellsMenu:delegate("input", IInput)

local UiListExt = function(spells_menu)
   local E = {}

   function E:get_item_text(item)
      return item.name
   end
   function E:draw_select_key(item, i, key_name, x, y)
      UiList.draw_select_key(self, item, i, key_name, x, y)

      spells_menu.t.base.skill_icons:draw_region(item.icon, x - 18, y + 9, nil, nil, {255, 255, 255}, true)
   end

   function E:draw_item_text(text, item, i, x, y, x_offset)
      UiList.draw_item_text(self, text, item, i, x, y, x_offset)

      Draw.text(item.cost_stock, x + 230 - Draw.text_width(item.cost_stock), y)
      Draw.text(item.lv_chance, x + 242, y)
      Draw.text(item.description, x + 322, y)
   end

   return E
end

function SpellsMenu.generate_list(chara)
   local list = {}

   for _, entry in data["base.skill"]:iter():filter(function(e) return e.type == "spell" end) do
      if chara:spell_stock(entry._id) > 0 then
         local name = I18N.localize("base.skill", entry._id, "name")

         -- TODO break this dependency (#30)
         for _, index, sc in Shortcut.iter() do
            if sc.type == "skill" and sc.skill_id == entry._id then
               name = ("%s {%d}"):format(name, index)
               break
            end
         end

         list[#list+1] = {
            _id = entry._id,
            name = name,
            cost_stock = ("%d (%d)"):format(Skill.calc_spell_mp_cost(entry._id, chara), chara:spell_stock(entry._id)),
            lv_chance = ("%d/%d%%"):format(chara:skill_level(entry._id), Skill.calc_spell_success_chance(entry._id, chara)),
            description = utf8.wide_sub(Skill.get_description(entry._id, chara), 0, 40),
            icon = Ui.skill_icon(entry.related_skill)
         }
      end
   end

   return list
end

local last_index

function SpellsMenu:init(chara)
   self.chara = chara

   local list = SpellsMenu.generate_list(self.chara)
   self.pages = UiList:new_paged(list, 16)
   table.merge(self.pages, UiListExt(self))

   local key_hints = self:make_key_hints()
   self.win = UiWindow:new("ui.spell.title", true, key_hints)

   self.input = InputHandler:new()
   self.input:forward_to(self.pages)
   self.input:bind_keys(self:make_keymap())

   if last_index then
      self.pages:select(last_index)
   end
end

function SpellsMenu:on_query()
   Gui.play_sound("base.spell")
end

function SpellsMenu:make_keymap()
   local keymap = {
      escape = function() self.canceled = true end,
      cancel = function() self.canceled = true end
   }

   for i = 0, 39 do
      local action = ("shortcut_%d"):format(i)
      keymap[action] = function()
         self:assign_shortcut(i)
      end
   end

   return keymap
end

function SpellsMenu:make_key_hints()
   local hints = self.pages:make_key_hints()

   hints[#hints+1] = {
      action = "ui.key_hint.action.close",
      keys = { "cancel", "escape" }
   }

   hints[#hints+1] = {
      action = "ui.key_hint.action.shortcut",
      key_name = "ui.key_hint.key.shortcut"
   }

   return hints
end

function SpellsMenu:assign_shortcut(index)
   -- >>>>>>>> oomSEST/src/southtyris.hsp:47007 	if (key == "sc") { ...
   Gui.play_sound("base.ok1")

   local entry = self.pages:selected_item()
   if entry == nil then
      return
   end

   -- TODO Break this dependency (#30)
   local result = Shortcut.assign_skill_shortcut(index, entry._id)

   if result == "assign" then
      Gui.mes("ui.assign_shortcut", index)
   end

   local list = SpellsMenu.generate_list(self.chara) -- update the shortcut text ("{1}")
   self.pages:set_data(list)
   -- <<<<<<<< oomSEST/src/southtyris.hsp:47023 	} ..
end

function SpellsMenu:relayout(x, y)
   self.width = 730
   self.height = 438
   self.x, self.y = Ui.params_centered(self.width, self.height)

   self.t = UiTheme.load(self)

   self.win:relayout(self.x, self.y, self.width, self.height)
   self.pages:relayout(self.x + 58, self.y + 66)
   self.win:set_pages(self.pages)
end

function SpellsMenu:draw()
   self.win:draw()

   Ui.draw_topic("ui.spell.name", self.x + 28, self.y + 36)
   Ui.draw_topic(I18N.get("ui.spell.cost_stock") .. " " .. I18N.get("ui.spell.lv_chance"), self.x + 220, self.y + 36)
   Ui.draw_topic("ui.spell.effect", self.x + 400, self.y + 36)
   self.t.base.inventory_icons:draw_region(13, self.x + 46, self.y - 16)
   self.t.base.deco_spell_a:draw(self.x + self.width - 78, self.y)
   self.t.base.deco_spell_b:draw(self.x + self.width - 180, self.y)

   self.pages:draw()
end

function SpellsMenu:update(dt)
   local canceled = self.canceled
   local changed = self.pages.changed
   local chosen = self.pages.chosen

   self.canceled = false
   self.win:update(dt)
   self.pages:update(dt)

   if canceled then
      last_index = self.pages:selected_index()
      return nil, "canceled"
   end

   if changed then
      self.win:set_pages(self.pages)
   elseif chosen then
      last_index = self.pages:selected_index()
      local entry = self.pages:selected_item()
      if entry == nil then
         return nil, "canceled"
      end
      return { type = "spell", _id = entry._id }
   end
end

function SpellsMenu:on_hotload_layer()
   table.merge(self.pages, UiListExt(self))
end

return SpellsMenu
