local Const = require("api.Const")
local Enum = require("api.Enum")
local Action = require("api.Action")
local Draw = require("api.Draw")
local Gui = require("api.Gui")
local I18N = require("api.I18N")
local Ui = require("api.Ui")
local EquipRules = require("api.chara.EquipRules")
local ICharaEquipStyle = require("api.chara.aspect.ICharaEquipStyle")
local ResistanceLayout = require("api.gui.menu.inv.ResistanceLayout")
local IInventoryMenuDetailView = require("api.gui.menu.inv.IInventoryMenuDetailView")

local IInput = require("api.gui.IInput")
local IPaged = require("api.gui.IPaged")
local IUiLayer = require("api.gui.IUiLayer")
local Input = require("api.Input")
local InputHandler = require("api.gui.InputHandler")
local ItemDescriptionMenu = require("api.gui.menu.ItemDescriptionMenu")
local MapObjectBatch = require("api.draw.MapObjectBatch")
local UiList = require("api.gui.UiList")
local UiTheme = require("api.gui.UiTheme")
local UiWindow = require("api.gui.UiWindow")

local EquipmentMenu = class.class("EquipmentMenu", {IUiLayer, IPaged})

EquipmentMenu:delegate("input", IInput)
EquipmentMenu:delegate("pages", IPaged)

local UiListExt = function(equipment_menu)
   local E = {}

   function E:get_item_text(entry)
      return entry.name
   end
   function E:get_item_color(entry)
      return entry.color
   end
   function E:draw_select_key(entry, i, key_name, x, y)
      if (i - 1) % 2 == 0 then
         Draw.filled_rect(x, y, 558, 18, {12, 14, 16, 16})
      end

      UiList.draw_select_key(self, entry, i, key_name, x, y)

      Draw.set_color(255, 255, 255)

      local icon = entry.body_part.icon or 1
      equipment_menu.t.base.body_part_icons:draw_region(icon, x - 66, y - 2) -- wx + 88 - 66 = wx + 22
      Draw.set_font(12, "bold") -- 12 + sizefix - en * 2

      Draw.text(entry.body_part_text, x - 42, y + 3, {0, 0, 0}) -- wx + 88 - y = wx + 46
   end
   function E:draw_item_text(item_name, entry, i, x, y, x_offset, color)
      local subtext = entry.subtext

      if entry.item then
         equipment_menu.map_object_batch:add(entry.item, x + 12, y + 10, nil, nil, nil, true)

         if equipment_menu.detail_view then
            equipment_menu.detail_view:draw_row(entry, i, x + 20, y)
            item_name = utf8.wide_sub(item_name, 0, 22)
         end
      end

      UiList.draw_item_text(self, item_name, entry, i, x, y, 30, color)

      Draw.text(subtext, x + 530 - Draw.text_width(subtext), y + 2, color)
   end
   function E:draw()
      UiList.draw(self)
      equipment_menu.map_object_batch:draw()
      equipment_menu.map_object_batch:clear()
   end

   return E
end

function EquipmentMenu:init(chara)
   self.width = 690
   self.height = 428
   self.chara = chara

   self.pages = UiList:new_paged({}, 14)
   table.merge(self.pages, UiListExt(self))

   self.detail_view = nil

   local key_hints = self:make_key_hints()
   self.win = UiWindow:new("ui.equip.title", true, key_hints)

   self.input = InputHandler:new()
   self.input:forward_to(self.pages)
   self.input:bind_keys(self:make_keymap())

   self.text_equip_stats = ""

   self.stats = {}
   self.changed_equipment = false

   self.map_object_batch = nil

   self:update_from_chara()
end

function EquipmentMenu:make_keymap()
   return {
      identify = function() self:show_item_description() end,
      -- >>>>>>>> shade2/command.hsp:3179 	if key=key_mode{ ...
      mode = function()
         Gui.play_sound("base.pop1")
         if self.detail_view then
            self:set_detail_view(nil)
         else
            self:set_detail_view(ResistanceLayout:new())
         end
      end,
      -- <<<<<<<< shade2/command.hsp:3182 		} ..
      cancel = function() self.canceled = true end,
      escape = function() self.canceled = true end,
   }
end

function EquipmentMenu:make_key_hints()
   return {
      {
         action = "ui.key_hint.action.known_info" ,
         keys = "identify"
      },
      {
         action = "ui.key_hint.action.mode",
         keys = "mode"
      },
      {
         action = "ui.key_hint.action.close",
         keys = { "cancel", "escape" }
      }
   }
end

function EquipmentMenu:on_hotload_layer()
   table.merge(self.pages, UiListExt(self))
end

function EquipmentMenu:selected_item_object()
   local selected = self.pages:selected_item()
   if selected == nil then
      return nil
   end
   return selected.item
end

function EquipmentMenu:show_item_description()
   local item = self:selected_item_object()
   if item == nil then
      return
   end
   local rest = self.pages:iter_all_pages():extract("item"):to_list()
   local index = ItemDescriptionMenu:new(item, rest):query()

   item = rest[index]
   if item then
      for i, other in self.pages:iter() do
         if item == other.item then
            self.pages:select(i)
            break
         end
      end
   end
end

function EquipmentMenu.build_list(chara)
   local list = {}

   for _, i in chara:iter_all_body_parts() do
      local entry = {}

      entry.body_part = i.body_part
      entry.body_part_text = I18N.localize("base.body_part", i.body_part._id, "name")
      entry.item = nil
      entry.color = {10, 10, 10}
      entry.name = "-    "
      entry.subtext = "-"

      if i.equipped then
         entry.item = i.equipped
         entry.color = i.equipped:calc_ui_color()
         entry.name = i.equipped:build_name()
         entry.subtext = Ui.display_weight(i.equipped:calc("weight"))
      end

      list[#list + 1] = entry
   end

   return list
end

function EquipmentMenu:update_from_chara()
   local list = EquipmentMenu.build_list(self.chara)

   self.pages:set_data(list)
   self.win:set_pages(self.pages)

   local dv = self.chara:calc("dv")
   local pv = self.chara:calc("pv")
   local weight = self.chara:calc("equipment_weight")
   local hit_bonus = self.chara:calc("hit_bonus")
   local damage_bonus = self.chara:calc("damage_bonus")

   self.text_equip_stats = ("%s: %s%s %s:%d %s:%d  DV/PV:%d/%d")
      :format(I18N.get("ui.equip.equip_weight"),
              Ui.display_weight(weight),
              Ui.display_armor_class(weight),
              I18N.get("ui.equip.hit_bonus"),
              hit_bonus,
              I18N.get("ui.equip.damage_bonus"),
              damage_bonus,
              dv,
              pv)

   Gui.refresh_hud()
end

function EquipmentMenu:on_query()
   Gui.play_sound("base.wear");
end

function EquipmentMenu:relayout()
   self.x, self.y, self.width, self.height = Ui.params_centered(self.width, self.height)
   self.t = UiTheme.load(self)

   self.map_object_batch = MapObjectBatch:new()

   self.win:relayout(self.x, self.y, self.width, self.height)
   self.pages:relayout(self.x + 88, self.y + 60, self.width, self.height)
   self.win:set_pages(self.pages)

   if self.detail_view then
      self.detail_view:relayout()
   end
end

function EquipmentMenu:set_detail_view(detail_view)
   if detail_view then
      class.assert_is_an(IInventoryMenuDetailView, detail_view)
   else
      detail_view = nil
   end

   self.detail_view = detail_view

   if self.detail_view then
      self.detail_view:on_page_changed(self)
      self.detail_view:relayout()
   end
end

function EquipmentMenu:draw()
   self.win:draw()

   Ui.draw_topic("ui.equip.category_name", self.x + 28, self.y + 30)
   if self.detail_view == nil then
      Ui.draw_topic("ui.equip.weight", self.x + 524 + 50, self.y + 30)
   end

   Draw.set_color(255, 255, 255)
   self.t.base.inventory_icons:draw_region(10, self.x + 46, self.y - 16)
   self.t.base.deco_wear_a:draw(self.x + self.width - 106, self.y)
   self.t.base.deco_wear_b:draw(self.x, self.y + self.height - 164)

   if self.detail_view then
      self.detail_view:draw_header(self.x + 50, self.y + 40)
   end
   Ui.draw_note(self.text_equip_stats, self.x, self.y, self.width, self.height, 0)

   self.pages:draw()
end

function EquipmentMenu.message_weapon_stats(chara)
   -- >>>>>>>> shade2/command.hsp:3052 *show_weaponStat ..
   local attack_count = 0
   for _, part in chara:iter_equipped_body_parts() do
      if part.body_part._id == "elona.hand" then
         local equipped = assert(part.equipped)
         local weight = equipped:calc("weight")
         if EquipRules.is_melee_weapon(equipped) then
            attack_count = attack_count + 1

            local style = chara:get_aspect(ICharaEquipStyle)
            if style:calc(chara, "is_wielding_two_handed") and weight >= Const.WEAPON_WEIGHT_HEAVY then
               Gui.mes("action.equip.two_handed.fits_well", equipped:build_name())
            end
            if style:calc(chara, "is_dual_wielding") then
               if attack_count == 1 then
                  if weight >= Const.WEAPON_WEIGHT_HEAVY then
                     Gui.mes("action.equip.two_handed.too_heavy", equipped:build_name())
                  end
               else
                  if weight > Const.WEAPON_WEIGHT_LIGHT then
                     Gui.mes("action.equip.two_handed.too_heavy_other_hand", equipped:build_name())
                  end
               end
            end

            -- TODO riding
            if chara:is_player() then
            end
         end
      end
   end
   -- <<<<<<<< shade2/command.hsp:3074 	return ..
end

function EquipmentMenu:on_exit_result()
   if self.changed_equipment then
      Gui.mes("action.equip.you_change")
      return "turn_end"
   end

   return "player_turn_query"
end

function EquipmentMenu:update(dt)
   local canceled = self.canceled
   local chosen = self.pages.chosen
   local changed_page = self.pages.changed_page

   self.canceled = false
   self.win:update(dt)
   self.pages:update(dt)
   if self.detail_view then
      self.detail_view:update(dt)
   end

   if canceled then
      return nil, "canceled"
   end

   if chosen then
      local slot = self.pages.selected
      local entry = self.pages:selected_item()

      if entry.item then
         local success, err = Action.unequip(self.chara, entry.item)
         self.changed_equipment = true
         if success then
            self:update_from_chara()
         else
            if err == "is_cursed" then
               Gui.mes("ui.equip.cannot_be_taken_off", entry.item)
            else
               Gui.mes("ui.equip.cannot_be_taken_off", entry.item)
            end
         end
      else
         local result, query_canceled = Input.query_item(self.chara, "elona.inv_equip", { params = {body_part_id = entry.body_part._id} })
         if not query_canceled then
            local selected_item = result.result:separate()
            assert(Action.equip(self.chara, selected_item, slot))
            -- >>>>>>>> shade2/command.hsp:3743 			snd seEquip ..
            Gui.play_sound("base.equip1")
            Gui.mes_newline()
            Gui.mes("ui.inv.equip.you_equip", selected_item:build_name())
            self.changed_equipment = true
            local curse = selected_item:calc("curse_state")
            if curse == Enum.CurseState.Cursed then
               Gui.mes("ui.inv.equip.cursed", self.chara)
            elseif curse == Enum.CurseState.Doomed then
               Gui.mes("ui.inv.equip.doomed", self.chara)
            elseif curse == Enum.CurseState.Blessed then
               Gui.mes("ui.inv.equip.blessed", self.chara)
            end
            if entry.body_part._id == "elona.hand" then
               EquipmentMenu.message_weapon_stats(self.chara)
            end
            -- <<<<<<<< shade2/command.hsp:3749 			if (cData(body,cc)/extBody)=bodyHand : gosub *s ..

            self:update_from_chara()
         end
      end
   end

   if changed_page then
      self.win:set_pages(self)
   end
end

function EquipmentMenu:release()
   self.map_object_batch:release()
end

return EquipmentMenu
