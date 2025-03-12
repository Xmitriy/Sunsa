local Event = require("api.Event")
local Rand = require("api.Rand")
local Gui = require("api.Gui")
local ElonaItem = require("mod.elona.api.ElonaItem")
local IItemRod = require("mod.elona.api.aspect.IItemRod")
local Magic = require("mod.elona_sys.api.Magic")

-- >>>>>>>> shade2/proc.hsp:1687 	if cc=pc : if trait(traitGodElement):if (ele=rsRe ...
-- TODO data_ext
local ITZPALT_BUFF_TARGETS = table.set {
   "elona.fire",
   "elona.cold",
   "elona.lightning",
}

local function itzpalt_trait(_, params, dice)
   local chara = params.chara
   if not chara or not chara:has_trait("elona.god_element") then
      return dice
   end

   if dice and dice.element then
      if ITZPALT_BUFF_TARGETS[dice.element] then
         dice.y = math.floor(dice.y * 125 / 100)
      end
   end
end
Event.register("elona_sys.calc_magic_dice", "Itzpalt trait buff for elemental spells", itzpalt_trait)
-- <<<<<<<< shade2/proc.hsp:1687 	if cc=pc : if trait(traitGodElement):if (ele=rsRe ...

local function fairy_trait(chara)
   -- >>>>>>>> shade2/calculation.hsp:389 		if trait(traitPermWeak)!false{ ...
   if not chara:has_trait("elona.perm_weak") then
      return
   end

   for _, part in chara:iter_equipped_body_parts() do
      local item = assert(part.equipped)
      if item:calc("weight") >= 1000 then
         assert(chara:unequip_item(item))
      end
   end
   -- <<<<<<<< shade2/calculation.hsp:395 			} ..
end
Event.register("base.on_refresh", "Fairy trait force unequip", fairy_trait, { priority = 30000 })

local function trait_ether_staff(item, params, result)
   -- >>>>>>>> shade2/action.hsp:180 		if trait(traitEtherStaff)!0:if iType(ci)=fltStaf ...
   local chara = params.chara
   if not chara:has_trait("elona.ether_staff") then
      return
   end

   local rod = item:get_aspect(IItemRod)
   if not rod then
      return
   end

   Gui.mes("action.pick_up.you_absorb_magic", item:build_name(), chara)

   local charges = rod.charges
   local effect_id = rod:calc(item, "effect_id")
   local skills = Magic.skills_for_magic(effect_id)

   local absorbed = false
   for _, skill_data in ipairs(skills) do
      if skill_data.type == "spell" then
         absorbed = true
         chara.spell_stocks[skill_data._id] = (chara.spell_stocks[skill_data._id] or 0) + (charges * 5 + item.amount)
      end
   end

   if not absorbed then
      chara:heal_mp(charges * 5 * item.amount)
   end

   rod:set_charges(item, 0)
   -- <<<<<<<< shade2/action.hsp:189 			} ..
end
Event.register("base.on_get_item", "Proc ether disease staff trait", trait_ether_staff, { priority = 200000 })

local ETHER_POISON_EXCLUDE_ITEMS = table.set {
   "elona.poison",
   "elona.potion_of_cure_corruption"
}

local function trait_ether_poison(item, params, result)
   -- >>>>>>>> shade2/action.hsp:190 		if trait(traitEtherPoison)!0:if iType(ci)=fltPot ...
   local chara = params.chara
   if not chara:has_trait("elona.ether_poison") then
      return
   end

   if item:has_category("elona.drink") and not ETHER_POISON_EXCLUDE_ITEMS[item._id] then
      if Rand.one_in(5) then
         Gui.mes("action.pick_up.poison_drips", chara)
         item:change_prototype("elona.poison", { replace_aspects = true })
         item.image = ElonaItem.default_item_image(item) or item.image
      end
   end
   -- <<<<<<<< shade2/action.hsp:193 			} ..
end
Event.register("base.on_get_item", "Proc ether disease poison trait", trait_ether_poison, { priority = 60000 })
