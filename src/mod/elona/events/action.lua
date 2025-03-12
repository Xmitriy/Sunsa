local Event = require("api.Event")
local Gui = require("api.Gui")
local ElonaAction = require("mod.elona.api.ElonaAction")
local Enum = require("api.Enum")
local Effect = require("mod.elona.api.Effect")
local ICharaSandBag = require("mod.elona.api.aspect.ICharaSandBag")

local function bump_into_chara(player, params, result)
   -- >>>>>>>> shade2/action.hsp:537 		tc=cellChara ...
   local on_cell = params.chara
   local relation = player:relation_towards(on_cell)

   if relation >= Enum.Relation.Ally
      or (relation == Enum.Relation.Dislike and (not config.base.attack_neutral_npcs or Gui.player_is_running()))
   then
      if not on_cell:calc_aspect(ICharaSandBag, "is_hung_on_sand_bag") then
         Gui.mes("action.move.displace.text", on_cell)
         if player:swap_places(on_cell) then
            on_cell:emit("elona.on_chara_displaced", {chara=player})
         end
         return "turn_end"
      end
   end

   if relation <= Enum.Relation.Dislike then
      if Effect.is_visible(on_cell, player) then
         player:set_target(on_cell)
      end
      ElonaAction.melee_attack(player, on_cell)
      return "turn_end"
   end

   Effect.try_to_chat(on_cell, player)

   return result
   -- <<<<<<<< shade2/action.hsp:563 		goto *turn_end ..
end

Event.register("elona_sys.on_player_bumped_into_chara", "Attack/swap position", bump_into_chara)

local function interrupt_eating_activity(chara, params, result)
   -- >>>>>>>> shade2/action.hsp:551 			if cRowAct(tc)=rowActEat:if cActionPeriod(tc)>0 ...
   local displacer = params.chara
   local activity = chara:get_activity()
   if activity and activity.proto.interrupt_on_displace then
      Gui.mes("action.move.interrupt", chara, displacer)
      chara:remove_activity()
   end
   -- <<<<<<<< shade2/action.hsp:551 			if cRowAct(tc)=rowActEat:if cActionPeriod(tc)>0 ..
end

Event.register("elona.on_chara_displaced", "Interrupt eating activity", interrupt_eating_activity)

local function proc_moved_onto_water(chara, params)
   -- >>>>>>>> shade2/action.hsp:639  	if tRole(p)=tWater{ ...
   chara.y_offset = nil

   local map = chara:current_map()
   if not map then
      return
   end

   local tile = map:tile(chara.x, chara.y)
   if tile.kind == Enum.TileRole.Water then
      -- >>>>>>>> shade2/module.hsp:826 					gmode 2,32,48:pos px+24,py+8:grotate selPcc,a ...
      chara.y_offset = 8
      -- <<<<<<<< shade2/module.hsp:826 					gmode 2,32,48:pos px+24,py+8:grotate selPcc,a ..

      if tile.kind2 == Enum.TileRole.MountainWater then
         Effect.heal_insanity(chara, 1)
      end

      Gui.add_effect_map("base.effect_map_ripple", chara.x, chara.y)

      if not chara:has_effect("elona.wet") then
         Effect.get_wet(chara, 20)
      end

      -- >>>>>>>> shade2/action.hsp:746 			if p=tWater:snd seWater ...
      if chara:is_player() then
         Gui.play_sound("base.water2", chara.x, chara.y)
      end
      -- <<<<<<<< shade2/action.hsp:746 			if p=tWater:snd seWater ..
   end
   -- <<<<<<<< shade2/action.hsp:642 		} ...end
end
Event.register("base.on_chara_moved", "Proc movement onto water", proc_moved_onto_water)
