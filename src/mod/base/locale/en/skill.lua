return {
   skill = {
      gained = function(_1)
         return ("You have learned new ability, %s.")
            :format(_1)
      end,

      default = {
         on_decrease = function(_1, _2)
            return ("%s%s %s skill falls off.")
               :format(name(_1), his_owned(_1), _2)
         end,
         on_increase = function(_1, _2)
            return ("%s%s %s skill increases.")
               :format(name(_1), his_owned(_1), _2)
         end
      },

      _ = {
         elona = {
            stat_strength = {
               name = "Strength",
               short_name = " STR",

               on_decrease = function(_1)
                  return ("%s%s muscles soften.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s muscles feel stronger.")
                     :format(name(_1), his_owned(_1))
               end
            },
            stat_constitution = {
               name = "Constitution",
               short_name = " CON",

               on_decrease = function(_1)
                  return ("%s lose%s patience.")
                     :format(name(_1), s(_1))
               end,
               on_increase = function(_1)
                  return ("%s begin%s to feel good when being hit hard.")
                     :format(name(_1), s(_1))
               end
            },
            stat_dexterity = {
               name = "Dexterity",
               short_name = " DEX",

               on_decrease = function(_1)
                  return ("%s become%s clumsy.")
                     :format(name(_1), s(_1))
               end,
               on_increase = function(_1)
                  return ("%s become%s dexterous.")
                     :format(name(_1), s(_1))
               end
            },
            stat_perception = {
               name = "Perception",
               short_name = " PER",

               on_decrease = function(_1)
                  return ("%s %s getting out of touch with the world.")
                     :format(name(_1), is(_1))
               end,
               on_increase = function(_1)
                  return ("%s feel%s more in touch with the world.")
                     :format(name(_1), s(_1))
               end
            },
            stat_learning = {
               name = "Learning",
               short_name = " LER",

               on_decrease = function(_1)
                  return ("%s lose%s curiosity.")
                     :format(name(_1), s(_1))
               end,
               on_increase = function(_1)
                  return ("%s feel%s studious.")
                     :format(name(_1), s(_1))
               end
            },
            stat_will = {
               name = "Will",
               short_name = " WIL",

               on_decrease = function(_1)
                  return ("%s%s will softens.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s will hardens.")
                     :format(name(_1), his_owned(_1))
               end
            },
            stat_magic = {
               name = "Magic",
               short_name = " MAG",

               on_decrease = function(_1)
                  return ("%s%s magic degrades.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s magic improves.")
                     :format(name(_1), his_owned(_1))
               end
            },
            stat_charisma = {
               name = "Charisma",
               short_name = " CHR",

               on_decrease = function(_1)
                  return ("%s start%s to avoid eyes of people.")
                     :format(name(_1), s(_1))
               end,
               on_increase = function(_1)
                  return ("%s enjoy%s showing off %s body.")
                     :format(name(_1), s(_1), his(_1))
               end
            },
            stat_speed = {
               name = "Speed",

               on_decrease = function(_1)
                  return ("%s%s speed decreases.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s speed increases.")
                     :format(name(_1), his_owned(_1))
               end
            },
            stat_luck = {
               name = "Luck",

               on_decrease = function(_1)
                  return ("%s become%s unlucky.")
                     :format(name(_1), s(_1))
               end,
               on_increase = function(_1)
                  return ("%s become%s lucky.")
                     :format(name(_1), s(_1))
               end
            },
            stat_life = {
               name = "Life",

               on_decrease = function(_1)
                  return ("%s%s life force decreases.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s life force increases.")
                     :format(name(_1), his_owned(_1))
               end
            },
            stat_mana = {
               name = "Mana",

               on_decrease = function(_1)
                  return ("%s%s mana decreases.")
                     :format(name(_1), his_owned(_1))
               end,
               on_increase = function(_1)
                  return ("%s%s mana increases.")
                     :format(name(_1), his_owned(_1))
               end
            },

            action_absorb_magic = {
               description = "Heal MP",
               name = "Absorb Magic"
            },
            spell_acid_ground = {
               description = "Create acid grounds",
               name = "Acid Ground"
            },
            alchemy = {
               description = "Enables you to perform alchemy.",
               name = "Alchemy"
            },
            anatomy = {
               description = "Gives you a better chance of finding dead bodies.",
               name = "Anatomy"
            },
            axe = {
               description = "Indicates your skill with axes.",
               name = "Axe"
            },
            blunt = {
               description = "Indicates your skill with blunt weapons.",
               name = "Blunt"
            },
            buff_boost = {
               name = "Boost"
            },
            bow = {
               description = "Indicates your skill with bows.",
               name = "Bow"
            },
            carpentry = {
               description = "Skill to cut trees and manufcture products.",
               name = "Carpentry"
            },
            casting = {
               description = "Reduces the chance of casting failure.",
               name = "Casting"
            },
            action_change = {
               description = "Change target",
               name = "Change"
            },
            spell_chaos_ball = {
               description = "Surround(Chaos)",
               name = "Chaos Ball"
            },
            action_chaos_breath = {
               description = "Breath(Chaos)",
               name = "Chaos Breath"
            },
            spell_chaos_eye = {
               description = "Target(Chaos)",
               name = "Chaos eye"
            },
            action_cheer = {
               description = "Strengthen allies",
               name = "Cheer"
            },
            action_cold_breath = {
               description = "Breath(Cold)",
               name = "Cold Breath"
            },
            buff_contingency = {
               name = "Contingency"
            },
            control_magic = {
               description = "Prevents your allies to get hit by your spells.",
               name = "Control Magic"
            },
            cooking = {
               description = "Improves your cooking skill.",
               name = "Cooking"
            },
            crossbow = {
               description = "Indicates your skill with cross bows",
               name = "Crossbow"
            },
            spell_crystal_spear = {
               description = "Target(Magic)",
               name = "Crystal Spear"
            },
            spell_cure_of_eris = {
               description = "Heal self",
               name = "Cure of Eris"
            },
            spell_cure_of_jure = {
               description = "Heal self",
               name = "Cure of Jure"
            },
            action_curse = {
               description = "Curse target",
               name = "Curse"
            },
            spell_dark_eye = {
               description = "Target(Darkness)",
               name = "Dark eye"
            },
            spell_darkness_bolt = {
               description = "Line(Darkness)",
               name = "Darkness Bolt"
            },
            action_darkness_breath = {
               description = "Breath(Darkness)",
               name = "Darkness Breath"
            },
            buff_death_word = {
               name = "Death Word"
            },
            action_decapitation = {
               description = "Kill target",
               name = "Decapitation"
            },
            detection = {
               description = "It is used to search hidden locations and traps.",
               name = "Detection"
            },
            action_dimensional_move = {
               description = "Teleport self",
               name = "Dimensional Move"
            },
            disarm_trap = {
               description = "Allows you to disarm harder traps.",
               name = "Disarm Trap"
            },
            action_distant_attack_4 = {
               name = "Distant Attack"
            },
            action_distant_attack_7 = {
               name = "Distant Attack"
            },
            buff_divine_wisdom = {
               name = "Divine Wisdom"
            },
            spell_dominate = {
               description = "Dominate target",
               name = "Dominate"
            },
            spell_door_creation = {
               description = "Create doors",
               name = "Door Creation"
            },
            action_drain_blood = {
               description = "Drain HP",
               name = "Drain Blood"
            },
            action_draw_charge = {
               description = "Draw charges",
               name = "Draw Charge"
            },
            action_draw_shadow = {
               description = "Draw target",
               name = "Draw Shadow"
            },
            action_drop_mine = {
               description = "Set Mine",
               name = "Drop Mine"
            },
            dual_wield = {
               description = "Used when wielding two weapoms at the same time.",
               name = "Dual Wield"
            },
            buff_element_scar = {
               name = "Element Scar"
            },
            buff_elemental_shield = {
               name = "Elemental Shield"
            },
            action_ether_ground = {
               description = "Create ether grounds",
               name = "Ether Ground"
            },
            evasion = {
               description = "Increases your chance of evading enemy attacks.",
               name = "Evasion"
            },
            action_eye_of_dimness = {
               description = "Dim target",
               name = "Eye of dimness"
            },
            action_eye_of_ether = {
               description = "Corrupt target",
               name = "Eye of Ether"
            },
            action_eye_of_insanity = {
               description = "Craze target",
               name = "Eye of Insanity"
            },
            action_eye_of_mana = {
               description = "Damage MP target",
               name = "Eye of Mana"
            },
            eye_of_mind = {
               description = "Increases your chance to deliver critical hits.",
               name = "Eye of Mind"
            },
            action_eye_of_mutation = {
               description = "Mutate target",
               name = "Eye of Mutation"
            },
            faith = {
               description = "Gets you closer to god.",
               enchantment_description = "makes you pious.",
               name = "Faith"
            },
            action_fill_charge = {
               description = "Restore charges",
               name = "Fill Charge"
            },
            spell_fire_ball = {
               description = "Surround(Fire)",
               name = "Fire Ball"
            },
            spell_fire_bolt = {
               description = "Line(Fire)",
               name = "Fire Bolt"
            },
            action_fire_breath = {
               description = "Breath(Fire)",
               name = "Fire Breath"
            },
            spell_fire_wall = {
               description = "Create fire grounds",
               name = "Fire Wall"
            },
            firearm = {
               description = "Indicates your skill with firearms.",
               name = "Firearm"
            },
            fishing = {
               description = "Displays your fishing skill.",
               enchantment_description = "makes you better fisher.",
               name = "Fishing"
            },
            spell_four_dimensional_pocket = {
               description = "Summon 4-Dimensional Pocket",
               name = "4-Dimensional Pocket"
            },
            gardening = {
               description = "Skill to plant seeds and gather harvests.",
               name = "Gardening"
            },
            gene_engineer = {
               description = "Allows you to control genes.",
               name = "Gene Engineer"
            },
            spell_gravity = {
               description = "Create gravity",
               name = "Gravity"
            },
            greater_evasion = {
               description = "Makes you able to evade inaccurate attacks.",
               name = "Greater Evasion"
            },
            action_grenade = {
               description = "Surround(Sound)",
               name = "Grenade"
            },
            action_harvest_mana = {
               description = "Restore MP",
               name = "Harvest Mana"
            },
            spell_heal_critical = {
               description = "Heal self",
               name = "Heal Critical"
            },
            spell_heal_light = {
               description = "Heal self",
               name = "Heal Light"
            },
            healing = {
               description = "Gradually heals your wounds.",
               name = "Healing"
            },
            spell_healing_rain = {
               description = "Heal area",
               name = "Healing Rain"
            },
            spell_healing_touch = {
               description = "Heal target",
               name = "Healing Touch"
            },
            heavy_armor = {
               description = "Skill to effectively act while wearing heavy armor.",
               name = "Heavy Armor"
            },
            buff_hero = {
               name = "Hero"
            },
            spell_holy_light = {
               description = "Remove one hex",
               name = "Holy Light"
            },
            buff_holy_shield = {
               name = "Holy Shield"
            },
            buff_holy_veil = {
               name = "Holy Veil"
            },
            spell_ice_ball = {
               description = "Surround(Cold)",
               name = "Ice Ball"
            },
            spell_ice_bolt = {
               description = "Line(Cold)",
               name = "Ice Bolt"
            },
            spell_identify = {
               description = "Identify one item",
               name = "Identify"
            },
            buff_incognito = {
               name = "Incognito"
            },
            action_insult = {
               description = "Insult target",
               name = "Insult"
            },
            investing = {
               description = "Lowers the money needed to invest in shops.",
               name = "Investing"
            },
            jeweler = {
               description = "Skill to process jewels and manufucture products.",
               name = "Jeweler"
            },
            light_armor = {
               description = "Skill to effectively act while wearing light armor.",
               name = "Light Armor"
            },
            spell_lightning_bolt = {
               description = "Line(Lightning)",
               name = "Lightning Bolt"
            },
            action_lightning_breath = {
               description = "Breath(Lightning)",
               name = "Lightning Breath"
            },
            literacy = {
               description = "Allows you to read difficult books.",
               enchantment_description = "makes you literate.",
               name = "Literacy"
            },
            lock_picking = {
               description = "Allows you to pick more difficult locks.",
               name = "Lock Picking"
            },
            long_sword = {
               description = "Indicates your skill with long swords.",
               name = "Long Sword"
            },
            buff_lulwys_trick = {
               name = "Lulwy's Trick"
            },
            magic_capacity = {
               description = "Reduces kickback damage from over casting.",
               name = "Magic Capacity"
            },
            spell_magic_dart = {
               description = "Target(Magic)",
               name = "Magic Dart"
            },
            magic_device = {
               description = "Improves effectiveness of magic devices.",
               name = "Magic Device"
            },
            spell_magic_map = {
               description = "Reveal surround map",
               name = "Magic Map"
            },
            spell_magic_storm = {
               description = "Surround(Magic)",
               name = "Magic Storm"
            },
            action_manis_disassembly = {
               description = "Almost kill target",
               name = "Mani's Disassembly"
            },
            marksman = {
               description = "Increases shooting damage.",
               name = "Marksman"
            },
            martial_arts = {
               description = "Indicates your skill fighting unarmed.",
               name = "Martial Arts"
            },
            meditation = {
               description = "Gradually restores your magic points.",
               enchantment_description = "enhances your meditation.",
               name = "Meditation"
            },
            medium_armor = {
               description = "Skill to effectively act while wearing medium armor.",
               name = "Medium Armor"
            },
            memorization = {
               description = "Helps you acquire additional spell stocks.",
               enchantment_description = "enhances your memory.",
               name = "Memorization"
            },
            spell_meteor = {
               description = "Massive Attack",
               name = "Meteor"
            },
            action_mewmewmew = {
               description = "?",
               name = "Mewmewmew!"
            },
            spell_mind_bolt = {
               description = "Line(Mind)",
               name = "Mind Bolt"
            },
            action_mind_breath = {
               description = "Breath(Mind)",
               name = "Mind Breath"
            },
            mining = {
               description = "Shows how good of a miner you are.",
               name = "Mining"
            },
            action_mirror = {
               description = "Know self",
               name = "Mirror"
            },
            spell_mist_of_darkness = {
               description = "Create mist",
               name = "Mist of Darkness"
            },
            buff_mist_of_frailness = {
               name = "Mist of frailness"
            },
            buff_mist_of_silence = {
               name = "Mist of Silence"
            },
            spell_mutation = {
               description = "Mutate self",
               name = "Mutation"
            },
            negotiation = {
               description = "Convinces someone to give you better deals.",
               name = "Negotiation"
            },
            spell_nerve_arrow = {
               description = "Target(Nerve)",
               name = "Nerve Arrow"
            },
            action_nerve_breath = {
               description = "Breath(Nerve)",
               name = "Nerve Breath"
            },
            spell_nether_arrow = {
               description = "Target(Nether)",
               name = "Nether Arrow"
            },
            action_nether_breath = {
               description = "Breath(Nether)",
               name = "Nether Breath"
            },
            buff_nightmare = {
               name = "Nightmare"
            },
            spell_oracle = {
               description = "Reveal artifacts",
               name = "Oracle"
            },
            performer = {
               description = "Shows how good of a performer you are.",
               name = "Performer"
            },
            pickpocket = {
               description = "Shows how good of a thief you are.",
               name = "Pickpocket"
            },
            action_poison_breath = {
               description = "Breath(Poison)",
               name = "Poison Breath"
            },
            polearm = {
               description = "Indicates your skill with polearms.",
               name = "Polearm"
            },
            action_power_breath = {
               description = "Breath",
               name = "Power Breath"
            },
            action_prayer_of_jure = {
               description = "Heal HP self",
               name = "Prayer of Jure"
            },
            action_pregnant = {
               description = "Pregnant target",
               name = "Pregnant"
            },
            buff_punishment = {
               name = "Punishment"
            },
            spell_raging_roar = {
               description = "Surround(Sound)",
               name = "Raging Roar"
            },
            action_rain_of_sanity = {
               description = "Cure insane area",
               name = "Rain of sanity"
            },
            buff_regeneration = {
               name = "Regeneration"
            },
            spell_restore_body = {
               description = "Restore physical",
               name = "Restore Body"
            },
            spell_restore_spirit = {
               description = "Restore mind",
               name = "Restore Spirit"
            },
            spell_resurrection = {
               description = "Resurrect dead",
               name = "Resurrection"
            },
            spell_return = {
               description = "Return",
               name = "Return"
            },
            riding = {
               description = "Allows you to ride creatures.",
               name = "Riding"
            },
            action_scavenge = {
               description = "Steal food",
               name = "Scavenge"
            },
            scythe = {
               description = "Indicates your skill with sycthes.",
               name = "Scythe"
            },
            spell_sense_object = {
               description = "Reveal nearby objects",
               name = "Sense Object"
            },
            sense_quality = {
               description = "Allows you to sense the quality of stuff.",
               name = "Sense Quality"
            },
            action_shadow_step = {
               description = "Teleport to target",
               name = "Shadow Step"
            },
            shield = {
               description = "Increases the effectivness of using shields.",
               name = "Shield"
            },
            short_sword = {
               description = "Indicates your skill with short swords.",
               name = "Short Sword"
            },
            spell_short_teleport = {
               description = "Teleport self",
               name = "Short Teleport"
            },
            buff_slow = {
               name = "Slow"
            },
            action_sound_breath = {
               description = "Breath(Sound)",
               name = "Sound Breath"
            },
            buff_speed = {
               name = "Speed"
            },
            stave = {
               description = "Indicates your skill with staves.",
               name = "Stave"
            },
            stealth = {
               description = "Allows you to move quietly.",
               name = "Stealth"
            },
            action_suicide_attack = {
               description = "Suicide",
               name = "Suicide Attack"
            },
            action_summon_cats = {
               description = "Summon cats",
               name = "Summon Cats"
            },
            action_summon_fire = {
               description = "Summon fire creatures",
               name = "Summon Fire"
            },
            spell_summon_monsters = {
               description = "Summon hostile creatures",
               name = "Summon Monsters"
            },
            action_summon_pawn = {
               description = "Summon pieces",
               name = "Summon Pawn"
            },
            action_summon_sister = {
               description = "Summon sisters",
               name = "Summon sister"
            },
            spell_summon_wild = {
               description = "Summon wild creatures",
               name = "Summon Wild"
            },
            action_summon_yeek = {
               description = "Summon Yeeks",
               name = "Summon Yeek"
            },
            action_suspicious_hand = {
               description = "Steal from target",
               name = "Suspicious Hand"
            },
            action_swarm = {
               description = "Attack circle",
               name = "Swarm"
            },
            tactics = {
               description = "Increases melee damage.",
               name = "Tactics"
            },
            tailoring = {
               description = "Skill to sew materials and manufucture products.",
               enchantment_description = "makes you a better tailor.",
               name = "Tailoring"
            },
            spell_teleport = {
               description = "Teleport self",
               name = "Teleport"
            },
            spell_teleport_other = {
               description = "Teleport target",
               name = "Teleport Other"
            },
            throwing = {
               description = "Indicates your skill with throwing objects.",
               name = "Throwing"
            },
            action_touch_of_fear = {
               description = "Fear target",
               name = "Touch of Fear"
            },
            action_touch_of_hunger = {
               description = "Starve target",
               name = "Touch of Hunger"
            },
            action_touch_of_nerve = {
               description = "Paralyze target",
               name = "Touch of Nerve"
            },
            action_touch_of_poison = {
               description = "Poison target",
               name = "Touch of Poison"
            },
            action_touch_of_sleep = {
               description = "Sleep target",
               name = "Touch of Sleep"
            },
            action_touch_of_weakness = {
               description = "Weaken target",
               name = "Touch of Weakness"
            },
            traveling = {
               description = "Allows you to receive more EXP from traveling.",
               name = "Traveling"
            },
            two_hand = {
               description = "Used when wielding a weapon with both hands.",
               name = "Two Hand"
            },
            spell_uncurse = {
               description = "Uncurse items",
               name = "Uncurse"
            },
            action_vanish = {
               description = "Escape self.",
               name = "Vanish"
            },
            spell_vanquish_hex = {
               description = "Remove all hexes",
               name = "Vanquish Hex"
            },
            spell_wall_creation = {
               description = "Create walls",
               name = "Wall Creation"
            },
            spell_web = {
               description = "Create webs",
               name = "Web"
            },
            weight_lifting = {
               description = "Allows you to carry more stuff.",
               name = "Weight Lifting"
            },
            spell_wish = {
               description = "Wish",
               name = "Wish"
            },
            spell_wizards_harvest = {
               description = "Random harvest",
               name = "Wizard's Harvest"
            }
         },
      }
   }
}
