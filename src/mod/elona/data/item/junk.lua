local light = require("mod.elona.data.item.light")
local Gui = require("api.Gui")
local Rand = require("api.Rand")
local Enum = require("api.Enum")
local IItemFishingPole = require("mod.elona.api.aspect.IItemFishingPole")
local IItemBait = require("mod.elona.api.aspect.IItemBait")
local IItemChair = require("mod.elona.api.aspect.IItemChair")

--
-- Junk
--

data:add {
   _type = "base.item",
   _id = "bonfire",
   elona_id = 48,
   image = "elona.item_bonfire",
   value = 170,
   weight = 3200,
   coefficient = 100,
   categories = {
      "elona.junk"
   },
   light = light.torch_lamp
}

data:add {
   _type = "base.item",
   _id = "flag",
   elona_id = 49,
   image = "elona.item_flag",
   value = 130,
   weight = 1400,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "skeleton",
   elona_id = 52,
   image = "elona.item_skeleton",
   value = 10,
   weight = 80,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "tombstone",
   elona_id = 53,
   image = "elona.item_tombstone",
   value = 10,
   weight = 12000,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "basket",
   elona_id = 216,
   image = "elona.item_basket",
   value = 40,
   weight = 80,
   coefficient = 100,
   tags = { "fest" },
   random_color = "Furniture",
   categories = {
      "elona.tag_fest",
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "empty_bowl",
   elona_id = 217,
   image = "elona.item_empty_bowl",
   value = 25,
   weight = 90,
   coefficient = 100,
   random_color = "Furniture",
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "bowl",
   elona_id = 218,
   image = "elona.item_bowl",
   value = 30,
   weight = 80,
   coefficient = 100,
   random_color = "Furniture",
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "straw",
   elona_id = 221,
   image = "elona.item_straw",
   value = 7,
   weight = 70,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "fire_wood",
   elona_id = 273,
   image = "elona.item_fire_wood",
   value = 10,
   weight = 1500,
   coefficient = 100,
   random_color = "Furniture",
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "scarecrow",
   elona_id = 274,
   image = "elona.item_scarecrow",
   value = 10,
   weight = 4800,
   coefficient = 100,
   random_color = "Furniture",
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "broom",
   elona_id = 275,
   image = "elona.item_broom",
   value = 100,
   weight = 800,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "large_bouquet",
   elona_id = 301,
   image = "elona.item_large_bouquet",
   value = 240,
   weight = 1400,
   coefficient = 100,
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "stump",
   elona_id = 330,
   image = "elona.item_stump",
   value = 250,
   weight = 3500,
   coefficient = 100,

   _ext = {
      IItemChair
   },

   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "shit",
   elona_id = 575,
   image = "elona.item_shit",
   value = 25,
   weight = 80,
   rarity = 250000,
   coefficient = 100,
   params = { chara_id = nil },
   categories = {
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "snow_scarecrow",
   elona_id = 590,
   image = "elona.item_snow_scarecrow",
   value = 10,
   weight = 4800,
   coefficient = 100,
   random_color = "Furniture",
   categories = {
      "elona.junk"
   }
}

--
-- Junk In Field
--

data:add {
   _type = "base.item",
   _id = "broken_vase",
   elona_id = 46,
   image = "elona.item_broken_vase",
   value = 6,
   weight = 800,
   coefficient = 100,
   categories = {
      "elona.junk",
      "elona.junk_in_field"
   }
}

data:add {
   _type = "base.item",
   _id = "broken_sword",
   elona_id = 50,
   image = "elona.item_broken_sword",
   value = 10,
   weight = 1050,
   coefficient = 100,
   categories = {
      "elona.junk",
      "elona.junk_in_field"
   }
}

data:add {
   _type = "base.item",
   _id = "bone_fragment",
   elona_id = 51,
   image = "elona.item_bone_fragment",
   value = 10,
   weight = 80,
   coefficient = 100,
   categories = {
      "elona.junk",
      "elona.junk_in_field"
   }
}

data:add {
   _type = "base.item",
   _id = "ore_piece",
   elona_id = 214,
   image = "elona.item_ore_piece",
   value = 180,
   weight = 12000,
   coefficient = 100,

   random_color = "Furniture",

   categories = {
      "elona.junk",
      "elona.junk_in_field"
   }
}

data:add {
   _type = "base.item",
   _id = "animal_bone",
   elona_id = 222,
   image = "elona.item_animal_bone",
   value = 8,
   weight = 40,
   coefficient = 100,
   categories = {
      "elona.junk",
      "elona.junk_in_field"
   }
}

--
-- Junk In Town
--

data:add {
   _type = "base.item",
   _id = "washing",
   elona_id = 47,
   image = "elona.item_washing",
   value = 140,
   weight = 250,
   coefficient = 100,
   categories = {
      "elona.junk_town",
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "lot_of_empty_bottles",
   elona_id = 215,
   image = "elona.item_whisky",
   value = 10,
   weight = 220,
   coefficient = 100,
   originalnameref2 = "lot",
   random_color = "Furniture",
   categories = {
      "elona.junk_town",
      "elona.junk"
   }
}

--
-- Special
--

data:add {
   _type = "base.item",
   _id = "bait",
   elona_id = 617,
   image = "elona.item_bait_water_flea",
   value = 1000,
   weight = 250,
   fltselect = Enum.FltSelect.Sp,
   coefficient = 100,

   _ext = {
      IItemBait
   },

   categories = {
      "elona.no_generate",
      "elona.junk"
   }
}

data:add {
   _type = "base.item",
   _id = "monster_heart",
   elona_id = 663,
   image = "elona.item_monster_heart",
   value = 25000,
   weight = 2500,
   fltselect = Enum.FltSelect.SpUnique,
   rarity = 800000,
   coefficient = 100,

   is_precious = true,
   quality = Enum.Quality.Unique,
   categories = {
      "elona.unique_item",
      "elona.junk"
   },
   light = light.item
}
