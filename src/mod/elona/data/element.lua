local Chara = require("api.Chara")
local Gui = require("api.Gui")
local Rand = require("api.Rand")
local Effect = require("mod.elona.api.Effect")
local Event = require("api.Event")
local Mef = require("api.Mef")
local IMapObject = require("api.IMapObject")
local IChara = require("api.chara.IChara")
local Enum = require("api.Enum")

local function order(elona_id)
   return 100000 + elona_id * 10000
end

local element = {
   {
      _id = "fire",
      elona_id = 50,
      _ordering = order(50),
      color = { 255, 155, 155 },
      ui_color = { 150, 0, 0 },
      can_resist = true,
      sound = "base.atk_fire",
      death_anim = "base.anim_elem_fire",
      death_anim_dy = -20,
      rarity = 1,

      on_modify_damage = function(chara, damage)
         -- >>>>>>>> shade2/chara_func.hsp:1459 		if (ele=rsResFire)or(dmgSource=dmgFromFire):dmg= ..
         if chara:has_effect("elona.wet") then
            damage = damage / 3
         end

         return damage
         -- <<<<<<<< shade2/chara_func.hsp:1459 		if (ele=rsResFire)or(dmgSource=dmgFromFire):dmg= ..
      end,

      on_damage_tile = function(self, x, y, source)
         -- >>>>>>>> shade2/proc.hsp:1774 	if ele=rsResFire:mapitem_fire dx,dy ...
         Effect.damage_map_fire(x, y, source, source:current_map())
         -- <<<<<<<< shade2/proc.hsp:1774 	if ele=rsResFire:mapitem_fire dx,dy ..
      end,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1560 		if (ele=rsResFire)or(dmgSource=dmgFromFire): ite ...
         Effect.damage_chara_items_fire(chara)
         -- <<<<<<<< shade2/chara_func.hsp:1560 		if (ele=rsResFire)or(dmgSource=dmgFromFire): ite ..
      end,

      on_kill = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1643 		if (dmgSource=dmgFromFire)or(ele=rsResFire){ ..
         local origin
         if class.is_an(IMapObject, params.source) then
            origin = params.source
         end
         Mef.create("elona.fire", chara.x, chara.y, { duration = Rand.rnd(10) + 5, power = 100, origin = origin }, chara:current_map())
         -- <<<<<<<< shade2/chara_func.hsp:1645 			} ..
      end
   },
   {
      _id = "cold",
      elona_id = 51,
      _ordering = order(51),
      color = { 255, 255, 255 },
      ui_color = { 0, 0, 150 },
      can_resist = true,
      sound = "base.atk_ice",
      death_anim = "base.anim_elem_cold",
      rarity = 1,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1561 		if (ele=rsResCold): item_cold tc,-1 ...
         Effect.damage_chara_items_cold(chara)
         -- <<<<<<<< shade2/chara_func.hsp:1561 		if (ele=rsResCold): item_cold tc,-1 ..
      end,

      on_damage_tile = function(self, x, y, source)
         -- >>>>>>>> shade2/proc.hsp:1706 	if ele=rsResCold:mapitem_cold dx,dy ...
         Effect.damage_map_cold(x, y, source, source:current_map())
         -- <<<<<<<< shade2/proc.hsp:1706 	if ele=rsResCold:mapitem_cold dx,dy ..
      end,
   },
   {
      _id = "lightning",
      elona_id = 52,
      _ordering = order(52),
      color = { 255, 255, 175 },
      ui_color = { 150, 150, 0 },
      can_resist = true,
      sound = "base.atk_elec",
      death_anim = "base.anim_elem_lightning",
      rarity = 1,

      on_modify_damage = function(chara, damage)
         -- >>>>>>>> shade2/chara_func.hsp:1460 		if ele=rsResLightning	:dmg=dmg*3/2 ..
         if chara:has_effect("elona.wet") then
            damage = damage * 3 / 2
         end

         return damage
         -- <<<<<<<< shade2/chara_func.hsp:1460 		if ele=rsResLightning	:dmg=dmg*3/2 ..
      end,

      on_damage = function(chara)
         -- >>>>>>>> shade2/chara_func.hsp:1549 			if ele=rsResLightning	: if rnd(3+(cQuality(tc)> ..
         local chance = 3
         if chara:calc("quality") >= Enum.Quality.Great then -- miracle
            chance = chance + 3
         end
         if Rand.one_in(chance) then
            chara:apply_effect("elona.paralysis", 1)
         end
         -- <<<<<<<< shade2/chara_func.hsp:1549 			if ele=rsResLightning	: if rnd(3+(cQuality(tc)> ..
      end
   },
   {
      _id = "darkness",
      elona_id = 53,
      _ordering = order(53),
      color = { 175, 175, 255 },
      ui_color = { 100, 80, 80 },
      can_resist = true,
      sound = "base.atk_dark",
      death_anim = "base.anim_elem_darkness",
      rarity = 2,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1550 			if ele=rsResDarkness 	: dmgCon tc,conBlind,rnd( ..
         chara:apply_effect("elona.blindness",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1550 			if ele=rsResDarkness 	: dmgCon tc,conBlind,rnd( ..
      end
   },
   {
      _id = "mind",
      elona_id = 54,
      _ordering = order(54),
      color = { 255, 195, 185 },
      ui_color = { 150, 100, 50 },
      can_resist = true,
      preserves_sleep = true,
      sound = "base.atk_mind",
      death_anim = "base.anim_elem_mind",
      rarity = 2,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1552 			if ele=rsResMind	: dmgCon tc,conConfuse,rnd(ele ..
         chara:apply_effect("elona.confusion",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1552 			if ele=rsResMind	: dmgCon tc,conConfuse,rnd(ele ..
      end
   },
   {
      _id = "poison",
      elona_id = 55,
      _ordering = order(55),
      color = { 175, 255, 175 },
      ui_color = { 0, 150, 0 },
      can_resist = true,
      sound = "base.atk_poison",
      death_anim = "base.anim_elem_poison",
      rarity = 3,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1554 			if ele=rsResPoison	: dmgCon tc,conPoison,rnd(el ..
         chara:apply_effect("elona.poison",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1554 			if ele=rsResPoison	: dmgCon tc,conPoison,rnd(el ..
      end
   },
   {
      _id = "nether",
      elona_id = 56,
      _ordering = order(56),
      color = { 155, 154, 153 },
      ui_color = { 150, 50, 0 },
      can_resist = true,
      sound = "base.atk_hell",
      death_anim = "base.anim_elem_mind",
      death_anim_dy = -24,
      rarity = 4,

      after_apply_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1471 	if ele=rsResNether : if dmgSource >= dmgFromChara ..
         local damage = params.damage
         if params.source and damage > 0 then
            params.source:heal_hp(
               math.clamp(
                  Rand.rnd(
                     damage * (
                        150 + params.element_power * 2) / 1000 + 10), 1, params.source:calc(
                     "max_hp") / 10 + Rand.rnd(5)))
         end
         -- <<<<<<<< shade2/chara_func.hsp:1471 	if ele=rsResNether : if dmgSource >= dmgFromChara ..
      end,

      on_kill = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1646 		if ele=rsResNether	: if dmgSource >= dmgFromChar ..
         local damage = params.damage
         if class.is_an(IChara, params.source) then
            params.source:heal_hp(Rand.rnd(damage * (200 + params.element_power) / 1000 + 5))
         end
         -- <<<<<<<< shade2/chara_func.hsp:1646 		if ele=rsResNether	: if dmgSource >= dmgFromChar ..
      end
   },
   {
      _id = "sound",
      elona_id = 57,
      _ordering = order(57),
      color = { 235, 215, 155 },
      ui_color = { 50, 100, 150 },
      can_resist = true,
      sound = "base.atk_sound",
      death_anim = "base.anim_elem_sound",
      rarity = 3,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1553 			if ele=rsResSound	: dmgCon tc,conConfuse,rnd(el ..
         chara:apply_effect("elona.confusion",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1553 			if ele=rsResSound	: dmgCon tc,conConfuse,rnd(el ..
      end
   },
   {
      _id = "nerve",
      elona_id = 58,
      _ordering = order(59),
      color = { 155, 205, 205 },
      ui_color = { 100, 150, 50 },
      can_resist = true,
      preserves_sleep = true,
      sound = "base.atk_nerve",
      death_anim = "base.anim_elem_nerve",
      rarity = 3,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1551 			if ele=rsResNerve 	: dmgCon tc,conParalyze,rnd( ..
         chara:apply_effect("elona.paralysis",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1551 			if ele=rsResNerve 	: dmgCon tc,conParalyze,rnd( ..
      end
   },
   {
      _id = "chaos",
      elona_id = 59,
      _ordering = order(59),
      color = { 185, 155, 215 },
      ui_color = { 150, 0, 150 },
      can_resist = true,
      preserves_sleep = true,
      sound = "base.atk_chaos",
      death_anim = "base.anim_elem_chaos",
      rarity = 4,

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1542 			if ele=rsResChaos{ ..
         local elep = params.element_power
         local power = function()
            return Rand.rnd(elep / 3 * 2 + 1)
         end

         if Rand.rnd(10) < elep / 75 + 4 then
            chara:apply_effect("elona.blindness", power())
         end
         if Rand.rnd(20) < elep / 50 + 4 then
            chara:apply_effect("elona.paralysis", power())
         end
         if Rand.rnd(20) < elep / 50 + 4 then
            chara:apply_effect("elona.confusion", power())
         end
         if Rand.rnd(20) < elep / 50 + 4 then
            chara:apply_effect("elona.poison", power())
         end
         if Rand.rnd(20) < elep / 50 + 4 then
            chara:apply_effect("elona.sleep", power())
         end
         -- <<<<<<<< shade2/chara_func.hsp:1548 				} ..
      end,
   },
   {
      _id = "magic",
      elona_id = 60,
      _ordering = order(60),
      ui_color = { 150, 100, 100 },
      can_resist = true,
      rarity = 5,

      calc_initial_resist_level = function(chara, level)
         -- >>>>>>>> shade2/calculation.hsp:979 	if ((cnt=rsResMagic)&(p<500))or(cLevel(r1)=1):p=1 ..
         if level < 500 then
            return 100
         end
         return level
         -- <<<<<<<< shade2/calculation.hsp:979 	if ((cnt=rsResMagic)&(p<500))or(cLevel(r1)=1):p=1 ..
      end
   },
   {
      _id = "cut",
      elona_id = 61,
      _ordering = order(61),

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1555 			if ele=rsResCut		: dmgCon tc,conBleed,rnd(eleP+ ..
         chara:apply_effect("elona.bleeding",
                            Rand.rnd(params.element_power + 1))
         -- <<<<<<<< shade2/chara_func.hsp:1555 			if ele=rsResCut		: dmgCon tc,conBleed,rnd(eleP+ ..
      end
   },
   {
      _id = "ether",
      elona_id = 62,
      _ordering = order(62),

      on_damage = function(chara)
         print("ether")
      end
   },
   {
      _id = "acid",
      color = { 175, 255, 175 },
      elona_id = 63,
      _ordering = order(63),
      sound = "base.atk_poison",
      death_anim = "base.anim_elem_poison",

      on_damage = function(chara, params)
         -- >>>>>>>> shade2/chara_func.hsp:1557 			if ele=rsResAcid	: if (tc=pc)or(rnd(3)=0):item_ ...
         if chara:is_player() or Rand.one_in(3) then
            Effect.damage_chara_item_acid(chara)
         end
         -- <<<<<<<< shade2/chara_func.hsp:1557 			if ele=rsResAcid	: if (tc=pc)or(rnd(3)=0):item_ ..
      end
   },
   {
      _id = "hunger",
      elona_id = 614,
   },
   {
      _id = "rotten",
      elona_id = 613,
   },
   {
      _id = "fear",
      elona_id = 617,
   },
   {
      _id = "soft",
      elona_id = 618,
   },
   {
      _id = "vorpal",
      elona_id = 658,
   },
}

data:add_multi("base.element", element)

local function vorpal_damage(chara, params, result)
   -- >>>>>>>> shade2/chara_func.hsp:1467 	if ele=actFinish:dmg=dmgOrg ..
   if params.element and params.element._id == "elona.vorpal" then
      result = params.original_damage
   end
   return result
   -- <<<<<<<< shade2/chara_func.hsp:1467 	if ele=actFinish:dmg=dmgOrg ..
end

Event.register("base.hook_calc_damage", "Proc vorpal damage", vorpal_damage)
