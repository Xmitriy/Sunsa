local Rand = require("api.Rand")
local Itemgen = require("mod.elona.api.Itemgen")
local I18N = require("api.I18N")
local InstancedMap = require("api.InstancedMap")

data:add_type {
   name = "field_type",
   fields = {
      {
         name = "default_tile",
         type = types.data_id("base.map_tile")
      },
      {
         name = "fog",
         type = types.data_id("base.map_tile")
      },
      {
         name = "tiles",
         type = types.list(types.fields_strict { id = types.data_id("base.map_tile"), density = types.number }),
         default = {}
      },
      {
         name = "generate",
         type = types.optional(types.callback("self", types.data_entry("elona.field_type"), "map", types.class(InstancedMap)))
      },
      {
         name = "material_spot_type",
         type = types.optional(types.data_id("elona.material_spot"))
      }
   }
}

local function create_junk_items(map)
   local stood_map_tile = true
   if stood_map_tile then
      for _=1,4+Rand.rnd(5) do
         Itemgen.create(nil, nil, {categories={"elona.junk_in_field"}}, map)
      end
   end
end

data:add_multi(
   "elona.field_type",
   {
      {
         _id = "plains",

         default_tile = "elona.grass",
         fog = "elona.wall_stone_1_fog",

         tiles = {
            { id = "elona.grass_violets", density = 10 },
            { id = "elona.grass_rocks", density = 2 },
            { id = "elona.grass_tall_1", density = 2 },
            { id = "elona.grass_tall_2", density = 2 },
            { id = "elona.grass_patch_1", density = 2 },
            { id = "elona.grass_patch_2", density = 2 }
         },

         generate = function(self, map)
            map.name = I18N.get("map.unique.elona.fields.plain_field")

            create_junk_items(map)
         end
      },
      {
         _id = "forest",

         default_tile = "elona.grass_bush_1",
         fog = "elona.wall_stone_1_fog",

         tiles = {
            { id = "elona.grass_bush_2", density = 25 },
            { id = "elona.grass", density = 10 },
            { id = "elona.grass_violets", density = 4 },
            { id = "elona.grass_tall_2", density = 2 },
         },

         material_spot_type = "elona.forest",

         generate = function(self, map)
            map.name = I18N.get("map.unique.elona.fields.forest")

            create_junk_items(map)
         end
      },
      {
         _id = "sea",

         default_tile = "elona.cracked_dirt_1",
         fog = "elona.wall_stone_1_fog",
         material_spot_type = "elona.forest",

         generate = function(self, map)
            map.name = I18N.get("map.unique.elona.fields.sea")
         end
      },
      {
         _id = "grassland",

         default_tile = "elona.grass_tall_1",
         fog = "elona.wall_stone_1_fog",

         tiles = {
            { id = "elona.grass_bush_3", density = 10 },
            { id = "elona.grass_patch_3", density = 10 },
            { id = "elona.grass", density = 30 },
            { id = "elona.grass_violets", density = 4 },
            { id = "elona.grass_tall_2", density = 2 },
            { id = "elona.grass_tall_1", density = 2 },
            { id = "elona.grass_tall_2", density = 2 },
            { id = "elona.grass_patch_1", density = 2 },
         },

         material_spot_type = "elona.field",

         generate = function(self, map)
            map.name = I18N.get("map.unique.elona.fields.grassland")

            create_junk_items(map)
         end
      },
      {
         _id = "desert",

         default_tile = "elona.desert",
         fog = "elona.wall_stone_4_fog",

         tiles = {
            { id = "elona.desert_rocks_3", density = 25 },
            { id = "elona.desert_rocks_2", density = 10 },
            { id = "elona.desert", density = 2 },
            { id = "elona.desert_flowers_1", density = 4 },
            { id = "elona.desert_flowers_2", density = 2 },
         },

         material_spot_type = "elona.field",

         generate = function(self, map)
            map.name = "desert"

            create_junk_items(map)
         end
      },
      {
         _id = "snow_field",

         default_tile = "elona.snow",
         fog = "elona.wall_stone_5_fog",

         tiles = {
            { id = "elona.snow_clumps_2", density = 4 },
            { id = "elona.snow_clumps_1", density = 4 },
            { id = "elona.snow_stump", density = 2 },
            { id = "elona.snow_mound", density = 1 },
            { id = "elona.snow_plants", density = 1 },
            { id = "elona.snow_rock", density = 1 },
            { id = "elona.snow_flowers_2", density = 1 },
         },

         generate = function(self, map)
            map.name = I18N.get("map.unique.elona.fields.snow_field")

            create_junk_items(map)
         end
      },
   }
)
