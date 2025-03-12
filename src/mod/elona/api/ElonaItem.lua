local I18N = require("api.I18N")
local Log = require("api.Log")
local Enum = require("api.Enum")
local ItemMemory = require("mod.elona_sys.api.ItemMemory")
local Rand = require("api.Rand")
local CharaMake = require("api.CharaMake")
local ItemMaterial = require("mod.elona.api.ItemMaterial")
local Event = require("api.Event")
local Chara = require("api.Chara")
local World = require("api.World")
local Effect = require("mod.elona.api.Effect")
local Util = require("mod.elona_sys.api.Util")
local Enchantment = require("mod.elona.api.Enchantment")
local Calc = require("mod.elona.api.Calc")
local Filters = require("mod.elona.api.Filters")
local Itemgen = require("mod.elona.api.Itemgen")
local Gui = require("api.Gui")
local Input = require("api.Input")
local Save = require("api.Save")
local Item = require("api.Item")
local Hunger = require("mod.elona.api.Hunger")
local IItemCargo = require("mod.elona.api.aspect.IItemCargo")
local IItemFood = require("mod.elona.api.aspect.IItemFood")
local IItemInittable = require("mod.elona.api.aspect.IItemInittable")
local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local IChargeable = require("mod.elona.api.aspect.IChargeable")

local ElonaItem = {}

function ElonaItem.generate_oracle_text(item)
   -- >>>>>>>> shade2/item.hsp:631 	if fixLv=fixUnique:if mode!mode_shop:if noOracle= ...
   local date = save.base.date
   local known_name = I18N.localize("base.item", item._id, "name")

   local owner = item:get_owning_chara()

   if owner then
      if owner:find_role("elona.adventurer") then
         local Adventurer = require("mod.elona.api.Adventurer")
         local area = Adventurer.area_of(owner)
         if area then
            return I18N.get("magic.oracle.was_held_by", known_name, owner, area.name, date.day, date.month, date.year)
         end
      end
   end

   local map = item:containing_map()
   local map_name = "?"
   if map == nil then
      Log.error("No containing map for %s!", item:build_name())
   else
      map_name = map.name
   end
   return I18N.get("magic.oracle.was_created_at", known_name, map_name, date.day, date.month, date.year)
   -- <<<<<<<< shade2/item.hsp:636  	} ...
end

-- >>>>>>>> shade2/item.hsp:708 	if (refType=fltGold)or(refType=fltPlat)or(iId(ci) ..
-- TODO externalize
local NORMAL_ITEMS = table.set {
   "elona.platinum_coin",
   "elona.gold_piece",
   "elona.small_medal",
   "elona.music_ticket",
   "elona.token_of_friendship",
   "elona.bill",
}
-- <<<<<<<< shade2/item.hsp:708 	if (refType=fltGold)or(refType=fltPlat)or(iId(ci) ...

-- >>>>>>>> shade2/command.hsp:3399 		if invCtrl(1)=1: if (refType!fltWeapon)&(refType ..
-- TODO add "elona.equipment" instead
local EQUIPMENT_CATEGORIES = {
   "elona.equip_melee",
   "elona.equip_head",
   "elona.equip_shield",
   "elona.equip_body",
   "elona.equip_leg",
   "elona.equip_cloak",
   "elona.equip_back",
   "elona.equip_wrist",
   "elona.equip_ranged",
   "elona.equip_ammo",
   "elona.equip_ring",
   "elona.equip_neck",
}
-- <<<<<<<< shade2/command.hsp:3399 		if invCtrl(1)=1: if (refType!fltWeapon)&(refType ...

-- >>>>>>>> shade2/command.hsp:3400 		if invCtrl(1)=2: if (refType<fltHeadArmor)or(ref ..
-- NOTE: Excludes ammo.
-- TODO add "elona.equipment_armor" instead
local ARMOR_CATEGORIES = {
   "elona.equip_head",
   "elona.equip_shield",
   "elona.equip_body",
   "elona.equip_leg",
   "elona.equip_cloak",
   "elona.equip_back",
   "elona.equip_wrist",
   "elona.equip_ring",
   "elona.equip_neck",
}
-- <<<<<<<< shade2/command.hsp:3400 		if invCtrl(1)=2: if (refType<fltHeadArmor)or(ref ...

-- >>>>>>>> shade2/init.hsp:812 	#define global ctype range_fltAccessory(%%1)	((%%1> ...
local ACCESSORY_CATEGORIES = {
   "elona.equip_ring",
   "elona.equip_neck",
}
-- <<<<<<<< shade2/init.hsp:812 	#define global ctype range_fltAccessory(%%1)	((%%1> ...

-- >>>>>>>> shade2/item.hsp:520 	if refType<fltFurniture{ ..
-- TODO add "elona.non_usable" instead
local NON_USEABLE_CATEGORIES = {
   "elona.furniture",
   "elona.furniture_well",
   "elona.furniture_altar",
   "elona.remains",
   "elona.junk",
   "elona.gold",
   "elona.platinum",
   "elona.container",
   "elona.ore",
   "elona.tree",
   "elona.cargo_food",
   "elona.cargo",
   "elona.bug",
}
-- <<<<<<<< shade2/item.hsp:520 	if refType<fltFurniture{ ..

local function has_any_category(item, cats)
   return fun.iter(cats):any(function(cat) return item:has_category(cat) end)
end

-- TODO remove
function ElonaItem.is_equipment(item)
   return item:get_aspect(IItemEquipment)
end

-- TODO remove
function ElonaItem.is_armor(item)
   return has_any_category(item, ARMOR_CATEGORIES)
end

-- TODO remove
function ElonaItem.is_accessory(item)
   return has_any_category(item, ACCESSORY_CATEGORIES)
end

-- TODO remove
function ElonaItem.is_non_useable(item)
   return has_any_category(item, NON_USEABLE_CATEGORIES)
end

local function is_randomized_material(material)
   return material == "elona.metal" or material == "elona.soft"
end

local function fix_item_2(item, params)
   -- >>>>>>>> shade2/item.hsp:519 *item_fix ..
   if item.proto.quality then
      item.quality = item.proto.quality
   end

   if not ElonaItem.is_non_useable(item) then
      if Rand.one_in(12) then
         item.curse_state = Enum.CurseState.Blessed
      end
      if Rand.one_in(13) then
         item.curse_state = Enum.CurseState.Cursed
         if ElonaItem.is_equipment(item) and Rand.one_in(4) then
            item.curse_state = Enum.CurseState.Doomed
         end
      end
   end

   if CharaMake.is_active() then
      item.curse_state = Enum.CurseState.Normal
   end

   if item.quality == Enum.Quality.Unique then
      item.curse_state = Enum.CurseState.Normal
   end

   if ElonaItem.is_equipment(item) or item:has_category("elona.furniture") and Rand.one_in(5) then
      if is_randomized_material(item.material) or item:has_category("elona.furniture") then
         local chara_level
         if CharaMake.is_active() then
            -- TODO need the level of the generated character
            chara_level = 1
         end
         local level = item.level
         local quality = item.quality
         local material = ItemMaterial.choose_random_material(item, nil, level, quality, chara_level)
         ItemMaterial.apply_item_material(item, material)
      else
         -- If a Unique quality item is generated with a material already
         -- defined on it (like the Blood Moon), then the stat bonuses from the
         -- material will *not* be applied, but the enchantments will.
         ItemMaterial.apply_material_enchantments(item)
      end
   end

   -- NOTE: fltPotion instead of fltHeadItem
   if ElonaItem.is_equipment(item) then
      Enchantment.add_random_enchantments(item)
   else
      if item.quality ~= Enum.Quality.Unique then
         item.quality = Enum.Quality.Normal
      end
   end
   -- <<<<<<<< shade2/item.hsp:549 	return ..
end

-- >>>>>>>> shade2/item.hsp:685 	if refType=fltChest{ ..
local function init_container(item, params, map)
   local map = item:containing_map()
   local map_level = (map and map:calc("level")) or 1

   -- TODO shelter
   local is_shelter = map and map._archetype == "elona.shelter"
   local item_level = 5 + ((not is_shelter) and 1 or 0) * map_level

   local difficulty = Rand.rnd(((not is_shelter) and 1 or 0) * math.abs(map_level) + 1)

   item.params.chest_item_level = math.floor(item_level)
   item.params.chest_lockpick_difficulty = difficulty
   item.params.chest_random_seed = Rand.rnd(30000)
end

-- >>>>>>>> shade2/item.hsp:697 	if refType=fltFood : if iParam1(ci)!0{ ..
local function init_food(item, params)
   local food = assert(item:get_aspect(IItemFood))

   if params.is_shop then
      if Rand.one_in(2) then
         food.food_quality = 0
      else
         food.food_quality = 3 + Rand.rnd(3)
      end
   end

   if food:is_cooked_dish(item) then
      item.image = Hunger.get_food_image(food:calc(item, "food_type"), food:calc(item, "food_quality"))
   end

   if item.material == "elona.fresh" then
      food.spoilage_date = food.spoilage_hours + World.date_hours()
   end
end
-- <<<<<<<< shade2/item.hsp:701 	} ..

-- >>>>>>>> shade2/text.hsp:213 	_randColor	=coDefault	,coGreen	,coBlue		,coYellow ..
local RANDOM_COLORS = {
   Enum.Color.White,
   Enum.Color.Green,
   Enum.Color.Blue,
   Enum.Color.Yellow,
   Enum.Color.Brown,
   Enum.Color.Red
}
-- <<<<<<<< shade2/text.hsp:213 	_randColor	=coDefault	,coGreen	,coBlue		,coYellow ...

function ElonaItem.random_item_color(item, seed)
   seed = seed or save.base.random_seed
   local index = (Util.string_to_integer(item._id) % seed) % 6
   return table.deepcopy(RANDOM_COLORS[index+1])
end

local FURNITURE_COLORS = {
   Enum.Color.White,
   Enum.Color.Green,
   Enum.Color.Blue,
   Enum.Color.Yellow,
   Enum.Color.Brown
}

function ElonaItem.random_furniture_color()
   -- >>>>>>>> shade2/item.hsp:613 	if iCol(ci)=coRand	:iCol(ci)=randColor(rnd(length ...
   return table.deepcopy(Rand.choice(FURNITURE_COLORS))
   -- <<<<<<<< shade2/item.hsp:613 	if iCol(ci)=coRand	:iCol(ci)=randColor(rnd(length ...end
end

function ElonaItem.default_item_image(item)
   local food = item:get_aspect(IItemFood)
   if food and food:is_cooked_dish(item) then
      return Hunger.get_food_image(food:calc(item, "food_type"), food:calc(item, "food_quality"))
   else
      return item.proto.image
   end
end

function ElonaItem.default_item_color(item, seed)
   -- >>>>>>>> shade2/item.hsp:615 	iCol(ci)=iColOrg(ci) ...
   if item.proto.random_color == "Random" then
      return ElonaItem.random_item_color(item)
   elseif item.proto.random_color == "Furniture" then
      return ElonaItem.random_furniture_color(item)
   else
      if item.proto.color then
         return item.proto.color
      end

      local material = item:calc("material")
      if material then
         return data["elona.item_material"]:ensure(material).color
      end

      return nil
   end
   -- <<<<<<<< shade2/item.hsp:616 	if iCol(ci)=coRand	:iCol(ci)=randColor(rnd(length ..
end

function ElonaItem.fix_item(item, params)
   -- If true:
   --  - Do not autoidentify with Sense Quality immediately upon creation.
   --  - No chance to generate unique items.
   --  - No artifact generation log for oracle.
   --  - Can generate any kind of home deed.
   --  - Can generate cooked food in addition to raw food.
   local is_shop = params.is_shop

   -- If true, do not allow the item to appear in the text when casting Oracle.
   local no_oracle = params.no_oracle or is_shop

   -- >>>>>>>> shade2/item.hsp:615 	iCol(ci)=iColOrg(ci) ...
   item.color = ElonaItem.default_item_color(item) or item.color
   -- <<<<<<<< shade2/item.hsp:616 	if iCol(ci)=coRand	:iCol(ci)=randColor(rnd(length ..

   -- >>>>>>>> shade2/item.hsp:628 	itemMemory(1,dbId)++ ..
   ItemMemory.on_generated(item._id)
   item.quality = params.quality or item.quality

   if item.quality == Enum.Quality.Unique and not no_oracle then
      local text = ElonaItem.generate_oracle_text(item)
      table.insert(save.elona.artifact_locations, text)
   end
   -- <<<<<<<< shade2/item.hsp:636  	} ...

   local ev_params = table.shallow_copy(params)
   ev_params.owner = item:get_owning_chara()
   ev_params.map = item:containing_map()
   ev_params.level = ev_params.level or (ev_params.map and ev_params.map:calc("level")) or 1

   item:emit("base.on_item_init_params", ev_params)

   if item:has_category("elona.container") then
      init_container(item, params, ev_params.map)
   end

   if item:get_aspect(IItemFood) then
      init_food(item, params)
   end

   -- >>>>>>>> shade2/item.hsp:705 	if refType=fltFurniture:if rnd(3)=0:iSubName(ci)= ...
   fix_item_2(item, params)

   if item:has_category("elona.furniture") then
      item.params.furniture_quality = 0
      if Rand.one_in(3) then
         item.params.furniture_quality = Rand.rnd(Rand.rnd(12) + 1)
      end
   end

   if is_shop then
      item.identify_state = Enum.IdentifyState.Full
   end

   if NORMAL_ITEMS[item._id] then
      item.identify_state = Enum.IdentifyState.Full
      item.curse_state = Enum.CurseState.Normal
   end

   if item:get_aspect(IItemCargo) then
      item.identify_state = Enum.IdentifyState.Full
      item.curse_state = Enum.CurseState.Normal
      ItemMemory.set_known(item._id, true)
   end

   if item:has_category("elona.remains")
      or item:has_category("elona.junk")
      or item:has_category("elona.ore")
   then
      item.curse_state = Enum.CurseState.Normal
   end

   if config.base.debug_autoidentify then
      Effect.identify_item(item, config.base.debug_autoidentify)
   else
      local player = Chara.player()
      if player and not is_shop and ElonaItem.is_equipment(item) then
         if Rand.rnd(player:skill_level("elona.sense_quality")+1) > 5 then
            item.identify_state = Enum.IdentifyState.Quality
         end
      end
   end

   item.value = ItemMaterial.recalc_quality(item)
   -- <<<<<<<< shade2/item.hsp:726 	gosub *item_value ..
end

local function item_fix_on_build(obj, params)
   ElonaItem.fix_item(obj, params)
end
Event.register("base.on_build_item", "Apply Item.fix_item", item_fix_on_build)

local function apply_item_on_init_params(item, params)
   if item.proto.on_init_params then
      item.proto.on_init_params(item, params)
   end
   for _, aspect in item:iter_aspects(IItemInittable) do
      aspect:on_init_params(item, params)
   end
end
Event.register("base.on_item_init_params", "Default item on_init_params callback", apply_item_on_init_params)

function ElonaItem.convert_artifact(item, mode)
   if not ElonaItem.is_equipment(item) then return end
   if item.quality ~= Enum.Quality.Unique then return end
   if item:is_equipped() then return end
   Log.error("TODO")
end

function ElonaItem.ensure_free_item_slot(chara)
   -- >>>>>>>> shade2/adv.hsp:151 *chara_adjustInv ..
   if not chara:is_inventory_full() then
      return
   end
   for _ = 1, 100 do
      local item = Rand.choice(chara:iter_items())
      if not item:is_equipped() then
         item:remove_activity()
         item.amount = 0
         item:remove_ownership()
      end
   end
   -- <<<<<<<< shade2/adv.hsp:164 	return p ..
end

function ElonaItem.open_chest(item, gen_filter_cb, item_count, loot_level, seed, silent)
   local map, _, x, y = item:containing_map()
   if not map then
      return
   end

   -- >>>>>>>> shade2/action.hsp:967 	snd seOpenChest :txt lang("あなたは"+itemName(ci)+"を開 ...
   if not silent then
      Gui.play_sound("base.chest1", x, y)
      Gui.mes("action.open.text", item:build_name())
      Input.query_more()
   end
   -- <<<<<<<< shade2/action.hsp:967 	snd seOpenChest :txt lang("あなたは"+itemName(ci)+"を開 ..

   -- >>>>>>>> shade2/action.hsp:976 	p=3+rnd(5) ...
   item_count = item_count or (3 + Rand.rnd(5))
   loot_level = loot_level or item.params.chest_item_level
   seed = seed or item.params.chest_random_seed

   Rand.set_seed(seed)

   for i = 1, item_count do
      local filter = {}

      local quality
      if i == 1 then
         quality = Enum.Quality.Great
      else
         quality = Enum.Quality.Good
      end

      filter.level = Calc.calc_object_level(loot_level, map)
      filter.quality = Calc.calc_object_quality(quality)
      filter.categories = { Rand.choice(Filters.fsetchest) }

      if i > 1 and not Rand.one_in(3) then
         filter.categories = { "elona.gold" }
      else
         filter.categories = { "elona.ore_valuable" }
      end

      if gen_filter_cb then
         filter = gen_filter_cb(filter, item, loot_level) or filter
      end

      Itemgen.create(x, y, filter, map)
   end

   Rand.set_seed()

   if not silent then
      Gui.play_sound("base.ding2")
      Gui.mes("action.open.goods", item:build_name())
   end

   local create_medal = false
   if item._id ~= "elona.small_gamble_chest" and Rand.one_in(10) then
      create_medal = true
   end
   if (item._id == "elona.bejeweled_chest" or item._id == "elona.chest") and Rand.one_in(5) then
      create_medal = true
   end
   if create_medal then
      Item.create("elona.small_medal", x, y, { amount = 1 }, map)
   end

   item:stack()

   Save.queue_autosave()
   -- <<<<<<<< shade2/action.hsp:1022 	iParam1(ri)=0 ..
end

function ElonaItem.find_small_medals(chara)
   return chara:iter_items()
      :filter(function(i) return i._id == "elona.small_medal" end)
      :into_sorted(function(a, b) return a.amount > b.amount end)
      :nth(1)
end

-- TODO remove once everything is ported to aspects
function ElonaItem.get_item_charges(item)
   local charges, max_charges, is_charged
   for _, aspect in item:iter_aspects(IChargeable) do
      charges = (charges or 0) + aspect.charges
      max_charges = (max_charges or 0) + aspect:calc(item, "max_charges")
      is_charged = is_charged or aspect:is_charged(item)
   end
   return charges, max_charges, is_charged
end

return ElonaItem
