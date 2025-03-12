local Event = require("api.Event")
local Text = require("mod.elona.api.Text")
local Rand = require("api.Rand")
local Enum = require("api.Enum")
local MapObject = require("api.MapObject")
local I18N = require("api.I18N")
local Skill = require("mod.elona_sys.api.Skill")
local CharaMake = require("api.CharaMake")
local Const = require("api.Const")
local Map = require("api.Map")
local Charagen = require("mod.elona.api.Charagen")
local Log = require("api.Log")
local ElonaChara = require("mod.elona.api.ElonaChara")
local ICharaElonaFlags = require("mod.elona.api.aspect.chara.ICharaElonaFlags")

local function add_elona_flags(chara)
   chara:get_aspect_or_default(ICharaElonaFlags, true)
end

Event.register("base.on_build_chara", "Add ICharaElonaFlags", add_elona_flags, { priority = 1000 })

local function fix_name_gender_age(chara)
   if chara.proto.has_own_name then
      chara.own_name = Text.random_name()
      chara.name = I18N.get("chara.job.own_name", chara.name, chara.own_name)
   end
end

Event.register("base.on_build_chara", "Fix character name, age, gender", fix_name_gender_age)

local function random_portrait(chara)
   local ind = 1 + Rand.rnd(32)
   local prefix
   if chara:calc("gender") == "male" then
      prefix = "man"
   else
      prefix = "woman"
   end
   local id = ("elona.%s%d"):format(prefix, ind)
   return data["base.portrait"]:ensure(id)._id
end

local function fix_portrait(chara)
   -- >>>>>>>> shade2/chara.hsp:523 	if cPortrait(rc)=0:cPortrait(rc)=rnd(rangePortrai ...
   if chara.proto.portrait then
      if chara.proto.portrait == "random" then
         chara.portrait = random_portrait(chara)
      else
         data["base.portrait"]:ensure(chara.proto.portrait)
      end
   end
   -- <<<<<<<< shade2/chara.hsp:523 	if cPortrait(rc)=0:cPortrait(rc)=rnd(rangePortrai ..
end

Event.register("base.on_build_chara", "Fix portrait", fix_portrait)

local function fix_level_and_quality(chara)
   -- >>>>>>>> shade2/chara.hsp:492 *chara_fix ..
   if chara.quality == Enum.Quality.Great then
      chara.name = I18N.get("chara.quality.great", chara.name)
      chara.level = math.floor(chara.level * 10 / 8)
   end
   if chara.quality == Enum.Quality.God then
      chara.name = I18N.get("chara.quality.god", chara.name)
      chara.level = math.floor(chara.level * 10 / 6)
   end
   -- <<<<<<<< shade2/chara.hsp:503 	return ..
end

Event.register("base.on_build_chara",
               "Fix character level and quality", fix_level_and_quality)

local function calc_initial_resistance_level(chara, element)
   -- >>>>>>>> shade2/calculation.hsp:976 	repeat tailResist-headResist,headResist ..
   if chara:is_player() then
      return 100
   end

   local initial_level = chara:resist_level(element._id)
   local level = math.min(chara:calc("level") * 4 + 96, 300)
   if initial_level ~= 0 then
      if initial_level < 100 or initial_level > 500 then
         level = initial_level
      else
         level = level + initial_level
      end
   end
   if element.calc_initial_resist_level then
      level = element.calc_initial_resist_level(chara, level)
   end
   return level
   -- <<<<<<<< shade2/calculation.hsp:981 	loop ..
end

-- >>>>>>>> shade2/calculation.hsp:983 	i=4 ..
local initial_skills = {
   ["elona.axe"] = 4,
   ["elona.blunt"] = 4,
   ["elona.bow"] = 4,
   ["elona.crossbow"] = 4,
   ["elona.evasion"] = 4,
   ["elona.faith"] = 4,
   ["elona.healing"] = 4,
   ["elona.heavy_armor"] = 4,
   ["elona.light_armor"] = 4,
   ["elona.long_sword"] = 4,
   ["elona.martial_arts"] = 4,
   ["elona.meditation"] = 4,
   ["elona.medium_armor"] = 4,
   ["elona.polearm"] = 4,
   ["elona.scythe"] = 4,
   ["elona.shield"] = 3,
   ["elona.short_sword"] = 4,
   ["elona.stat_luck"] = 50,
   ["elona.stave"] = 4,
   ["elona.stealth"] = 4,
   ["elona.throwing"] = 4
}
-- <<<<<<<< shade2/calculation.hsp:1006 	skillInit rsLUC,r1,50 ...

local function init_skills_from_table(chara, tbl)
   for skill_id, level in pairs(tbl) do
      local init = Skill.calc_initial_skill_level(skill_id, level, chara:base_skill_level(skill_id), chara:calc("level"), chara)
      chara:set_base_skill(skill_id, init.level, init.potential, 0)
   end
end

local function init_skills(chara)
   local elements = data["base.element"]:iter():filter(function(e) return e.can_resist end)
   for _, element in elements:unwrap() do
      local level = calc_initial_resistance_level(chara, element)
      chara:set_base_resist(element._id, level, 0, 0)
   end

   init_skills_from_table(chara, initial_skills)
end

Event.register("base.on_build_chara",
               "Init skills", init_skills)

local function apply_race_class(chara)
   -- TODO: Should not be applied on player
   -- It is actually possible for characters to lack a class, but usually not a race.
   if not CharaMake.is_active() then
      if chara.race ~= nil then
         Skill.apply_race_params(chara, chara.race)
      end
      if chara.class ~= nil then
         Skill.apply_class_params(chara, chara.class)
      end
   end
end

Event.register("base.on_chara_normal_build",
               "Init race and class", apply_race_class)

local function init_lay_hand(chara)
   if chara.has_lay_hand then
      chara.is_lay_hand_available = true
   end
end

Event.register("base.on_build_chara",
               "Init lay hand", init_lay_hand)

local function init_chara_defaults(chara)
   -- >>>>>>>> shade2/chara.hsp:509 	cInterest(rc)=100 ..
   chara.interest = 100
   chara.impression = Const.IMPRESSION_NORMAL
   chara.fov = 14
   -- <<<<<<<< shade2/chara.hsp:511 	cFov(rc)=14 ..

   -- >>>>>>>> shade2/chara.hsp:516 	if rc=pc:cHunger(rc)=9000:else:cHunger(rc)=defAll ..
   chara.nutrition = Const.ALLY_HUNGER_THRESHOLD - 1000 + Rand.rnd(4000)

   chara.required_experience = Skill.calc_required_experience(chara)

   -- TODO custom talk
   -- See mod/elona/locale/en/talk_random.lua (talk.random.personality.<n>)
   chara.personality = Rand.rnd(4)
   -- <<<<<<<< shade2/chara.hsp:524 	cPersonality(rc)=rnd(rangePS) ..
end

Event.register("base.on_build_chara",
               "Init chara_defaults", init_chara_defaults)

local function init_player_defaults(player)
   -- >>>>>>>> shade2/chara.hsp:516 	if rc=pc:cHunger(rc)=9000:else:cHunger(rc)=defAll ...
   player.nutrition = 9000
   -- <<<<<<<< shade2/chara.hsp:516 	if rc=pc:cHunger(rc)=9000:else:cHunger(rc)=defAll ..

   -- >>>>>>>> shade2/chara.hsp:532 	if rc=pc{ ..
   player.initial_max_cargo_weight = 80000
   player.max_cargo_weight = player.initial_max_cargo_weight
   -- <<<<<<<< shade2/chara.hsp:534 		} ..
end

Event.register("base.on_initialize_player", "Init player defaults", init_player_defaults)

local function init_chara_image(chara)
   if chara.image == nil then
      chara.image = "base.default"
   end

   if chara.image == "base.default" then
      local image = ElonaChara.default_chara_image(chara)
      if image then
         chara.image = image
      else
         Log.error("No chara image for %s", chara)
      end
   end
end

Event.register("base.on_build_chara",
               "Init chara image", init_chara_image)

Event.register("base.generate_chara_name", "Elona character name generation", function(_, _, result)
                  if result and result ~= "" then
                     return result
                  end
                  return Text.random_name()
end)

Event.register(
   "base.hook_generate_chara",
   "Shade generation",
   function(_, params, result)
      -- >>>>>>>> shade2/chara.hsp:473 	npcMemory(1,dbId)++ 	 ..
      if params.no_modify then
         return result
      end

      if params.id ~= "elona.shade" then
         return result
      end

      if not Rand.one_in(5) then
         return result
      end

      if params.level then
         params.level = params.level * 2
      end
      if params.quality and params.quality > Enum.Quality.Good then
         params.quality = Enum.Quality.Good
      end
      params.id = Charagen.random_chara_id_raw(params.level, params.filter, params.category)

      -- using Chara.create would cause recursion
      local chara = MapObject.generate_from("base.chara", params.id, params.uid_tracker)

      chara.is_shade = true
      chara.name = I18N.get("chara.job.shade")
      chara.image = "elona.chara_shade"
      -- <<<<<<<< shade2/chara.hsp:485 	if cmShade:cnName(rc)=lang("シェイド","shade"):	cPic( ...

      if params.where then
         Map.try_place_chara(chara, params.x, params.y, params.where)
      end

      MapObject.finalize(chara, params.gen_params)

      return chara
end)
