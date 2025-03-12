local Rand = require("api.Rand")
local Chara = require("api.Chara")
local Calc = require("mod.elona.api.Calc")
local Enum = require("api.Enum")
local Charagen = require("mod.elona.api.Charagen")
local Feat = require("api.Feat")
local Item = require("api.Item")
local Filters = require("mod.elona.api.Filters")
local Itemgen = require("mod.elona.api.Itemgen")
local God = require("mod.elona.api.God")
local ElonaChara = require("mod.elona.api.ElonaChara")

local MapgenUtils = {}

function MapgenUtils.spray_tile(map, tile_id, density)
   local n = math.floor(map:width() * map:height() * density / 100 + 1)

   for _=1,n do
      local x = Rand.rnd(map:width())
      local y = Rand.rnd(map:height())
      map:set_tile(x, y, tile_id)
   end
end

function MapgenUtils.generate_chara(map, x, y, extra_params)
   local filter = ElonaChara.random_filter(map)
   local params = filter(map)
   if extra_params then
      table.merge(params, extra_params)
   end
   return Charagen.create(x, y, params, map)
end

function MapgenUtils.spawn_random_site(map, is_first_renewal, x, y)
   -- >>>>>>>> shade2/map_func.hsp:793 #deffunc map_randSite int dx,int dy ...
   if not x or not y then
      local pos = function()
         return Rand.rnd(map:width() - 5) + 2, Rand.rnd(map:height() - 5) + 2
      end

      local filter = function(x, y)
         return map:can_access(x, y)
            and Feat.at(x, y, map):length() == 0
            and Item.at(x, y, map):length() == 0
      end

      x, y = fun.tabulate(pos):filter(filter):take(20):nth(1)
   end

   if not x or not y then
      return false
   end

   if map:has_type("world") then
      local tile = map:tile(x, y)
      if tile.field_type == "elona.sea" or tile.is_road then
         return false
      end
   end

   if map:has_type("dungeon") then
      if is_first_renewal then
         if Rand.one_in(25) then
            local fountain = Item.create("elona.fountain", x, y, {}, map)
            if fountain then
               fountain.own_state = Enum.OwnState.NotOwned
               return true
            end
         end
         if Rand.one_in(100) then
            local altar = Item.create("elona.altar", x, y, {}, map)
            if altar then
               altar.own_state = Enum.OwnState.NotOwned
               altar.params.altar_god_id = God.random_god_id()
               return true
            end
         end
      end

      local mat_spot_info = "elona.default"

      if Rand.one_in(14) then
         mat_spot_info = "elona.remains"
      elseif Rand.one_in(13) then
         mat_spot_info = "elona.mine"
      elseif Rand.one_in(12) then
         mat_spot_info = "elona.spring"
      elseif Rand.one_in(11) then
         mat_spot_info = "elona.bush"
      end

      Feat.create("elona.material_spot", x, y, {params={material_spot_info=mat_spot_info}}, map)
      return true
   end

   if map:has_type("town") or map:has_type("guild") then
      if Rand.one_in(3) then
         Item.create("elona.moon_gate", x, y, {}, map)
         return true
      end

      if Rand.one_in(15) then
         Item.create("elona.platinum_coin", x, y, {}, map)
         return true
      end

      if Rand.one_in(20) then
         Item.create("elona.wallet", x, y, {}, map)
         return true
      end

      if Rand.one_in(15) then
         Item.create("elona.suitcase", x, y, {}, map)
         return true
      end

      if Rand.one_in(18) then
         local player = Chara.player()
         local filter = {
            level = Calc.calc_object_level(Rand.rnd(player:calc("level")), map),
            quality = Calc.calc_object_quality(Enum.Quality.Good),
            categories = Rand.choice(Filters.fsetwear)
         }
         Itemgen.create(x, y, filter, map)
         return true
      end

      local filter = { level = 10, categories = "elona.junk_town" }
      Itemgen.create(x, y, filter, map)
      return true
   end

   return false
   -- <<<<<<<< shade2/map_func.hsp:891 	return ..
end

return MapgenUtils
