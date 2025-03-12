local Gui = require("api.Gui")
local Rand = require("api.Rand")
local Action = require("api.Action")
local Input = require("api.Input")
local ElonaAction = require("mod.elona.api.ElonaAction")
local ItemDescriptionMenu = require("api.gui.menu.ItemDescriptionMenu")
local Map = require("api.Map")
local Calc = require("mod.elona.api.Calc")
local Effect = require("mod.elona.api.Effect")
local ElonaItem = require("mod.elona.api.ElonaItem")
local Enum = require("api.Enum")
local Quest = require("mod.elona_sys.api.Quest")
local Ui = require("api.Ui")
local I18N = require("api.I18N")
local Equipment = require("mod.elona.api.Equipment")
local Skill = require("mod.elona_sys.api.Skill")
local Chara = require("api.Chara")
local Const = require("api.Const")
local World = require("api.World")
local Item = require("api.Item")
local God = require("mod.elona.api.God")
local IItemCargo = require("mod.elona.api.aspect.IItemCargo")
local IItemFood = require("mod.elona.api.aspect.IItemFood")
local IItemAncientBook = require("mod.elona.api.aspect.IItemAncientBook")
local IChargeable = require("mod.elona.api.aspect.IChargeable")

local function fail_in_world_map(ctxt)
   if ctxt.chara:current_map():has_type("world_map") then
      return "player_turn_query", "action.cannot_do_in_global"
   end
end

local function can_take(item)
   if item.own_state == Enum.OwnState.NotOwned or item.own_state == Enum.OwnState.Shop then
      Gui.play_sound("base.fail1")
      if item.own_state == Enum.OwnState.NotOwned then
         Gui.mes("action.get.not_owned")
      elseif item.own_state == Enum.OwnState.Shop then
         Gui.mes("action.get.cannot_carry")
      end
      return false
   end
   return true
end

local inv_examine = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_examine",
   elona_id = 1,

   keybinds = function(ctxt)
      return {
         mode2 = function(wrapper)
            -- >>>>>>>> shade2/command.hsp:4001 			ci=list(0,pageSize*page+cs) ...
            local item = wrapper:selected_item_object()
            if item then
               Gui.play_sound("base.ok1")
               if not item.is_no_drop then
                  item.is_no_drop = true
                  Gui.mes("ui.inv.examine.no_drop.set", item:build_name())
               else
                  item.is_no_drop = false
                  Gui.mes("ui.inv.examine.no_drop.unset", item:build_name())
               end
            end
            -- <<<<<<<< shade2/command.hsp:4002 			if iBit(iNoDrop,ci)=false:iBitMod iNoDrop,ci,tr ..
         end
      }
   end,

   key_hints = {
      {
         action = "ui.inv.window.tag.no_drop",
         keys = "mode2",
      }
   },

   sources = { "chara", "equipment", "ground" },
   shortcuts = true,
   icon = 7,
   window_title = "ui.inventory_command.general",
   query_text = "ui.inv.title.general",

   on_select = function(ctxt, item, amount, rest)
      local list = rest and rest:to_list()
      ItemDescriptionMenu:new(item, list):query()

      return "inventory_continue"
   end
}
data:add(inv_examine)

local inv_drop = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_drop",
   elona_id = 2,

   params = { is_multi_drop = types.optional(types.boolean) },

   keybinds = function(ctxt)
      return {
         mode2 = function(wrapper)
            -- >>>>>>>> shade2/command.hsp:4005 			txt lang("続けてアイテムを置くことができる。","You can continuou ...
            if not ctxt.params.is_multi_drop then
               Gui.mes("ui.inv.drop.multi")
               wrapper:set_inventory_group("elona.multi_drop", "elona.inv_drop", { is_multi_drop = true })
            end
            -- <<<<<<<< shade2/command.hsp:4006 			dropContinue=1:snd seInv:screenUpdate=-1:gosub  ..
         end
      }
   end,

   key_hints = function(ctxt)
      if not ctxt.params.is_multi_drop then
         return {
            {
               action = "ui.inv.window.tag.multi_drop",
               keys = "mode2"
            }
         }
      end

      return {}
   end,

   sources = { "chara" },
   icon = 8,
   window_title = "ui.inventory_command.drop",
   query_text = "ui.inv.title.drop",
   can_select = function(ctxt, item)
      if item:calc("is_no_drop") then
         return false, "marked as no drop"
      end

      local map = ctxt.chara:current_map()
      if not Map.can_drop_items(map) and not item:has_category("elona.furniture") then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.drop.cannot_anymore")
         return false, "Map is full."
      end

      return true
   end,

   query_amount = true,

   on_select = function(ctxt, item, amount)
      Action.drop(ctxt.chara, item, amount, ctxt.params.is_multi_drop)

      if ctxt.params.is_multi_drop then
         return "inventory_continue"
      end

      return "turn_end"
   end,

   on_menu_exit = function(ctxt)
      -- TODO: Ensure this is always called in multi-drop by
      -- restricting the menus that can be switched to when it is
      -- active, or in some other way.
      if ctxt.params.is_multi_drop then
         return "turn_end"
      end

      return "player_turn_query"
   end
}
data:add(inv_drop)

local inv_get = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_get",
   elona_id = 3,

   sources = { "ground" },
   icon = 7,
   window_title = "ui.inventory_command.get",
   query_text = "ui.inv.title.get",
   on_select = function(ctxt, item, amount)
      if not can_take(item) then
         return "turn_end"
      end

      local result = Action.get(ctxt.chara, item, amount)

      if type(result) == "string" then
         -- This is a turn result like "turn_end", used by the harvest quest to
         -- indicate the harvesting action should start instead of staying in
         -- the inventory screen.
         return result
      end

      return "inventory_continue"
   end,

   after_filter = function(ctxt, filtered)
      if #filtered == 0 then
         return "player_turn_query"
      end
   end
}
data:add(inv_get)

local inv_eat = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_eat",
   elona_id = 5,

   sources = { "chara", "equipment", "ground" },
   shortcuts = true,
   icon = 2,
   window_title = "ui.inventory_command.eat",
   query_text = "ui.inv.title.eat",
   filter = function(ctxt, item)
      return item:calc("can_eat")
         or item:calc("material") == "elona.fresh" -- TODO
   end,
   can_select = function(ctxt, item)
      if item:calc("is_no_drop") then
         return false, "marked as no drop"
      end

      return true
   end,
   on_select = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3735 			if cHunger(pc)>EatLimit:if develop=false:txt la ...
      if ctxt.chara.nutrition > Const.EATING_NUTRITION_LIMIT
         and not config.base.development_mode
      then
         Gui.mes("ui.inv.eat.too_bloated")
         return "player_turn_query"
      end

      ctxt:set_menu_visible(false)
      return ElonaAction.eat(ctxt.chara, item)
      -- <<<<<<<< shade2/command.hsp:3736 			goto *act_eat ..
   end
}
data:add(inv_eat)

local inv_equip = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equip",
   elona_id = 6,

   params = { body_part_id = types.data_id("base.body_part") },
   sources = { "chara" },
   icon = nil,
   window_title = "ui.inventory_command.equip",
   query_text = "ui.inv.title.equip",
   filter = function(ctxt, item)
      return item:can_equip_at(ctxt.params.body_part_id)
   end,
   can_select = function(ctxt, item)
      if ctxt.chara:has_trait("elona.perm_weak") and item:calc("weight") >= 1000 then
         Gui.mes("ui.inv.equip.too_heavy")
         return false, "too heavy"
      end

      return true
   end
}
data:add(inv_equip)

local inv_read = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_read",
   elona_id = 7,

   sources = { "chara", "ground" },
   shortcuts = true,
   icon = 3,
   window_title = "ui.inventory_command.read",
   query_text = "ui.inv.title.read",
   filter = function(ctxt, item)
      if ctxt.chara:current_map():has_type("world_map") then
         if not (item:calc("can_read_in_world_map")) then
            return false
         end
      end

      return item:calc("can_read")
   end,
   on_select = function(ctxt, item)
      ctxt:set_menu_visible(false)
      return ElonaAction.read(ctxt.chara, item)
   end
}
data:add(inv_read)

local inv_drink = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_drink",
   elona_id = 8,

   sources = { "chara", "ground" },
   shortcuts = true,
   icon = 0,
   window_title = "ui.inventory_command.drink",
   query_text = "ui.inv.title.drink",
   filter = function(ctxt, item)
      return item:calc("can_drink")
   end,
   on_select = function(ctxt, item)
      ctxt:set_menu_visible(false)
      return ElonaAction.drink(ctxt.chara, item)
   end
}
data:add(inv_drink)

local inv_zap = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_zap",
   elona_id = 9,

   sources = { "chara", "ground" },
   shortcuts = true,
   icon = 1,
   window_title = "ui.inventory_command.zap",
   query_text = "ui.inv.title.zap",
   filter = function(ctxt, item)
      return item:calc("can_zap")
   end,
   on_shortcut = fail_in_world_map,
   on_select = function(ctxt, item)
      ctxt:set_menu_visible(false)
      return ElonaAction.zap(ctxt.chara, item)
   end
}
data:add(inv_zap)

local inv_give = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_give",
   elona_id = 10,

   sources = { "chara" },
   params = { is_giving_to_ally = types.optional(types.boolean) },
   icon = 17,
   show_money = false,
   query_amount = false,
   default_amount = 1,
   window_title = "ui.inventory_command.give",
   query_text = "ui.inv.title.give",
}

function inv_give.on_select(ctxt, item, amount)
   -- >>>>>>>> shade2/command.hsp:3756 			ifnodrop ci:goto *com_inventory_loop ...
   if item:calc("is_no_drop") then
      Gui.mes("ui.inv.common.set_as_no_drop")
      Gui.play_sound("base.fail1")
      return "inventory_continue"
   end

   local chara = ctxt.chara
   local target = ctxt.target

   if target:has_effect("elona.sleep") then
      Gui.mes("ui.inv.give.is_sleeping", target)
      Gui.play_sound("base.fail1")
      return "inventory_continue"
   end
   if target:is_inventory_full() then
      Gui.mes("ui.inv.give.inventory_is_full", target)
      Gui.play_sound("base.fail1")
      return "inventory_continue"
   end

   if item._id == "elona.gift" then
      Gui.mes("ui.inv.give.present.text", target, item:build_name(amount))
      item:remove(1)
      Gui.mes("ui.inv.give.present.dialog", target)

      local gift_value = item.params.gift_value
      Skill.modify_impression(target, gift_value)
      target:set_emotion_icon("elona.heart", 3)

      Gui.update_screen()

      return "player_turn_query"
   end

   local will_carry, complaint = Calc.will_chara_take_item(target, item, amount)
   if not will_carry then
      Gui.play_sound("base.fail1")
      complaint = complaint or "ui.inv.give.refuses"
      Gui.mes(complaint, target, item:build_name(amount))
      return "inventory_continue"
   end

   -- TODO move
   -- >>>>>>>> shade2/command.hsp:3813 					if cBit(cPregnant,tc):if (iId(ci)=262)or(iId( ...
   if target:calc("is_pregnant") and item:has_tag("elona.is_acid") then
      Gui.mes("ui.inv.give.abortion")
   end
   -- <<<<<<<< shade2/command.hsp:3813 					if cBit(cPregnant,tc):if (iId(ci)=262)or(iId( ..

   Gui.play_sound("base.equip1")

   Gui.mes("ui.inv.give.you_hand", item:build_name(amount), target)

   local result = item:emit("elona.on_item_given", {chara=chara, target=target, amount=amount}, nil)
   if result then
      return result
   end

   local sep = item:separate(1)
   sep:remove_ownership()
   ElonaItem.ensure_free_item_slot(target)
   assert(target:take_item(sep))
   sep:stack(true)

   Effect.try_to_set_ai_item(target, sep)
   Equipment.equip_all_optimally(target)
   target:refresh()
   target:refresh_weight()

   if ctxt.params.is_giving_to_ally then
      return "inventory_continue"
   end

   Gui.update_screen()
   return "turn_end"
   -- <<<<<<<< shade2/command.hsp:3842 			goto *com_inventory_loop ...
end

data:add(inv_give)

local inv_buy = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_buy",
   elona_id = 11,

   sources = { "shop" },
   shortcuts = false,
   icon = nil,
   query_amount = true,
   show_money = true,
   window_title = "ui.inventory_command.buy",
   query_text = "ui.inv.title.buy",
   window_detail_header = "ui.inv.buy.window.price",

   get_item_name = function(name, item)
      return name .. " " .. Ui.display_weight(item:calc("weight"))
   end,
   get_item_detail_text = function(name, item)
      return tostring(Calc.calc_item_value(item, "buy")) .. " gp"
   end,

   can_select = function(ctxt, item)
      if item:calc("is_no_drop") then
         return false, "marked as no drop"
      end

      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,
   on_select = function(ctxt, item, amount)
      local cost = Calc.calc_item_value(item, "buy") * amount

      Gui.mes("ui.inv.buy.prompt", item:build_name(amount), cost)
      if not Input.yes_no() then
         return "inventory_continue"
      end

      if cost > ctxt.chara.gold then
         Gui.mes("ui.inv.buy.not_enough_money")
         return "inventory_continue"
      end

      local separated = Action.get(ctxt.chara, item, amount)
      if not separated then
         Gui.mes("ui.inv.buy.common.inventory_is_full")
         return "inventory_continue"
      end

      Gui.mes("action.pick_up.you_buy", item:build_name(amount))
      Gui.play_sound("base.paygold1", ctxt.chara.x, ctxt.chara.y)
      ctxt.chara.gold = math.floor(ctxt.chara.gold - cost)
      ctxt.target.gold = math.floor(ctxt.target.gold + cost)

      local food = item:get_aspect(IItemFood)
      if food then
         local spoilage_hours = food:calc(item, "spoilage_hours")
         if spoilage_hours then
            food.spoilage_date = World.date_hours() + spoilage_hours
            if food:is_cooked(item) then
               food.spoilage_date = food.spoilage_date + 72
            end
         end
      end

      return "inventory_continue"
   end
}
data:add(inv_buy)

local inv_sell = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_sell",
   elona_id = 12,

   sources = { "chara" },
   shortcuts = false,
   icon = nil,
   query_amount = true,
   show_money = true,
   window_title = "ui.inventory_command.sell",
   query_text = "ui.inv.title.sell",
   window_detail_header = "ui.inv.buy.window.price",

   get_item_name = function(name, item)
      return name .. " " .. Ui.display_weight(item:calc("weight"))
   end,
   get_item_detail_text = function(name, item)
      return tostring(Calc.calc_item_value(item, "sell")) .. " gp"
   end,

   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3368 		if shopTrade{ ...
      if item:get_aspect(IItemCargo) then
         return false
      end

      if item:calc("value") <= 1 then
         return false
      end

      if item:calc("is_precious") then
         return false
      end

      local food = item:get_aspect(IItemFood)
      if food and food:is_rotten(item) then
         return false
      end

      if item:calc("quality") == Enum.Quality.Unique then
         return false
      end

      return true
      -- <<<<<<<< shade2/command.hsp:3377 		if iQuality(cnt)=fixUnique	:continue ..
   end,

   can_select = function(ctxt, item)
      if item:calc("is_no_drop") then
         return false, "marked as no drop"
      end

      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,
   on_select = function(ctxt, item, amount)
      local cost = math.floor((Calc.calc_item_value(item, "sell") * amount))

      Gui.mes("ui.inv.sell.prompt", item:build_name(amount), cost)
      if not Input.yes_no() then
         return "inventory_continue"
      end

      if cost > ctxt.target.gold then
         Gui.mes("ui.inv.sell.not_enough_money", ctxt.target)
         return "inventory_continue"
      end

      local separated = item:separate(amount)
      if not ctxt.target:take_item(separated) then
         Gui.mes("action.pick_up.shopkeepers_inventory_is_full")
         return "inventory_continue"
      end

      if not item.is_stolen then
         Gui.mes("action.pick_up.you_sell", item:build_name(amount))
      else
         item.is_stolen = false
         Gui.mes("action.pick_up.you_sell_stolen", item:build_name(amount))
         if save.elona.guild_thief_stolen_goods_quota > 0 then
            save.elona.guild_thief_stolen_goods_quota = math.max(save.elona.guild_thief_stolen_goods_quota - cost, 0)
            Gui.mes("action.pick_up.thieves_guild_quota", save.elona.guild_thief_stolen_goods_quota )
         end
      end

      Gui.play_sound("base.getgold1", ctxt.chara.x, ctxt.chara.y)
      ctxt.target.gold = ctxt.target.gold - cost
      ctxt.chara.gold = ctxt.chara.gold + cost

      separated.own_state = Enum.OwnState.None
      separated.identify_state = Enum.IdentifyState.Full

      return "inventory_continue"
   end
}
data:add(inv_sell)

local inv_use = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_use",
   elona_id = 14,

   sources = { "chara", "equipment", "ground" },
   shortcuts = true,
   icon = 5,
   allow_special_owned = true,
   window_title = "ui.inventory_command.use",
   query_text = "ui.inv.title.use",
   filter = function(ctxt, item)
      return item:calc("can_use")
   end,
   on_select = function(ctxt, item, amount, rest)
      ctxt:set_menu_visible(false)
      return ElonaAction.use(ctxt.chara, item)
   end
}
data:add(inv_use)

local inv_open = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_open",
   elona_id = 15,

   sources = { "chara", "ground" },
   shortcuts = true,
   icon = 4,
   window_title = "ui.inventory_command.open",
   query_text = "ui.inv.title.open",
   filter = function(ctxt, item)
      return item:calc("can_open")
   end,
   on_shortcut = fail_in_world_map,
   on_select = function(ctxt, item, amount, rest)
      ctxt:set_menu_visible(false)
      return ElonaAction.open(ctxt.chara, item)
   end
}
data:add(inv_open)

local inv_cook = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_cook",
   elona_id = 16,

   sources = { "chara" },
   icon = nil,
   window_title = "ui.inventory_command.cook",
   query_text = "ui.inv.title.cook",
   filter = function(ctxt, item)
      local food = item:get_aspect(IItemFood)
      if not food then
         return false
      end

      if food:is_cooked(item) then
         return false
      end

      return true
   end,
}
data:add(inv_cook)

local inv_dip_source = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_dip_source",
   elona_id = 17,

   sources = { "chara", "ground" },
   icon = 6,
   window_title = "ui.inventory_command.dip_source",
   query_text = "ui.inv.title.dip_source",
   on_shortcut = fail_in_world_map,
   filter = function(ctxt, item)
      return item:calc("can_dip_into")
   end,
   on_select = function(ctxt, item, amount, rest)
      local result, canceled = Input.query_inventory(ctxt.chara, "elona.inv_dip", {chara=ctxt.chara, params={dip_item=item}})
      if result and not canceled then
         return "player_turn_query"
      end
      return "inventory_cancel"
   end
}
data:add(inv_dip_source)

local inv_dip = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_dip",
   elona_id = 18,

   sources = { "chara", "ground", "equipment" },
   params = { dip_item = types.map_object("base.item") },
   icon = nil,
   query_amount = false,
   window_title = "ui.inventory_command.dip",
   query_text = function(ctxt)
      -- >>>>>>>> shade2/command.hsp:3473 		if invCtrl=18:valN=itemName(ciDip,1):else:if inv ...
      return I18N.get("ui.inv.title.dip", ctxt.params.dip_item:build_name(1))
      -- <<<<<<<< shade2/command.hsp:3473 		if invCtrl=18:valN=itemName(ciDip,1):else:if inv ..
   end,
   filter = function(ctxt, item)
      local can_dip = true
      can_dip = ctxt.params.dip_item:emit("elona_sys.calc_item_can_dip_into", {item=item}, can_dip)
      return can_dip
   end,
   on_select = function(ctxt, item, amount, rest)
      ctxt:set_menu_visible(false)
      return ElonaAction.dip(ctxt.chara, ctxt.params.dip_item, item)
   end
}
data:add(inv_dip)

local inv_trade = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_trade",
   elona_id = 20,

   sources = { "target", "target_equipment" },
   window_title = "ui.inventory_command.trade",
   query_text = "ui.inv.title.trade",
   filter = function(ctxt, item)
      return item._id ~= "elona.gold_piece" and item._id ~= "elona.platinum_coin"
   end,
   on_select = function(ctxt, item, amount, rest)
      local result, canceled = Input.query_inventory(ctxt.chara, "elona.inv_present", {target=ctxt.target, params={trade_item=item}})
      if result and not canceled then
         return "player_turn_query"
      end
      return "inventory_cancel"
   end
}
data:add(inv_trade)

local inv_present = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_present",
   elona_id = 20,

   sources = { "chara" },
   params = { trade_item = types.map_object("base.item") },
   window_title = "ui.inventory_command.present",

   query_text = function(ctxt)
      return I18N.get("ui.inv.title.present", ctxt.params.trade_item:build_name())
   end,
   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3390 	if invCtrl=21{ ..
      local trade_item = ctxt.params.trade_item
      local trade_value = Calc.calc_item_value(trade_item) * trade_item.amount
      local offer_value = Calc.calc_item_value(item) * item.amount
      return offer_value >= trade_value / 2 * 3
         and not item:calc("is_stolen")
      -- <<<<<<<< shade2/command.hsp:3393 		} ..
   end,
   after_filter = function(ctxt, filtered)
      if #filtered == 0 then
         Gui.mes("ui.inv.trade.too_low_value", ctxt.params.trade_item:build_name())
         return "inventory_cancel"
      end
   end,
   on_select = function(ctxt, item, amount, rest)
      -- >>>>>>>> shade2/command.hsp:3872 		if invCtrl=21{ ...
      if item:calc("is_no_drop") then
         return "inventory_continue"
      end

      local trade_item = ctxt.params.trade_item
      Gui.play_sound("base.equip1")
      item:remove_activity()
      trade_item:remove_activity()
      trade_item.always_drop = false
      Gui.mes("ui.inv.trade.you_receive", trade_item:build_name(), item:build_name())
      if trade_item:is_equipped() then
         assert(ctxt.target:unequip_item(trade_item))
      end

      trade_item:remove_ownership()
      item:remove_ownership()
      assert(ctxt.chara:take_item(trade_item))
      assert(ctxt.target:take_item(item))

      ElonaItem.convert_artifact(trade_item)
      Equipment.equip_all_optimally(ctxt.target)
      if not ctxt.target:is_in_player_party() then
         Equipment.generate_and_equip(ctxt.target)
      end
      ElonaItem.ensure_free_item_slot(ctxt.target)
      ctxt.target:refresh()
      ctxt.target:refresh_weight()
      ctxt.chara:refresh_weight()

      return "player_turn_query"
      -- <<<<<<<< shade2/command.hsp:3892 			} ..
   end
}
data:add(inv_present)

local inv_throw = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_throw",
   elona_id = 26,

   sources = { "chara", "ground" },
   icon = 18,
   shortcuts = true,
   on_shortcut = fail_in_world_map,
   window_title = "ui.inventory_command.throw",
   query_text = "ui.inv.title.throw",
   filter = function(ctxt, item)
      return item:calc("can_throw")
   end,
   on_select = function(ctxt, item, amount, rest)
      -- >>>>>>>> shade2/command.hsp:3957 		if invCtrl=26{	 ...
      ctxt:set_menu_visible(false)
      local x, y, can_see = Input.query_position()
      if not can_see then
         Gui.mes("action.which_direction.cannot_see_location")
         return "player_turn_query"
      end
      if not Map.is_floor(x, y, ctxt.chara:current_map()) then
         Gui.mes("ui.inv.throw.location_is_blocked")
         return "player_turn_query"
      end
      return ElonaAction.throw(ctxt.chara, item, x, y)
      -- <<<<<<<< shade2/command.hsp:3966 			} ..
   end
}
data:add(inv_throw)

local inv_steal = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_steal",
   elona_id = 27,

   sources = { "target_optional", "ground" },
   icon = 7,
   show_money = true,
   window_title = "ui.inventory_command.steal",
   query_text = "ui.inv.title.steal",
   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3429 	if invCtrl=27	:if cnt2=0:if iProperty(cnt)!propNp ...
      return item.own_state == Enum.OwnState.NotOwned
      -- <<<<<<<< shade2/command.hsp:3429 	if invCtrl=27	:if cnt2=0:if iProperty(cnt)!propNp ..
   end,
   after_filter = function(ctxt, filtered)
      -- >>>>>>>> shade2/command.hsp:3456 		if invCtrl=27{ ...
      if #filtered == 0 then
         if Chara.is_alive(ctxt.target) and not ctxt.target:is_player() then
            Gui.mes("ui.inv.steal.has_nothing", ctxt.target)
         else
            Gui.mes("ui.inv.steal.there_is_nothing")
         end
         return "player_turn_query"
      end
      if Chara.is_alive(ctxt.target) and ctxt.target:is_ally() then
         Gui.mes("ui.inv.steal.do_not_rob_ally")
         return "player_turn_query"
      end
      -- <<<<<<<< shade2/command.hsp:3459 		} ..
   end,
   on_select = function(ctxt, item, amount)
      -- >>>>>>>> shade2/command.hsp:3967 		if invCtrl=27:gosub *act_pickpocket:invSubRoutin ...
      ctxt.chara:start_activity("elona.pickpocket", {item=item})
      return "turn_end"
      -- <<<<<<<< shade2/command.hsp:3967 		if invCtrl=27:gosub *act_pickpocket:invSubRoutin ..
   end
}
data:add(inv_steal)

local inv_take_container = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_take_container",
   elona_id = 22,
   elona_sub_id = 0,

   sources = { "container" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.take",
   query_text = "ui.inv.title.take",

   can_select = function(ctxt, item)
      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,

   on_menu_exit = function(ctxt)
      -- >>>>>>>> shade2/command.hsp:4018 		if invCtrl=22:if invCtrl(1)=0:if listMax>0{ ...
      local item_count = ctxt.container:iter():length()
      if item_count > 0 and ctxt.params.query_leftover then
         Gui.mes("ui.inv.take.really_leave")
         if not Input.yes_no() then
            return "inventory_continue"
         end
      end
      -- <<<<<<<< shade2/command.hsp:4022 			} ..

      return "player_turn_query"
   end,

   on_select = function(ctxt, item, amount)
      local result = Action.take_from_container(ctxt.chara, item, amount)

      return "inventory_continue"
   end
}
data:add(inv_take_container)

local inv_take_food_container = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_take_food_container",
   elona_id = 22,
   elona_sub_id = 3,

   sources = { "container" },
   params = { container_item = types.map_object("base.item") },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.take",
   query_text = "ui.inv.title.take",

   can_select = function(ctxt, item)
      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,

   on_select = function(ctxt, item, amount)
      local result = Action.take_from_container(ctxt.chara, item, amount, ctxt.params.container_item)

      return "inventory_continue"
   end
}
data:add(inv_take_food_container)

local inv_take_strange_scientist = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_take_strange_scientist",
   elona_id = 22,
   elona_sub_id = 4,

   sources = { "container" },
   icon = 17,
   show_money = false,
   query_amount = true,
   window_title = "ui.inventory_command.take",
   query_text = "ui.inv.title.take",

   on_select = function(ctxt, item, amount)
      local result = Action.take_from_container(ctxt.chara, item, amount)

      if result then
         save.elona.strange_scientist_gifts_given = save.elona.strange_scientist_gifts_given + 1
         return "turn_end"
      end

      return "inventory_continue"
   end
}
data:add(inv_take_strange_scientist)

local inv_take_four_dimensional_pocket = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_take_four_dimensional_pocket",
   elona_id = 22,
   elona_sub_id = 5,

   sources = { "container" },
   icon = 17,
   show_money = false,
   query_amount = true,
   window_title = "ui.inventory_command.take",
   query_text = "ui.inv.title.take",

   can_select = function(ctxt, item)
      local success = Effect.do_stamina_check(ctxt.chara, 10)
      if not success then
         Gui.mes("magic.common.too_exhausted")
         return "turn_end"
      end

      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,

   on_select = function(ctxt, item, amount)
      local result = Action.take_from_container(ctxt.chara, item, amount)

      return "inventory_continue"
   end
}
data:add(inv_take_four_dimensional_pocket)

local inv_put_food_container = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_put_food_container",
   elona_id = 24,
   elona_sub_id = 3,

   sources = { "chara" },
   params = { container_item = types.map_object("base.item") },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.put",
   query_text = "ui.inv.title.put",

   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3416 			if iProperty(cnt)=propQuest:continue ...
      return item.own_state ~= Enum.OwnState.Quest
      -- <<<<<<<< shade2/command.hsp:3416 			if iProperty(cnt)=propQuest:continue ..
      -- >>>>>>>> shade2/command.hsp:3421 		if invCtrl(1)=3: if refType!fltFood:continue ...
         and item:has_category("elona.food")
      -- <<<<<<<< shade2/command.hsp:3421 		if invCtrl(1)=3: if refType!fltFood:continue ..
         and not item:is_item_container()
   end,

   on_select = function(ctxt, item, amount)
      if not ctxt.container:can_take_object(item) then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.container.full")
         return "inventory_continue"
      end

      local max_weight = ctxt.container:get_max_item_weight()
      if max_weight and item:calc("weight") >= max_weight then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.container.too_heavy", max_weight)
         return "inventory_continue"
      end

      local result = Action.put_in_container(ctxt.container, item, amount, ctxt.params.container_item)

      return "inventory_continue"
   end
}
data:add(inv_put_food_container)

local inv_harvest_delivery_chest = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_harvest_delivery_chest",
   elona_id = 24,
   elona_sub_id = 0,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.put",
   query_text = "ui.inv.title.put",

   filter = function(ctxt, item)
      return not item:has_category("elona.container")
      -- >>>>>>>> shade2/command.hsp:3413 				if iProperty(cnt)!propQuest:continue ..
         and item.own_state == Enum.OwnState.Quest
         and item.params.harvest_weight_class
      -- <<<<<<<< shade2/command.hsp:3413 				if iProperty(cnt)!propQuest:continue ..
   end,

   on_select = function(ctxt, item, amount)
      -- >>>>>>>> shade2/command.hsp:3898 			if invCtrl(1)=0{ ...
      Gui.play_sound("base.inv")
      local quest = assert(Quest.get_immediate_quest())
      assert(quest._id == "elona.harvest", quest._id)
      quest.params.current_weight = quest.params.current_weight + item:calc("weight") * item.amount
      Gui.mes_c("ui.inv.put.harvest", "Green",
                item:build_name(amount),
                Ui.display_weight(item:calc("weight") * item.amount),
                Ui.display_weight(quest.params.current_weight),
                Ui.display_weight(quest.params.required_weight))

      item.amount = 0
      item:remove_ownership()
      ctxt.chara:refresh_weight()

      return "inventory_continue"
      -- <<<<<<<< shade2/command.hsp:3911 				} ...      return "inventory_continue"
   end
}
data:add(inv_harvest_delivery_chest)

local inv_mages_guild_delivery_chest = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_mages_guild_delivery_chest",
   elona_id = 24,
   elona_sub_id = 0,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.put",
   query_text = "ui.inv.title.put",

   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3410 			if gArea=areaLumiest{ ...
      local aspect = item:get_aspect(IItemAncientBook)
      return aspect and aspect:calc(item, "is_decoded")
      -- <<<<<<<< shade2/command.hsp:3412 				}else{ ..
   end,

   after_filter = function(ctxt, filtered)
      -- >>>>>>>> shade2/command.hsp:3462 	if invCtrl=24: if invCtrl(1)=0 :if gArea=areaLumi ...
      if save.elona.guild_mage_point_quota <= 0 then
         Gui.mes("ui.inv.put.guild.have_no_quota")
         return "player_turn_query"
      end
      -- <<<<<<<< shade2/command.hsp:3462 	if invCtrl=24: if invCtrl(1)=0 :if gArea=areaLumi ..
   end,

   on_query = function(ctxt)
      -- >>>>>>>> shade2/command.hsp:3482 		if invCtrl=24: if invCtrl(1)=0 :if gArea=areaLum ...
      Gui.mes("ui.inv.put.guild.remaining", save.elona.guild_mage_point_quota)
      -- <<<<<<<< shade2/command.hsp:3482 		if invCtrl=24: if invCtrl(1)=0 :if gArea=areaLum ..
   end,

   on_select = function(ctxt, item, amount)
      -- >>>>>>>> shade2/command.hsp:3893 				snd seInv ...
      Gui.play_sound("base.inv")

      local aspect = assert(item:get_aspect(IItemAncientBook))
      local points_earned = (aspect:calc(item, "difficulty") + 1) * amount
      save.elona.guild_mage_point_quota = math.max(save.elona.guild_mage_point_quota - points_earned, 0)
      local mes = I18N.get("ui.inv.put.guild.you_deliver", item:build_name(amount))
      mes = ("%s(%d Guild Point)"):format(mes, points_earned)
      Gui.mes_c(mes, "Green")
      if save.elona.guild_mage_point_quota == 0 then
         Gui.play_sound("base.complete1")
         Gui.mes_c("ui.inv.put.guild.you_fulfill", "Green")
      end

      item.amount = item.amount - amount
      ctxt.chara:refresh_weight()

      return "inventory_continue"
      -- <<<<<<<< shade2/command.hsp:3904 				goto *com_inventory ...
   end
}
data:add(inv_mages_guild_delivery_chest)

local inv_put_tax_box = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_put_tax_box",
   elona_id = 24,
   elona_sub_id = 2,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = true,
   window_title = "ui.inventory_command.put",
   query_text = "ui.inv.title.put",

   filter = function(ctxt, item)
      return item._id == "elona.bill"
   end,

   can_select = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3907 				if cGold(pc)<iSubName(ci):snd seFail1:txt lang ...
      if ctxt.chara.gold < item.params.bill_gold_amount then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.tax.not_enough_money")
         return false
      end

      -- This can happen if you buy an extra bill from Miral.
      if save.elona.unpaid_bill_count <= 0 then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.tax.do_not_have_to")
         return false
      end
      -- <<<<<<<< shade2/command.hsp:3908 				if gBill<=0 : snd seFail1:txt lang("まだ納税する必要はな ..

      return true
   end,

   on_select = function(ctxt, item, amount)
      -- >>>>>>>> shade2/command.hsp:3909 				cGold(pc)-=iSubName(ci) ...
      ctxt.chara.gold = math.floor(ctxt.chara.gold - item.params.bill_gold_amount)
      Gui.play_sound("base.paygold1")
      Gui.mes_c("ui.inv.put.tax.you_pay", "Green", item:build_name())
      item:remove(1)
      save.elona.unpaid_bill_count = save.elona.unpaid_bill_count - 1

      return "inventory_continue"
      -- <<<<<<<< shade2/command.hsp:3915 				goto *com_inventory ..
   end
}
data:add(inv_put_tax_box)

local inv_put_four_dimensional_pocket = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_put_four_dimensional_pocket",
   elona_id = 24,
   elona_sub_id = 5,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = true,
   window_title = "ui.inventory_command.put",
   query_text = "ui.inv.title.put",

   can_select = function(ctxt, item)
      local success = Effect.do_stamina_check(ctxt.chara, 10)
      if not success then
         Gui.mes("magic.common.too_exhausted")
         return "turn_end"
      end

      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,

   on_select = function(ctxt, item, amount)
      -- HACK: Assuming ctxt.container is an api.Inventory. Probably want to have
      -- an IInventory interface that both IChara and Inventory satisfy.
      if not ctxt.container:can_take_object(item) then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.container.full")
         return "inventory_continue"
      end

      local max_weight = ctxt.container:get_max_item_weight()
      if max_weight and item:calc("weight") >= max_weight then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.container.too_heavy", max_weight)
         return "inventory_continue"
      end

      if item:get_aspect(IItemCargo) then
         Gui.play_sound("base.fail1")
         Gui.mes("ui.inv.put.container.cannot_hold_cargo")
         return "inventory_continue"
      end

      local result = Action.put_in_container(ctxt.container, item, amount)

      return "inventory_continue"
   end
}
data:add(inv_put_four_dimensional_pocket)

local inv_identify = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_identify",
   elona_id = 13,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.identify",
   query_text = "ui.inv.title.identify",

   filter = function(ctxt, item)
      return item.identify_state ~= Enum.IdentifyState.Full
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_identify)

local function find_altar(x, y, map)
   return Item.at(x, y, map)
   :filter(function(i) return i:has_category("elona.furniture_altar") end)
      :nth(1)
end

local inv_offer = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_offer",
   elona_id = 19,

   sources = { "chara" },
   icon = nil,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.offer",
   query_text = "ui.inv.title.offer",

   filter = function(ctxt, item)
      local god = ctxt.chara:calc("god")
      return God.can_offer_item_to(god, item)
   end,

   after_filter = function(ctxt, filtered)
      -- >>>>>>>> shade2/command.hsp:3460 	if invCtrl=19: item_find fltAltar ,2 : if stat=fa ...
      local altar = find_altar(ctxt.chara.x, ctxt.chara.y, ctxt.chara:current_map())

      if not Item.is_alive(altar) then
         Gui.mes_duplicate()
         Gui.mes("ui.inv.offer.no_altar")
         return "player_turn_query"
      end
      -- <<<<<<<< shade2/command.hsp:3460 	if invCtrl=19: item_find fltAltar ,2 : if stat=fa ..
   end,

   can_select = function(ctxt, item)
      if item:calc("is_no_drop") then
         return false, "marked as no drop"
      end

      return true
   end,

   on_select = function(ctxt, item, amount)
      local altar = find_altar(ctxt.chara.x, ctxt.chara.y, ctxt.chara:current_map())

      return God.offer(ctxt.chara, item, altar)
   end
}
data:add(inv_offer)

local inv_equipment = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equipment",
   elona_id = 23,
   elona_sub_id = 0,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      return item:has_category("elona.furniture") or ElonaItem.is_equipment(item)
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_equipment)

local inv_equipment_weapon = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equipment_weapon",
   elona_id = 23,
   elona_sub_id = 1,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      return item:has_category("elona.equip_melee") or item:has_category("elona.equip_ranged")
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_equipment_weapon)

local inv_equipment_armor = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equipment_armor",
   elona_id = 23,
   elona_sub_id = 2,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      return ElonaItem.is_armor(item)
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_equipment_armor)

local inv_chargeable = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_chargeable",
   elona_id = 23,
   elona_sub_id = 3,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      return item:iter_aspects(IChargeable):length() > 0
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_chargeable)

local inv_equipment_alchemy = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equipment_alchemy",
   elona_id = 23,
   elona_sub_id = 4,

   sources = { "chara" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3402 		if invCtrl(1)=4: if iEquip(cnt)!0 :continue ..
      return true
      -- <<<<<<<< shade2/command.hsp:3402 		if invCtrl(1)=4: if iEquip(cnt)!0 :continue ..
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_equipment_alchemy)

local inv_equipment_flight = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_equipment_flight",
   elona_id = 23,
   elona_sub_id = 6,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      -- >>>>>>>> shade2/command.hsp:3404 		if invCtrl(1)=6: if (iWeight(cnt)<=0)or(iId(cnt) ..
      return item.weight > 1 and not item:calc("cannot_use_flight_on") ~= false
      -- <<<<<<<< shade2/command.hsp:3404 		if invCtrl(1)=6: if (iWeight(cnt)<=0)or(iId(cnt) ..
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_equipment_flight)

local inv_garoks_hammer = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_garoks_hammer",
   elona_id = 23,
   elona_sub_id = 7,

   sources = { "chara", "equipment" },
   icon = 17,
   show_money = false,
   query_amount = false,
   window_title = "ui.inventory_command.target",
   query_text = "ui.inv.title.target",

   filter = function(ctxt, item)
      return item:calc("quality") < Enum.Quality.Great and ElonaItem.is_equipment(item)
   end,

   on_select = function(ctxt, item, amount)
      return "inventory_continue"
   end
}
data:add(inv_garoks_hammer)

local inv_take = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_take",
   elona_id = 25,

   sources = { "target", "target_equipment" },
   icon = 17,
   show_money = true,
   query_amount = false,
   -- >>>>>>>> shade2/command.hsp:3943 			if iId(ci)=idGold:in=iNum(ci):else:in=1 ...
   default_amount = 1,
   -- <<<<<<<< shade2/command.hsp:3943 			if iId(ci)=idGold:in=iNum(ci):else:in=1 ..
   -- >>>>>>>> shade2/command.hsp:3565 	if invCtrl=25:s="" ...
   hide_weight_text = true,
   -- <<<<<<<< shade2/command.hsp:3565 	if invCtrl=25:s="" ..
   -- >>>>>>>> shade2/command.hsp:3568 	if invCtrl=25{ ...
   show_target_equip = true,
   -- <<<<<<<< shade2/command.hsp:3568 	if invCtrl=25{ ..
   window_title = "ui.inventory_command.take",
   query_text = "ui.inv.title.take",
}

function inv_take.on_select(ctxt, item, amount)
   -- >>>>>>>> shade2/command.hsp:3919 		if invCtrl=25{ ...
   local chara = ctxt.chara
   local target = ctxt.target

   if chara:is_inventory_full() then
      Gui.mes("ui.inv.common.inventory_full")
      return "inventory_continue"
   end

   local will_give, complaint = Calc.will_chara_give_item_back(target, item, amount)
   if not will_give then
      Gui.play_sound("base.fail1")
      complaint = complaint or "ui.inv.take_ally.refuse_dialog"
      Gui.mes_c(complaint, "Blue", target, item:build_name(amount))
      return "inventory_continue"
   end

   if item:is_equipped() then
      if item:calc("curse_state") <= Enum.CurseState.Cursed then
         Gui.mes("ui.inv.take_ally.cursed", item:build_name())
         return "inventory_continue"
      end
      assert(target:unequip_item(item))
   end

   local result = item:emit("elona.on_item_taken", {chara=chara, target=target, amount=amount}, nil)
   if result then
      return result
   end

   Gui.play_sound("base.equip1")
   item.always_drop = false

   if item._id == "elona.gold_piece" then
      amount = item.amount
   end

   Gui.mes("ui.inv.take_ally.you_take", item:build_name(amount))

   -- TODO maybe make less special-casey
   if item._id == "elona.gold_piece" then
      chara.gold = chara.gold + amount
      item:remove(amount)
   else
      local sep = item:separate(amount)
      sep:remove_ownership()
      assert(chara:take_item(sep))
      ElonaItem.convert_artifact(sep)
   end

   Equipment.equip_all_optimally(target)
   target:refresh()
   target:refresh_weight()

   return "inventory_continue"
   -- <<<<<<<< shade2/command.hsp:3955 			} ..
end

data:add(inv_take)

local inv_buy_small_medals = {
   _type = "elona_sys.inventory_proto",
   _id = "inv_buy_small_medals",
   elona_id = 28,

   sources = { "shop" },
   shortcuts = false,
   icon = nil,
   query_amount = false,
   show_money = true,
   window_title = "ui.inventory_command.buy",
   query_text = "ui.inv.title.buy",
   window_detail_header = "ui.inv.trade_medals.window.medal",

   get_item_detail_text = function(name, item)
      return I18N.get("ui.inv.trade_medals.medal_value", Calc.calc_item_medal_value(item))
   end,
   sort = function(ctxt, a, b)
      return Calc.calc_item_medal_value(a.item) < Calc.calc_item_medal_value(b.item)
   end,

   on_query = function(ctxt)
      -- >>>>>>>> shade2/command.hsp:3477 		if invCtrl=28{ ...
      local medals = ElonaItem.find_small_medals(ctxt.chara)
      local medal_amount = medals and medals.amount or 0
      Gui.mes("ui.inv.trade_medals.medals", medal_amount)
      -- <<<<<<<< shade2/command.hsp:3481 			} ..
   end,

   can_select = function(ctxt, item)
      if not can_take(item) then
         return "turn_end"
      end

      return true
   end,
   on_select = function(ctxt, item, amount)
      -- >>>>>>>> shade2/command.hsp:3969 			txtNew ...
      Gui.mes_newline()

      amount = 1
      local cost = Calc.calc_item_medal_value(item)

      if ctxt.chara:is_inventory_full() then
         Gui.mes("ui.inv.trade_medals.inventory_full")
         Gui.play_sound("base.fail1")
         return "inventory_continue"
      end

      local medals = ElonaItem.find_small_medals(ctxt.chara)

      if medals == nil or cost > medals.amount then
         Gui.mes("ui.inv.trade_medals.not_enough_medals")
         Gui.play_sound("base.fail1")
         return "inventory_continue"
      end

      medals:remove(cost)
      Gui.play_sound("base.paygold1", ctxt.chara.x, ctxt.chara.y)
      local new_item = item:clone()
      item.amount = amount
      assert(ctxt.chara:take_item(new_item))
      Gui.mes("ui.inv.trade_medals.you_receive", new_item:build_name(amount))
      item:stack(true)
      -- TODO convertArtifact

      return "inventory_continue"
      -- <<<<<<<< shade2/command.hsp:3979 			goto *com_inventory ..
   end
}
data:add(inv_buy_small_medals)
