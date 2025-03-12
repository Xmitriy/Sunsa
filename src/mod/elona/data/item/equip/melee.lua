local Enum = require("api.Enum")
local light = require("mod.elona.data.item.light")
local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local IItemMeleeWeapon = require("mod.elona.api.aspect.IItemMeleeWeapon")

--
-- Broadsword
--

data:add {
   _type = "base.item",
   _id = "claymore",
   elona_id = 232,
   image = "elona.item_claymore",
   value = 500,
   weight = 4000,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_broadsword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 1,
         damage_bonus = 8,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 3,
         dice_y = 7,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "claymore_unique",
   elona_id = 719,
   image = "elona.item_claymore_unique",
   value = 45000,
   weight = 6500,
   material = "elona.silver",
   level = 45,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   categories = {
      "elona.equip_melee_broadsword",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.crit", power = 250 },
      { _id = "elona.pierce", power = 200 },
      { _id = "elona.res_mutation", power = 100 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 1,
         damage_bonus = 16,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 3,
         dice_y = 14,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "dragon_slayer",
   elona_id = 791,
   image = "elona.item_dragon_slayer",
   value = 72000,
   weight = 22500,
   material = "elona.iron",
   level = 55,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   categories = {
      "elona.equip_melee_broadsword",
      "elona.unique_item",
      "elona.equip_melee"
   },

   enchantments = {
      { _id = "elona.dragon_bane", power = 300 },
      { _id = "elona.god_bane", power = 200 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -25,
         damage_bonus = 20,
         pv = 30,
         dv = -42,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 3,
         dice_y = 14,
      }
   }
}

--
-- Long Sword
--

data:add {
   _type = "base.item",
   _id = "long_sword",
   elona_id = 1,
   image = "elona.item_long_sword",
   value = 500,
   weight = 1500,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_long_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 5,
         damage_bonus = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 2,
         dice_y = 8,
         pierce_rate = 5,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "diablo",
   elona_id = 56,
   image = "elona.item_long_sword",
   value = 40000,
   weight = 2200,
   material = "elona.steel",
   level = 40,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 155, 154, 153 },

   medal_value = 65,
   categories = {
      "elona.equip_melee_long_sword",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.stop_time", power = 300 },
      { _id = "elona.elemental_damage", power = 400, params = { element_id = "elona.nerve" } },
      { _id = "elona.modify_attribute", power = 300, params = { skill_id = "elona.stat_speed" } },
      { _id = "elona.res_paralyze", power = 100 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 2,
         damage_bonus = 8,
         dv = -3,
         pv = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 4,
         dice_y = 8,
         pierce_rate = 10,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "zantetsu",
   elona_id = 57,
   image = "elona.item_zantetsu",
   value = 40000,
   weight = 1400,
   material = "elona.silver",
   level = 30,
   fltselect = Enum.FltSelect.Unique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 175, 175, 255 },

   categories = {
      "elona.equip_melee_long_sword",
      "elona.unique_weapon",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.pierce", power = 400 },
      { _id = "elona.res_confuse", power = 100 },
      { _id = "elona.modify_attribute", power = 300, params = { skill_id = "elona.stat_strength" } },
      { _id = "elona.modify_resistance", power = 200, params = { element_id = "elona.nerve" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 7,
         dice_y = 7,
         pierce_rate = 25,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "mournblade",
   elona_id = 64,
   image = "elona.item_long_sword",
   value = 60000,
   weight = 4000,
   material = "elona.obsidian",
   level = 50,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 175, 175, 255 },

   categories = {
      "elona.equip_melee_long_sword",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.absorb_stamina", power = 300 },
      { _id = "elona.elemental_damage", power = 300, params = { element_id = "elona.chaos" } },
      { _id = "elona.elemental_damage", power = 250, params = { element_id = "elona.nether" } },
      { _id = "elona.modify_skill", power = 300, params = { skill_id = "elona.dual_wield" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.chaos" } },
      { _id = "elona.modify_resistance", power = 200, params = { element_id = "elona.nether" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 8,
         damage_bonus = 5,
         dv = -4,
         pv = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 3,
         dice_y = 13,
         pierce_rate = 15,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "ragnarok",
   elona_id = 73,
   image = "elona.item_long_sword",
   value = 20000,
   weight = 4200,
   material = "elona.obsidian",
   level = 30,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 155, 154, 153 },
   categories = {
      "elona.equip_melee_long_sword",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.ragnarok", power = 100 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 4,
         damage_bonus = 3,
         dv = -1,
         pv = 1,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 2,
         dice_y = 18,
         pierce_rate = 20,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "katana",
   elona_id = 224,
   image = "elona.item_katana",
   value = 500,
   weight = 1200,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_long_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         damage_bonus = 6,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 4,
         dice_y = 4,
         pierce_rate = 20,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "hiryu_to",
   elona_id = 741,
   image = "elona.item_zantetsu",
   value = 40000,
   weight = 2500,
   material = "elona.obsidian",
   level = 25,
   fltselect = Enum.FltSelect.Unique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 155, 155 },

   categories = {
      "elona.equip_melee_long_sword",
      "elona.unique_weapon",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.modify_resistance", power = 550, params = { element_id = "elona.fire" } },
      { _id = "elona.elemental_damage", power = 400, params = { element_id = "elona.lightning" } },
      { _id = "elona.dragon_bane", power = 1150 },
      { _id = "elona.modify_attribute", power = 720, params = { skill_id = "elona.stat_constitution" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 3,
         damage_bonus = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 6,
         dice_y = 6,
         pierce_rate = 20,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "lightsabre",
   elona_id = 759,
   image = "elona.item_lightsabre",
   value = 4800,
   weight = 600,
   material = "elona.ether",
   rarity = 2000,
   coefficient = 100,
   random_color = "Furniture",

   categories = {
      "elona.equip_melee_long_sword",
      "elona.equip_melee"
   },
   light = light.item,

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
      },
      [IItemMeleeWeapon] = {
         skill = "elona.long_sword",
         dice_x = 2,
         dice_y = 5,
         pierce_rate = 100,
      }
   }
}

--
-- Short Sword
--

data:add {
   _type = "base.item",
   _id = "dagger",
   elona_id = 2,
   image = "elona.item_dagger",
   value = 500,
   weight = 600,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_short_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 9,
         damage_bonus = 4,
         dv = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 2,
         dice_y = 5,
         pierce_rate = 10,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "ether_dagger",
   elona_id = 206,
   image = "elona.item_dagger",
   value = 60000,
   weight = 600,
   material = "elona.ether",
   level = 40,
   fltselect = Enum.FltSelect.Unique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 175, 175, 255 },
   categories = {
      "elona.equip_melee_short_sword",
      "elona.unique_weapon",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.invoke_skill", power = 200, params = { enchantment_skill_id = "elona.element_scar" } },
      { _id = "elona.elemental_damage", power = 300, params = { element_id = "elona.lightning" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.lightning" } },
      { _id = "elona.modify_skill", power = 350, params = { skill_id = "elona.casting" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 16,
         damage_bonus = 8,
         dv = 4,
         pv = 6,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 5,
         dice_y = 5,
         pierce_rate = 20,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "scimitar",
   elona_id = 225,
   image = "elona.item_scimitar",
   value = 500,
   weight = 900,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_short_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 7,
         damage_bonus = 3,
         dv = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 3,
         dice_y = 4,
         pierce_rate = 10,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "wakizashi",
   elona_id = 266,
   image = "elona.item_wakizashi",
   value = 500,
   weight = 700,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_short_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 6,
         damage_bonus = 5,
         dv = 1,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 4,
         dice_y = 4,
         pierce_rate = 5,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "lucky_dagger",
   elona_id = 678,
   image = "elona.item_dagger",
   value = 35000,
   weight = 400,
   material = "elona.mica",
   level = 60,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 215, 175 },

   categories = {
      "elona.equip_melee_short_sword",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.res_steal", power = 100 },
      { _id = "elona.see_invisi", power = 100 },
      { _id = "elona.modify_attribute", power = 1500, params = { skill_id = "elona.stat_luck" } },
      { _id = "elona.absorb_stamina", power = 400 },
      { _id = "elona.modify_skill", power = 600, params = { skill_id = "elona.fishing" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         dv = 18,
         pv = 13,
         hit_bonus = 13,
         damage_bonus = 18,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 4,
         dice_y = 6,
         pierce_rate = 10,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "kitchen_knife",
   elona_id = 781,
   image = "elona.item_kitchen_knife",
   value = 2400,
   weight = 400,
   material = "elona.metal",
   rarity = 50000,
   coefficient = 100,

   categories = {
      "elona.equip_melee_short_sword",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 5,
         damage_bonus = 1,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.short_sword",
         dice_x = 1,
         dice_y = 14,
         pierce_rate = 40,
      }
   }
}

--
-- Club
--

data:add {
   _type = "base.item",
   _id = "club",
   elona_id = 4,
   image = "elona.item_club",
   value = 500,
   weight = 1000,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_club",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 4,
         damage_bonus = 7,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.blunt",
         dice_x = 3,
         dice_y = 4,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "blood_moon",
   elona_id = 356,
   image = "elona.item_club",
   value = 30000,
   weight = 1800,
   material = "elona.iron",
   level = 30,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 155, 155 },

   categories = {
      "elona.equip_melee_club",
      "elona.unique_item",
      "elona.equip_melee"
   },

   light = light.item,

   enchantments = {
      { _id = "elona.absorb_mana", power = 300 },
      { _id = "elona.modify_resistance", power = 200, params = { element_id = "elona.fire" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.nether" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.fire" } },
      { _id = "elona.res_confuse", power = 100 },
      { _id = "elona.res_fear", power = 100 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 8,
         damage_bonus = 22,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.blunt",
         dice_x = 3,
         dice_y = 5,
      }
   }
}

--
-- Hammer
--

data:add {
   _type = "base.item",
   _id = "hammer",
   elona_id = 227,
   image = "elona.item_hammer",
   value = 500,
   weight = 4200,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_hammer",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -3,
         damage_bonus = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.blunt",
         dice_x = 2,
         dice_y = 13,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "gaia_hammer",
   elona_id = 679,
   image = "elona.item_hammer",
   value = 35000,
   weight = 6500,
   material = "elona.adamantium",
   level = 60,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 215, 175 },

   categories = {
      "elona.equip_melee_hammer",
      "elona.unique_item",
      "elona.equip_melee"
   },

   light = light.item,

   enchantments = {
      { _id = "elona.pierce", power = 350 },
      { _id = "elona.invoke_skill", power = 500, params = { enchantment_skill_id = "elona.hero" } },
      { _id = "elona.modify_attribute", power = 600, params = { skill_id = "elona.stat_strength" } },
      { _id = "elona.modify_skill", power = 450, params = { skill_id = "elona.two_hand" } },
      { _id = "elona.modify_resistance", power = 400, params = { element_id = "elona.mind" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         damage_bonus = 2,
         hit_bonus = -3,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.blunt",
         dice_x = 2,
         dice_y = 30,
      }
   }
}

--
-- Staff
--

data:add {
   _type = "base.item",
   _id = "staff",
   elona_id = 212,
   image = "elona.item_staff",
   value = 500,
   weight = 900,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_staff",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 4,
         damage_bonus = 3,
         dv = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.stave",
         dice_x = 1,
         dice_y = 8,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "long_staff",
   elona_id = 229,
   image = "elona.item_long_staff",
   value = 500,
   weight = 800,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_staff",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 3,
         damage_bonus = 4,
         dv = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.stave",
         dice_x = 2,
         dice_y = 5,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "staff_of_insanity",
   elona_id = 358,
   image = "elona.item_staff",
   value = 30000,
   weight = 2500,
   material = "elona.obsidian",
   level = 35,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,
   categories = {
      "elona.equip_melee_staff",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.invoke_skill", power = 400, params = { enchantment_skill_id = "elona.nightmare" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.mind" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.nerve" } },
      { _id = "elona.modify_attribute", power = 450, params = { skill_id = "elona.stat_magic" } },
      { _id = "elona.power_magic", power = 350 },
      { _id = "elona.modify_skill", power = 420, params = { skill_id = "elona.casting" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         dv = 15,
         pv = 3,
         hit_bonus = -5,
         damage_bonus = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.stave",
         dice_x = 1,
         dice_y = 8,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "elemental_staff",
   elona_id = 676,
   image = "elona.item_staff",
   value = 35000,
   weight = 900,
   material = "elona.obsidian",
   level = 60,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 215, 255, 215 },

   categories = {
      "elona.equip_melee_staff",
      "elona.unique_item",
      "elona.equip_melee"
   },

   light = light.item,

   enchantments = {
      { _id = "elona.invoke_skill", power = 400, params = { enchantment_skill_id = "elona.element_scar" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.fire" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.cold" } },
      { _id = "elona.elemental_damage", power = 350, params = { element_id = "elona.lightning" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.fire" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.cold" } },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.lightning" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         dv = 11,
         pv = 4,
         hit_bonus = 6,
         damage_bonus = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.stave",
         dice_x = 1,
         dice_y = 14,
      }
   }
}

--
-- Lance
--

data:add {
   _type = "base.item",
   _id = "spear",
   elona_id = 213,
   image = "elona.item_spear",
   value = 500,
   weight = 2500,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_lance",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 2,
         damage_bonus = 4,
         dv = 3,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.polearm",
         dice_x = 3,
         dice_y = 5,
         pierce_rate = 25,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "trident",
   elona_id = 228,
   image = "elona.item_trident",
   value = 500,
   weight = 1800,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_lance",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 1,
         damage_bonus = 3,
         dv = 3,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.polearm",
         dice_x = 4,
         dice_y = 4,
         pierce_rate = 25,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "rankis",
   elona_id = 359,
   image = "elona.item_halberd",
   value = 30000,
   weight = 2000,
   material = "elona.iron",
   level = 35,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 155, 155 },

   categories = {
      "elona.equip_melee_lance",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.stop_time", power = 400 },
      { _id = "elona.elemental_damage", power = 400, params = { element_id = "elona.nether" } },
      { _id = "elona.modify_resistance", power = 300, params = { element_id = "elona.nether" } },
      { _id = "elona.res_fear", power = 100 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 2,
         damage_bonus = 11,
         dv = 6,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.polearm",
         dice_x = 8,
         dice_y = 4,
         pierce_rate = 40,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "holy_lance",
   elona_id = 677,
   image = "elona.item_holy_lance",
   value = 35000,
   weight = 4400,
   material = "elona.silver",
   level = 60,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   categories = {
      "elona.equip_melee_lance",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.invoke_skill", power = 350, params = { enchantment_skill_id = "elona.healing_rain" } },
      { _id = "elona.invoke_skill", power = 450, params = { enchantment_skill_id = "elona.holy_veil" } },
      { _id = "elona.modify_attribute", power = 650, params = { skill_id = "elona.stat_will" } },
      { _id = "elona.modify_resistance", power = 200, params = { element_id = "elona.darkness" } },
      { _id = "elona.modify_resistance", power = 150, params = { element_id = "elona.nether" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 12,
         damage_bonus = 11,
         dv = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.polearm",
         dice_x = 7,
         dice_y = 5,
         pierce_rate = 30,
      }
   }
}

--
-- Halberd
--

data:add {
   _type = "base.item",
   _id = "halberd",
   elona_id = 235,
   image = "elona.item_halberd",
   value = 500,
   weight = 3800,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_halberd",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -2,
         damage_bonus = 1,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.polearm",
         dice_x = 2,
         dice_y = 10,
         pierce_rate = 30,
      }
   }
}

--
-- Hand Axe
--

data:add {
   _type = "base.item",
   _id = "hand_axe",
   elona_id = 3,
   image = "elona.item_hand_axe",
   value = 500,
   weight = 900,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_hand_axe",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 4,
         damage_bonus = 5,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.axe",
         dice_x = 2,
         dice_y = 9,
      }
   }
}

--
-- Axe
--

data:add {
   _type = "base.item",
   _id = "battle_axe",
   elona_id = 226,
   image = "elona.item_battle_axe",
   value = 500,
   weight = 3700,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_axe",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -1,
         damage_bonus = 3,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.axe",
         dice_x = 1,
         dice_y = 18,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "bardiche",
   elona_id = 234,
   image = "elona.item_bardiche",
   value = 500,
   weight = 3500,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_axe",
      "elona.equip_melee"
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -1,
         damage_bonus = 5,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.axe",
         dice_x = 1,
         dice_y = 20,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "axe_of_destruction",
   elona_id = 695,
   image = "elona.item_bardiche",
   value = 50000,
   weight = 14000,
   material = "elona.rubynus",
   level = 30,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 155, 155 },

   categories = {
      "elona.equip_melee_axe",
      "elona.unique_item",
      "elona.equip_melee"
   },

   light = light.item,

   enchantments = {
      { _id = "elona.crit", power = 750 },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -35,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.axe",
         dice_x = 1,
         dice_y = 70,
      }
   }
}

--
-- Scythe
--

data:add {
   _type = "base.item",
   _id = "scythe_of_void",
   elona_id = 63,
   image = "elona.item_scythe",
   value = 50000,
   weight = 9000,
   material = "elona.iron",
   level = 35,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 255, 155, 155 },

   categories = {
      "elona.equip_melee_scythe",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.float", power = 100 },
      { _id = "elona.absorb_mana", power = 500 },
      { _id = "elona.power_magic", power = 450 },
      { _id = "elona.modify_resistance", power = 250, params = { element_id = "elona.magic" } },
      { _id = "elona.invoke_skill", power = 100, params = { enchantment_skill_id = "elona.decapitation" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         damage_bonus = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.scythe",
         dice_x = 1,
         dice_y = 44,
         pierce_rate = 15,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "sickle",
   elona_id = 211,
   image = "elona.item_scythe",
   value = 500,
   weight = 1400,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_scythe",
      "elona.equip_melee"
   },

   enchantments = {
      { _id = "elona.invoke_skill", power = 100, params = { enchantment_skill_id = "elona.decapitation" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 2,
         damage_bonus = 10,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.scythe",
         dice_x = 2,
         dice_y = 5,
         pierce_rate = 5,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "kumiromi_scythe",
   elona_id = 675,
   image = "elona.item_scythe",
   value = 35000,
   weight = 850,
   material = "elona.spirit_cloth",
   level = 60,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,

   color = { 175, 255, 175 },

   categories = {
      "elona.equip_melee_scythe",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.modify_skill", power = 600, params = { skill_id = "elona.cooking" } },
      { _id = "elona.eater", power = 100 },
      { _id = "elona.modify_skill", power = 1100, params = { skill_id = "elona.gardening" } },
      { _id = "elona.modify_skill", power = 800, params = { skill_id = "elona.mining" } },
      { _id = "elona.modify_attribute", power = 550, params = { skill_id = "elona.stat_strength" } },
      { _id = "elona.modify_resistance", power = 400, params = { element_id = "elona.chaos" } },
      { _id = "elona.invoke_skill", power = 100, params = { enchantment_skill_id = "elona.decapitation" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 5,
         damage_bonus = 2,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.scythe",
         dice_x = 1,
         dice_y = 38,
         pierce_rate = 15,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "scythe",
   elona_id = 735,
   image = "elona.item_scythe",
   value = 500,
   weight = 4000,
   material = "elona.metal",
   coefficient = 100,

   categories = {
      "elona.equip_melee_scythe",
      "elona.equip_melee"
   },

   enchantments = {
      { _id = "elona.invoke_skill", power = 100, params = { enchantment_skill_id = "elona.decapitation" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = 3,
         damage_bonus = 4,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.scythe",
         dice_x = 1,
         dice_y = 17,
         pierce_rate = 5,
      }
   }
}

data:add {
   _type = "base.item",
   _id = "frisias_tail",
   elona_id = 739,
   image = "elona.item_staff",
   value = 30000,
   weight = 376500,
   material = "elona.ether",
   level = 99,
   fltselect = Enum.FltSelect.SpUnique,
   coefficient = 100,

   is_precious = true,
   identify_difficulty = 500,
   quality = Enum.Quality.Unique,
   categories = {
      "elona.equip_melee_scythe",
      "elona.unique_item",
      "elona.equip_melee"
   },
   light = light.item,

   enchantments = {
      { _id = "elona.invoke_skill", power = 400, params = { enchantment_skill_id = "elona.nightmare" } },
      { _id = "elona.elemental_damage", power = 850, params = { element_id = "elona.mind" } },
      { _id = "elona.modify_attribute", power = 34500, params = { skill_id = "elona.stat_magic" } },
      { _id = "elona.invoke_skill", power = 100, params = { enchantment_skill_id = "elona.decapitation" } },
      { _id = "elona.ragnarok", power = 100 },
      { _id = "elona.invoke_skill", power = 350, params = { enchantment_skill_id = "elona.raging_roar" } },
   },

   _ext = {
      [IItemEquipment] = {
         equip_slots = { "elona.hand" },
         hit_bonus = -460,
         damage_bonus = 32,
      },
      [IItemMeleeWeapon] = {
         skill = "elona.scythe",
         dice_x = 25,
         dice_y = 16,
         pierce_rate = 65,
      }
   }
}
