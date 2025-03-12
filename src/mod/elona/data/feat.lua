local Enum = require("api.Enum")
local Effect = require("mod.elona.api.Effect")
local Gui = require("api.Gui")
local Item = require("api.Item")
local Map = require("api.Map")
local Rand = require("api.Rand")
local Skill = require("mod.elona_sys.api.Skill")
local ElonaAction = require("mod.elona.api.ElonaAction")
local SkillCheck = require("mod.elona.api.SkillCheck")
local Chara = require("api.Chara")
local Itemgen = require("mod.elona.api.Itemgen")
local Calc = require("mod.elona.api.Calc")
local Anim = require("mod.elona_sys.api.Anim")
local Pos = require("api.Pos")
local MapTileset = require("mod.elona_sys.map_tileset.api.MapTileset")
local QuestBoardMenu = require("api.gui.menu.QuestBoardMenu")
local Quest = require("mod.elona_sys.api.Quest")
local Dialog = require("mod.elona_sys.dialog.api.Dialog")
local Magic = require("mod.elona_sys.api.Magic")
local I18N = require("api.I18N")
local Filters = require("mod.elona.api.Filters")

data:add {
   _type = "base.feat",
   _id = "door",
   elona_id = 21,
   image = "elona.feat_door_wooden_closed",
   is_solid = true,
   is_opaque = true,
   params = {
      opened = { type = types.boolean, default = false },
      open_sound = { type = types.optional(types.data_id("base.sound")), default = "base.door1" },
      close_sound = { type = types.optional(types.data_id("base.sound")), default = "base.door1" },
      locked_sound = { type = types.optional(types.data_id("base.sound")), default = "base.locked1" },
      opened_tile = { type = types.optional(types.data_id("base.chip")), default = "elona.feat_door_wooden_open" },
      closed_tile = { type = types.optional(types.data_id("base.chip")), default = "elona.feat_door_wooden_closed" },
      difficulty = { type = types.number, default = 0 }
   },
   on_refresh = function(self)
      self.params.opened = not not self.params.opened

      self.can_open = not self.params.opened
      self.can_close = self.params.opened
      self.is_solid = not self.params.opened
      self.is_opaque = not self.params.opened

      if self.params.opened then
         self.image = self.params.opened_tile
      else
         self.image = self.params.closed_tile
      end
   end,
   on_bumped_into = function(self, params) self.proto.on_open(self, params) end,

   on_open = function(self, params)
      if self.params.opened then
         return "turn_end"
      end

      local chara = params.chara

      -- TODO move to aspect
      if SkillCheck.try_to_open_door(chara, self) then
         if self.params.difficulty > 0 then
            -- >>>>>>>> shade2/calculation.hsp:99 	skillExp rsOpenLock,r1,100 ...
            Skill.gain_skill_exp(chara, "elona.lock_picking", 100)
            -- <<<<<<<< shade2/calculation.hsp:99 	skillExp rsOpenLock,r1,100 ..
         end
         self.params.difficulty = 0
         self.params.opened = true
         self.is_solid = false
         self.is_opaque = false

         if chara:is_in_fov() then
            Gui.mes("action.open.door.succeed", chara)
         end
         if self.params.open_sound then
            Gui.play_sound(self.params.open_sound, self.x, self.y)
         end
      else
         Gui.mes_duplicate()
         if self.params.locked_sound then
            Gui.play_sound(self.params.locked_sound, self.x, self.y)
         end
         if chara:is_in_fov() then
            Gui.mes("action.open.door.fail", chara)
         end
      end

      if chara:is_player() then
         Gui.wait(100)
      end

      self:refresh()

      return "turn_end"
   end,
   on_close = function(self, params)
      self.params.opened = false
      self.is_solid = true
      self.is_opaque = true

      Gui.mes("action.close.execute", params.chara)
      if self.close_sound then
         Gui.play_sound(self.close_sound, self.x, self.y)
      end

      self:refresh()
      return "turn_end"
   end,
   on_bash = function(self, params)
      -- >>>>>>>> elona122/shade2/action.hsp:443 		if feat(1)=objDoorClosed{ ..
      if self.params.opened then
         return nil
      end

      local basher = params.chara
      Gui.play_sound("base.bash1")

      local difficulty = self.params.difficulty * 3 + 30
      local is_jail = self:current_map()._archetype == "elona.jail"

      if is_jail then
         difficulty = difficulty * 20
      end

      local str = basher:skill_level("elona.stat_strength")

      if Rand.rnd(difficulty) < str and Rand.one_in(2) then
         Gui.mes("action.bash.door.destroyed")
         if self.params.difficulty > str then
            Skill.gain_skill_exp("elona.stat_strength", (self.params.difficulty - str) * 15)
         end
         self:remove_ownership()
         return "turn_end"
      else
         Gui.mes("action.bash.door.execute")
         if is_jail then
            Gui.mes("action.bash.door.jail")
         end

         if Rand.one_in(4) then
            basher:apply_effect("elona.confusion", 200)
         end
         if Rand.one_in(3) then
            basher:apply_effect("elona.paralysis", 200)
         end
         if Rand.one_in(3) then
            if basher:calc("quality") < Enum.Quality.Great
               and not Effect.has_sustain_enchantment(basher, "elona.stat_strength")
            then
               basher:add_stat_adjustment("elona.stat_strength", -1)
               basher:refresh()
               Gui.mes_c("action.bash.door.hurt", "Purple", basher)
            end
         end
         if Rand.one_in(3) then
            if self.params.difficulty > 0 then
               self.params.difficulty = self.params.difficulty - 1
               Gui.mes_visible("action.bash.door.cracked", basher)
            end
         end
      end


      return "turn_end"
      -- <<<<<<<< elona122/shade2/action.hsp:464 		} ..
   end
}


data:add {
   _type = "base.feat",
   _id = "pot",
   elona_id = 30,

   image = "elona.feat_pot",
   is_solid = true,
   is_opaque = false,

   on_bash = function(self, params)
      local map = self:current_map()
      local basher = params.chara

      self.image = nil

      local level = map:calc("level")
      if map._archetype == "elona.shelter" then level = 0 end

      local filter = {
         level = Calc.calc_object_level(level, map),
         quality = Calc.calc_object_quality(Enum.Quality.Good),
         categories = Rand.choice(Filters.fsetbarrel)
      }
      Itemgen.create(self.x, self.y, filter, map)

      map:memorize_tile(self.x, self.y)
      Gui.update_screen()

      if Map.is_in_fov(basher.x, basher.y) then
         Gui.play_sound("base.bash1")
         Gui.mes("action.bash.shatters_pot", basher)
         Gui.play_sound("base.crush1")
         local anim = Anim.breaking(self.x, self.y)
         Gui.start_draw_callback(anim)
      end

      self:remove_ownership()

      return "turn_end"
   end,

   events = {
      {
         id = "elona_sys.on_bump_into",
         name = "Bump into to shatter pot",
         callback = function(self, params)
            return ElonaAction.bash(params.chara, self.x, self.y)
         end
      }
   }
}

data:add {
   _type = "base.feat",
   _id = "hidden_path",
   elona_id = 22,

   image = "elona.feat_hidden",
   is_solid = false,
   is_opaque = false,

   on_search_from_distance = function(self, params)
      local chara = params.chara

      if math.abs(chara.y - self.y) > 1 or math.abs(chara.x - self.x) > 1 then
         return
      end

      if SkillCheck.try_to_reveal(chara) then
         local map = chara:current_map()
         local tile = MapTileset.get("elona.mapgen_tunnel", map)
         Map.set_tile(self.x, self.y, tile, map)
         self:remove_ownership()
         Gui.mes("action.search.discover.hidden_path")
      end
   end,

   events = {
      {
         id = "elona.on_feat_tile_digged_into",
         name = "Reveal hidden path.",

         callback = function(self, params)
            -- >>>>>>>> shade2/proc.hsp:1069 			if map(refX,refY,6)!0{ ...
            local map = self:current_map()
            local tile = MapTileset.get("elona.mapgen_tunnel", map)
            Map.set_tile(self.x, self.y, tile, map)
            self:remove_ownership()
            -- <<<<<<<< shade2/proc.hsp:1072 				}		 ..
         end
      }
   }
}

local function visit_quest_giver(quest)
   local player = Chara.player()
   local map = player:current_map()
   local client = Chara.find(quest.client_uid, "all", map)
   assert(client)
   Magic.cast("elona.shadow_step", {source=player, target=client})
   if Chara.is_alive(client) then
      Dialog.start(client, "elona.quest_giver:quest_about")
   end

   -- TODO return turn event?
   return nil
end

data:add {
   _type = "base.feat",
   _id = "quest_board",
   elona_id = 23,

   image = "elona.feat_quest_board",
   is_solid = true,
   is_opaque = false,

   on_bumped_into = function(self, params)
      local pred = function(quest)
         return quest.originating_map_uid == self:current_map().uid
            and quest.state == "not_accepted"
      end
      local quests_here = Quest.iter():filter(pred):to_list()
      local quest, canceled = QuestBoardMenu:new(quests_here):query()
      if quest == nil or canceled then
         return
      end

      return visit_quest_giver(quest)
   end,
}

data:add {
   _type = "base.feat",
   _id = "voting_box",
   elona_id = 31,

   image = "elona.feat_voting_box",
   is_solid = true,
   is_opaque = false,

   on_bumped_into = function(self, params)
      Gui.play_sound("base.chat")
      Gui.mes("Voting box.")
   end
}

data:add {
   _type = "base.feat",
   _id = "small_medal",
   elona_id = 32,

   image = "elona.feat_hidden",
   is_solid = false,
   is_opaque = false,

   on_search_from_distance = function(self, params)
      local chara = params.chara
      if chara.x == self.x and chara.y == self.y then
         Gui.play_sound("base.ding2")
         Gui.mes("action.search.small_coin.find")
         Item.create("elona.small_medal", self.x, self.y)
         self:remove_ownership()
      else
         if Pos.dist(chara.x, chara.y, self.x, self.y) > 2 then
            Gui.mes("action.search.small_coin.far")
         else
            Gui.mes("action.search.small_coin.close")
         end
      end
   end,
}

data:add {
   _type = "base.feat",
   _id = "politics_board",
   elona_id = 33,

   image = "elona.feat_politics_board",
   is_solid = true,
   is_opaque = false,

   on_bumped_into = function(self, params)
      Gui.play_sound("base.chat")
      Gui.mes("Politics board.")
   end,
}


-- TODO feat: trap handling (procMove)

data:add {
   _type = "base.feat",
   _id = "mine",
   elona_id = 14,
   elona_sub_id = 7,

   image = "elona.feat_trap",
   is_solid = false,
   is_opaque = false,

   on_stepped_on = function(self, params)
      local chara = params.chara
      Gui.mes_c("action.move.trap.activate.mine", "SkyBlue")
      local cb = Anim.ball({{ chara.x, chara.y }}, nil, nil, chara.x, chara.y, chara:current_map())
      Gui.start_draw_callback(cb)
      self:remove_ownership()
      params.chara:damage_hp(100+Rand.rnd(200), "elona.trap")
   end,
}

-- For dungeon generation.
data:add {
   _type = "base.feat",
   _id = "mapgen_block",

   is_solid = true,
   is_opaque = true
}

data:add {
   _type = "base.feat",
   _id = "plant",
   elona_id = 29,

   image = "elona.feat_plant_0",
   is_solid = false,
   is_opaque = false,

   params = {
      plant_id = { type = types.data_id("elona.plant"), default = "elona.vegetable" },
      plant_growth_stage = { type = types.uint, default = 0 },
      plant_time_to_growth_days = { type = types.number, default = 0 },
   },

   on_stepped_on = function(self, params)
      -- >>>>>>>> shade2/action.hsp:768 			if feat(1)=objPlant{ ...
      local name = I18N.get("plant." .. self.params.plant_id .. ".plant_name")

      local stage = self.params.plant_growth_stage
      if stage == 0 then
         Gui.mes("action.move.feature.seed.growth.seed", name)
      elseif stage == 1 then
         Gui.mes("action.move.feature.seed.growth.bud", name)
      elseif stage == 2 then
         Gui.mes("action.move.feature.seed.growth.tree", name)
      else
         Gui.mes("action.move.feature.seed.growth.withered", name)
      end
      -- <<<<<<<< shade2/action.hsp:780 				} ...   end,
   end,

   events = {
      {
         id = "elona.on_harvest_plant",
         name = "Harvest plant.",
         callback = function(self, params)
            data["elona.plant"]:ensure(self.params.plant_id).on_harvest(self, params)
         end
      }
   }
}

require("mod.elona.data.feat.entrance")
