local Enum = require("api.Enum")
local Const = require("api.Const")
local Chara = require("api.Chara")
local Combat = require("mod.elona.api.Combat")
local Feat = require("api.Feat")
local Gui = require("api.Gui")
local Input = require("api.Input")
local Item = require("api.Item")
local Map = require("api.Map")
local Rand = require("api.Rand")
local Skill = require("mod.elona_sys.api.Skill")
local Anim = require("mod.elona_sys.api.Anim")
local Action = require("api.Action")
local Effect = require("mod.elona.api.Effect")
local Pos = require("api.Pos")
local I18N = require("api.I18N")
local EquipRules = require("api.chara.EquipRules")
local ICharaEquipStyle = require("api.chara.aspect.ICharaEquipStyle")
local IItemMeleeWeapon = require("mod.elona.api.aspect.IItemMeleeWeapon")
local IItemRangedWeapon = require("mod.elona.api.aspect.IItemRangedWeapon")
local ICharaElonaFlags = require("mod.elona.api.aspect.chara.ICharaElonaFlags")

local ElonaAction = {}

local function proc_shield_bash(chara, target)
   -- >>>>>>>> shade2/action.hsp:1213         if sync(cc):txt lang(name(cc)+"は盾で"+name(t ..
   local shield = chara:skill_level("elona.shield")
   local do_bash = math.clamp(math.sqrt(shield) - 3, 1, 5) + ((chara:calc_aspect(ICharaElonaFlags, "has_shield_bash") and 5) or 0)
   if Rand.percent_chance(do_bash) then
      Gui.mes_visible("action.melee.shield_bash", chara, target)
      target:damage_hp(Rand.rnd(shield) + 1, chara)
      target:apply_effect("elona.dimming", 50 + math.floor(math.sqrt(shield)) * 15)
      target:add_effect_turns("elona.paralysis", Rand.rnd(3))
   end
   -- <<<<<<<< shade2/action.hsp:1216         cParalyze(tc)+=rnd(3) ..
end

-- >>>>>>>> shade2/action.hsp:1219     repeat sizeBody ..
local function body_part_where_equipped(cb)
   return function(entry) return cb(entry.equipped) end
end

function ElonaAction.get_melee_weapons(chara)
   local pred = body_part_where_equipped(EquipRules.is_melee_weapon)
   return chara:iter_equipped_body_parts():filter(pred):extract("equipped")
end
-- <<<<<<<< shade2/action.hsp:1229     return ..

function ElonaAction.melee_attack(chara, target)
   -- >>>>>>>> shade2/action.hsp:1197 *act_melee ..
   if chara:calc_aspect(ICharaEquipStyle, "is_wielding_shield") then
      proc_shield_bash(chara, target)
   end

   local attack_number = 0

   for _, weapon in ElonaAction.get_melee_weapons(chara) do
      local skill = weapon:calc_aspect(IItemMeleeWeapon, "skill")
      attack_number = attack_number + 1
      ElonaAction.physical_attack(chara, weapon, target, skill, 0, attack_number)
   end

   if attack_number == 0 then
      ElonaAction.physical_attack(chara, nil, target, "elona.martial_arts", 0, attack_number, false)
   end
   -- <<<<<<<< shade2/action.hsp:1229     return ..
end

function ElonaAction.get_ranged_weapon_and_ammo(chara)
   -- >>>>>>>> shade2/command.hsp:4290 *FindRangeWeapon ...
   local pred = body_part_where_equipped(EquipRules.is_ranged_weapon)
   local ranged = chara:iter_equipped_body_parts():filter(pred):extract("equipped"):nth(1)

   pred = body_part_where_equipped(EquipRules.is_ammo)
   local ammo = chara:iter_equipped_body_parts():filter(pred):extract("equipped"):nth(1)

   if ranged == nil then
      return nil, "no_ranged_weapon"
   end

   local aspect = ranged:get_aspect(IItemRangedWeapon)
   if not ammo and not aspect:can_use_without_ammo(ranged) then
      return nil, "no_ammo"
   end

   if ammo and not aspect:can_use_with_ammo(ranged, ammo) then
      return nil, "wrong_ammo"
   end

   return ranged, ammo
   -- <<<<<<<< shade2/command.hsp:4302 	return true ..
end

function ElonaAction.ranged_attack(chara, target, weapon, ammo)
   -- >>>>>>>> shade2/action.hsp:1148 *act_fire ..
   local ammo_enchantment_id = nil
   local ammo_enchantment_data = nil

   if ammo then
      local enc = ammo.params.ammo_loaded
      if enc then
         if enc.params.ammo_current <= 0 then
            Gui.mes("action.ranged.load_normal_ammo")
            ammo.params.ammo_loaded = nil
         else
            -- get the `base.ammo_enchantment` ID of this InstancedEnchantment
            ammo_enchantment_id = enc.params.ammo_enchantment_id
            ammo_enchantment_data = data["base.ammo_enchantment"]:ensure(ammo_enchantment_id)

            if chara:is_player() then
               if chara.stamina < Const.FATIGUE_LIGHT and chara.stamina < Rand.rnd(Const.FATIGUE_LIGHT * 1.5) then
                  Gui.mes("magic.common.too_exhausted")
                  chara:damage_sp(ammo_enchantment_data.stamina_cost / 2 + 1)
                  return true
               end
               chara:damage_sp(ammo_enchantment_data.stamina_cost+ 1)
               enc.params.ammo_current = enc.params.ammo_current - 1
            end
         end
      end
   end

   local skill = weapon:calc_aspect(IItemRangedWeapon, "skill")

   if ammo_enchantment_data and ammo_enchantment_data.on_ranged_attack then
      ammo_enchantment_data.on_ranged_attack(chara, weapon, target, skill, ammo, ammo_enchantment_id)
   else
      ElonaAction.physical_attack(chara, weapon, target, skill, 0, 0, true, ammo, ammo_enchantment_id)
   end

   return true
   -- <<<<<<<< shade2/action.hsp:1195 	return ..
end

local function show_miss_text(chara, target, extra_attacks)
   -- >>>>>>>> shade2/action.hsp:1365 	if hit=atkEvade:if sync(cc){ ...
   if not Map.is_in_fov(chara.x, chara.y) then
      return
   end
   if extra_attacks > 0 then
      Gui.mes("damage.furthermore")
      Gui.mes_continue_sentence()
   end
   if target:is_ally() then
      Gui.mes("damage.miss.ally", chara, target)
   else
      Gui.mes("damage.miss.other", chara, target)
   end
   -- <<<<<<<< shade2/action.hsp:1368 		} ...
end

local function show_evade_text(chara, target, extra_attacks)
   -- >>>>>>>> shade2/action.hsp:1369 	if hit=atkEvadePlus:if sync(cc){ ...
   if not Map.is_in_fov(chara.x, chara.y) then
      return
   end
   if extra_attacks > 0 then
      Gui.mes("damage.furthermore")
      Gui.mes_continue_sentence()
   end
   if target:is_ally() then
      Gui.mes("damage.evade.ally", chara, target)
   else
      Gui.mes("damage.evade.other", chara, target)
   end
   -- <<<<<<<< shade2/action.hsp:1372 		} ...
end

function ElonaAction.play_ranged_animation(chara, start_x, start_y, end_x, end_y, attack_skill, weapon)
   local chip, sound, color

   local ranged = weapon:get_aspect(IItemRangedWeapon)
   if ranged then
      chip, color, sound = ranged:calc_anim_chip_and_sound(weapon)
   else
      chip = weapon:calc("image")
      color = weapon:calc("color") or {255, 255, 255}
      sound = "base.throw1"
   end

   if chara:is_in_fov() then
      local cb = Anim.ranged_attack(start_x, start_y, end_x, end_y, chip, color, sound, nil)
      Gui.start_draw_callback(cb)
   end
end

local function do_physical_attack(chara, weapon, target, attack_skill, extra_attacks, attack_number, is_ranged, ammo, ammo_enc)
   -- >>>>>>>> shade2/action.hsp:1233 *act_attack ..
   if not Chara.is_alive(chara) or not Chara.is_alive(target) then
      return
   end

   if chara:has_effect("elona.fear") then
      Gui.mes_duplicate()
      Gui.mes("damage.is_frightened", chara)
      return
   end
   -- <<<<<<<< shade2/action.hsp:1237  ..

   local event_params = {
      weapon = weapon,
      target = target,
      is_ranged = is_ranged,
      ammo = ammo,
      attack_skill = attack_skill,
      extra_attacks = extra_attacks,
   }

   local result = chara:emit("elona.before_physical_attack", event_params, {blocked=false})
   if result.blocked then
      return
   end

   -- >>>>>>>> shade2/action.hsp:1248 	if attackRange=true:call anime,(animeId=attackSki ..
   if is_ranged then
      ElonaAction.play_ranged_animation(chara, chara.x, chara.y, target.x, target.y, attack_skill, weapon)
   end
   -- <<<<<<<< shade2/action.hsp:1248 	if attackRange=true:call anime,(animeId=attackSki ..

   attack_skill = attack_skill or "elona.martial_arts"

   -- >>>>>>>> shade2/action.hsp:1253 	hit=calcAttackHit() ..
   local hit = Combat.calc_attack_hit(chara, weapon, target, attack_skill, attack_number, is_ranged, ammo)
   local did_hit = hit == "hit" or hit == "critical"
   local is_critical = hit == "critical"

   if did_hit then
      if chara:is_player() then
         if is_critical then
            Gui.mes_c("damage.critical_hit", "Red")
            Gui.play_sound("base.atk2", target.x, target.y)
         else
            Gui.play_sound("base.atk1", target.x, target.y)
         end
      end

      local raw_damage = Combat.calc_attack_damage(chara, weapon, target, attack_skill, is_ranged, is_critical, ammo, ammo_enc)
      local damage = raw_damage.damage
      local original_damage = raw_damage.original_damage

      local play_animation = chara:is_player() and config.base.attack_anime
      if play_animation then
         local damage_percent = damage * 100 / target:calc("max_hp")
         local kind = data["base.skill"]:ensure(attack_skill).attack_animation or 0
         local anim = Anim.melee_attack(target.x, target.y, target:calc("breaks_into_debris"), kind, damage_percent, is_critical)
         Gui.start_draw_callback(anim)
      end

      local element, element_power
      if weapon then
         local quality = weapon:calc("quality")
         if quality >= Enum.Quality.Great
            -- Don't spoil the item's title if not fully identified yet
            and weapon:calc("identify_state") >= Enum.IdentifyState.Full
         then
            local name
            if quality == Enum.Quality.Unique then
               name = I18N.get("item.title_paren.article", weapon.name)
            else
               if weapon.title then
                  name = weapon.title
               else
                  name = I18N.get("item.title_paren.article", weapon.name)
               end
            end
            name = I18N.get("item.title_paren.great", name)
            if Rand.one_in(5) then
               Gui.mes_c_visible("damage.wields_proudly", chara.x, chara.y, "SkyBlue", chara, name)
            end
         end
      else
         element = chara:calc("unarmed_element_id")
         element_power = chara:calc("unarmed_element_power")
         if element then
            element_power = element_power or 100
         end
      end

      local tense = "enemy"
      if not target:is_ally() then
         tense = "ally"
      end

      local killed, base_damage, actual_damage = target:damage_hp(damage, chara, {element=element,element_power=element_power,extra_attacks=extra_attacks,weapon=weapon,message_tense=tense,attack_skill=attack_skill})
      -- <<<<<<<< shade2/action.hsp:1292  ..

      chara:emit("elona.on_physical_attack_hit", {weapon=weapon,target=target,hit=hit,damage=damage,base_damage=base_damage,actual_damage=actual_damage,original_damage=original_damage,is_ranged=is_ranged,attack_skill=attack_skill,killed=killed,ammo=ammo,ammo_enchantment=ammo_enc})
   else
      local play_sound = chara:is_player()
      if play_sound then
         Gui.play_sound("base.miss", target.x, target.y)
      end
      chara:emit("elona.on_physical_attack_miss", {weapon=weapon,target=target,hit=hit,is_ranged=is_ranged,attack_skill=attack_skill})
   end

   if hit == "miss" then
      show_miss_text(chara, target, extra_attacks)
   elseif hit == "evade" then
      show_evade_text(chara, target, extra_attacks)
   end

   target:interrupt_activity()
   -- TODO living weapon

   chara:emit("elona.after_physical_attack", {weapon=weapon,target=target,hit=hit,is_ranged=is_ranged,attack_skill=attack_skill})
end

function ElonaAction.physical_attack(chara, weapon, target, attack_skill, extra_attacks, attack_number, is_ranged, ammo, ammo_enc)
   local attacks = extra_attacks
   local going

   repeat
      do_physical_attack(chara, weapon, target, attack_skill, extra_attacks, attack_number, is_ranged, ammo, ammo_enc)
      going = false
      -- >>>>>>>> shade2/action.hsp:1383     if extraAttack=false{ ..
      if attacks == 0 then
         if is_ranged then
            if Rand.percent_chance(chara:calc("extra_ranged_attack_rate") or 0) then
               attacks = attacks + 1
               going = true
               ammo_enc = nil
            end
         else
            if Rand.percent_chance(chara:calc("extra_melee_attack_rate") or 0) then
               attacks = attacks + 1
               going = true
            end
         end
      end
      -- <<<<<<<< shade2/action.hsp:1389     } ..
   until not going
end

-- proc_damage_events_flag
-- 1:
--   - Print element damage 0 if chara is not killed
--   - do not trigger splitting behavior
-- 2:
--   - print "is scratched", "is slightly wounded", etc.
--   - print element text 1 if target is not party
--   - print transformed into meat/destroyed/minced if target is not party

function ElonaAction.prompt_really_attack(chara, target)
   Gui.mes(Action.target_level_text(chara, target))
   Gui.mes("action.really_attack", target)
   return Input.yes_no()
end

function ElonaAction.bash(chara, x, y)
   -- >>>>>>>> shade2/action.hsp:388     if map(x,y,5)!0{ ..
   for _, item in Item.at(x, y) do
      local result = item:emit("elona_sys.on_item_bash", {chara=chara}, nil)
      if result then return result end
   end

   local target = Chara.at(x, y)
   if target then
      if not target:has_effect("elona.sleep") then
         if chara:is_player() and target:relation_towards(chara) >= Enum.Relation.Neutral then
            if not ElonaAction.prompt_really_attack(chara, target) then
               return "player_turn_query"
            end
         end
         if target:has_effect("elona.choking") then
            Gui.play_sound("base.bash1")
            Gui.mes("action.bash.choked.execute", chara, target)
            local killed = target:damage_hp(chara:skill_level("elona.stat_strength") * 5, chara)
            if not killed then
               Gui.mes("action.bash.choked.spits", target)
               Gui.mes("action.bash.choked.dialog", target)
               target:remove_effect("elona.choking")
               Skill.modify_impression(target, 10)
            end
         else
            Gui.play_sound("base.bash1")
            Gui.mes("action.bash.execute", chara, target)
            chara:act_hostile_towards(target)
         end
      else
         Gui.play_sound("base.bash1")
         Gui.mes("action.bash.execute", chara, target)
         Gui.mes("action.bash.disturbs_sleep", chara, target)
         Effect.modify_karma(chara, -1)
         target:set_emotion_icon("elona.angry", 4)
      end
      target:remove_effect("elona.sleep")
      return "turn_end"
   end

   for _, feat in Feat.at(x, y) do
      local result = feat:emit("elona_sys.on_feat_bash", {chara=chara})
      if result then return true end
   end

   Gui.mes("action.bash.air", chara)
   Gui.play_sound("base.miss", x, y)

   return true
   -- <<<<<<<< shade2/action.hsp:467     goto *turn_end ..
end

function ElonaAction.read(chara, item)
   -- >>>>>>>> shade2/proc.hsp:1246 	if cBlind(cc)!0{ ...
   if chara:has_effect("elona.blindness") then
      Gui.mes_visible("action.read.cannot_see", chara.x, chara.y, chara)
      return "turn_end"
   end
   -- <<<<<<<< shade2/proc.hsp:1249 		}  ..

   local result = item:emit("elona_sys.on_item_read", {chara=chara,triggered_by="read"}, "turn_end")

   return result
end

function ElonaAction.eat(chara, item)
   -- >>>>>>>> shade2/action.hsp:364     if cc=pc{ ..
   local chara_using = item:get_chara_using()
   if chara:is_player() then
      if chara_using and chara_using.uid ~= chara.uid then
         Gui.mes("action.someone_else_is_using")
         return "player_turn_query"
      end
   elseif chara_using then
      if chara_using.uid ~= chara.uid then
         chara_using:finish_activity()
         chara_using:set_item_using(nil)
         assert(chara_using.item_using == nil)
         if chara:is_in_fov() then
            Gui.mes("action.eat.snatches", chara, chara_using)
         end
      end
   end

   chara:set_emotion_icon("elona.eat")
   chara:start_activity("elona.eating", {food=item, no_message=false})

   return "turn_end"
   -- <<<<<<<< shade2/action.hsp:372     goto *turn_end ..
end

function ElonaAction.drink(chara, item)
   local result = item:emit("elona_sys.on_item_drink", {chara=chara,triggered_by="potion"}, "turn_end")
   return result
end

function ElonaAction.zap(chara, item)
   local result = item:emit("elona_sys.on_item_zap", {chara=chara,triggered_by="wand"}, "turn_end")
   return result
end

function ElonaAction.use(chara, item)
   local result = item:emit("elona_sys.on_item_use", {chara=chara,triggered_by="use"}, "turn_end")
   return result
end

function ElonaAction.open(chara, item)
   local result = item:emit("elona_sys.on_item_open", {chara=chara,triggered_by="open"}, "turn_end")
   return result
end

function ElonaAction.dip(chara, dip_item, target_item)
   local result = dip_item:emit("elona_sys.on_item_dip_into", {chara=chara, target_item=target_item}, "turn_end")
   return result
end

function ElonaAction.throw(chara, item, tx, ty)
   -- >>>>>>>> shade2/action.hsp:3 *act_throw ...
   Gui.mes_visible("action.throw.execute", chara.x, chara.y, chara, item:build_name(1))
   local map = chara:current_map()

   if (Pos.dist(chara.x, chara.y, tx, ty) * 4 > Rand.rnd(chara:skill_level("elona.throwing") + 10) + chara:skill_level("elona.throwing") / 4)
      or Rand.one_in(10)
   then
      local x = tx + Rand.rnd(2) - Rand.rnd(2)
      local y = ty + Rand.rnd(2) - Rand.rnd(2)
      if Map.can_access(x, y, map) then
         tx = x
         ty = y
      end
   end

   local anim = Anim.ranged_attack(chara.x, chara.y, tx, ty, item:calc("image"), item:calc("color"))
   Gui.start_draw_callback(anim)

   item:remove(1)
   chara:refresh_weight()

   anim = Anim.breaking(tx, ty)
   Gui.start_draw_callback(anim)

   item:emit("elona_sys.on_item_throw", {chara=chara,x=tx,y=ty})
   -- <<<<<<<< shade2/action.hsp:24 	call anime,(animeId=aniCrush,x=tlocX,y=tlocY) ...

   return "turn_end"
end

function ElonaAction.trade(player, target)
   local cb = function(i) i.identify_state = Enum.IdentifyState.Full end
   target:iter_items():each(cb)
   local result, canceled = Input.query_inventory(player, "elona.inv_trade", {target=target})
   return result, canceled
end

function ElonaAction.do_sex(chara, target)
   chara:start_activity("elona.sex", {partner=target,is_host=true})
end

function ElonaAction.do_dig(chara, x, y)
   if chara.stamina < 0 then
      Gui.mes("action.dig.too_exhausted")
      return false
   end

   chara:start_activity("elona.mining", {x = x, y = y})
   return true
end

function ElonaAction.dig(chara, x, y)
   if x == chara.x and y == chara.y then
      chara:start_activity("elona.digging_spot")
      return "turn_end"
   end

   -- Don't allow digging into water.
   local tile = chara:current_map():tile(x, y)
   local can_dig = tile.is_solid and tile.role ~= Enum.TileRole.Water

   if not can_dig then
      Gui.mes("common.it_is_impossible")
      return "player_turn_query"
   end

   Gui.update_screen()
   local result = ElonaAction.do_dig(chara, x, y)

   if not result then
      return "player_turn_query"
   end

   return "turn_end"
end

return ElonaAction
