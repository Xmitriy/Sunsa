local Rand = require("api.Rand")
local I18N = require("api.I18N")
local Quest = require("mod.elona_sys.api.Quest")
local Gui = require("api.Gui")
local Chara = require("api.Chara")
local Dialog = require("mod.elona_sys.dialog.api.Dialog")
local Event = require("api.Event")
local Itemname = require("mod.elona.api.Itemname")
local ElonaItem = require("mod.elona.api.ElonaItem")
local Log = require("api.Log")
local IItemFood = require("mod.elona.api.aspect.IItemFood")

local cook = {
   _id = "cook",
   _type = "elona_sys.quest",
   _ordering = 90000,

   elona_id = 1003,
   client_chara_type = 3,
   reward = "elona.supply",
   reward_fix = 60,

   min_fame = 0,
   chance = 6,

   params = {
      food_type = types.string,
      food_quality = types.uint
   },

   difficulty = 0,

   expiration_hours = function() return (Rand.rnd(3) + 1) * 24 end,
   deadline_days = function() return Rand.rnd(6) + 2 end,

   locale_data = function(self)
      local ingredient = "food.names." .. self.params.food_type .. ".default_origin"
      local objective = Itemname.qualify_article(I18N.get("food.names." .. self.params.food_type .. "._" .. self.params.food_quality, ingredient))
      local params = { objective = objective }
      local key = "food_type." .. self.params.food_type
      return params, key
   end,
}

function cook.generate(self, client, start)
   local food_type = Rand.choice(data["elona.food_type"]:iter())
   local reward_category = food_type.quest_reward_category

   if reward_category then
      self.reward = { _id = "elona.by_category", category = reward_category }
   else
      Log.debug("No quest reward category for food type %s, using default", food_type._id)
      self.reward = { _id = "elona.supply" }
   end

   local food_quality = Rand.rnd(7) + 3
   self.difficulty = food_quality * 3
   self.reward_fix = 60 + self.difficulty

   self.params = {
      food_type = food_type._id,
      food_quality = food_quality
   }

   return true
end

data:add(cook)

local function cook_quest_for(chara)
   local function is_quest_client(q)
      return q._id == "elona.cook" and q.client_uid == chara.uid
   end
   return Quest.iter():filter(is_quest_client):nth(1)
end

local function find_item(chara, food_type, food_quality)
   local pred = function(item)
      return item:calc_aspect(IItemFood, "food_type") == food_type and item:calc_aspect(IItemFood, "food_quality") == food_quality
   end
   return chara:iter_inventory():filter(pred):nth(1)
end

data:add {
   _type = "elona_sys.dialog",
   _id = "quest_cook",

   nodes = {
      give = function(t)
         -- TODO generalize with dialog argument
         local quest = cook_quest_for(t.speaker)
         assert(quest)

         local item = find_item(Chara.player(), quest.params.food_type, quest.params.food_quality)

         Gui.mes("talk.npc.common.hand_over", item)
         ElonaItem.ensure_free_item_slot(t.speaker)
         local sep = assert(item:move_some(1, t.speaker))
         t.speaker.item_to_use = sep
         t.speaker.was_passed_quest_item = true

         Chara.player():refresh_weight()

         return Quest.complete(quest, t.speaker)
      end
   }
}

local function add_give_dialog_choice(speaker, _, choices)
   local quest = cook_quest_for(speaker)
   if quest then
      local item = find_item(Chara.player(), quest.params.food_type, quest.params.food_quality)
      if item then
         Dialog.add_choice("elona.quest_cook:give", I18N.get("talk.npc.quest_giver.choices.here_is_item", item:build_name(1)), choices)
      end
   end
   return choices
end

Event.register("elona.calc_dialog_choices", "Add give option for cook quest client",
               add_give_dialog_choice)
