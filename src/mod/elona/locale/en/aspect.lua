return {
   aspect = {
      _ = {
         elona = {
            IItemUseable = {
               prompt = function(_1) return ("How do you want to use %s?"):format(_1) end,
            },
            IItemSeed = {
               action_name = "Seed"
            },
            IItemMusicDisc = {
               action_name = "Music Disc"
            },
            IItemMonsterBall = {
               action_name = "Monster Ball",

               level = function(s, lv)
                  return ("%s Level %s(Empty)"):format(s, lv)
               end
            },
            IItemCookingTool = {
               action_name = "Cooking Tool"
            },
            IItemGaroksHammer = {
               action_name = "Garok's Hammer"
            },
            IItemFishingPole = {
               action_name = "Fishing Pole",

               remaining = function(s, bait, charges)
                  return ("%s(%s %s)"):format(s, charges, bait)
               end
            },
            IItemBait = {
               action_name = "Bait",

               title = function(s, bait_name)
                  return ("%s <%s>"):format(s, bait_name)
               end
            },
            IItemMoneyBox = {
               action_name = "Kitty Bank",

               amount = function(s, amount)
                  return ("%s(%s)"):format(s, amount)
               end,
               increments = {
                  _500       = "500 GP",
                  _2000      = "2k GP",
                  _10000     = "10K GP",
                  _50000     = "50K GP",
                  _500000    = "500K GP",
                  _5000000   = "5M GP",
                  _100000000 = "500M GP"
               }
            },
            IItemChair = {
               action_name = "Chair"
            },

            IItemReadable = {
               prompt = function(_1) return ("How do you want to read %s?"):format(_1) end,
            },
            IItemTextbook = {
               action_name = "Textbook",

               title = function(s, skill_name)
                  return ("%s titled <Art of %s>"):format(s, skill_name)
               end
            },
            IItemBook = {
               action_name = "Book",

               title = function(s, title)
                  return ("%s titled <%s>"):format(s, title)
               end
            },
            IItemBookOfRachel = {
               action_name = "Book of Rachel",

               title = function(s, no)
                  return ("%s of Rachel No.%s"):format(s, no)
               end
            },
            IItemSpellbook = {
               action_name = "Spellbook",
            },
            IItemAncientBook = {
               action_name = "Ancient Book",

               decoded = nil,
               undecoded = function(_1)
                  return ("undecoded %s"):format(_1)
               end,

               title = function(title, name)
                  return ("%s titled <%s>"):format(name, title)
               end,
               titles = {
                  _0 = "Voynich Manuscript",
                  _1 = "Dhol Chants",
                  _2 = "Ponape Scripture",
                  _3 = "Revelations of Glaaki",
                  _4 = "G'harne Fragments",
                  _5 = "Liber Damnatus",
                  _6 = "Book of Dzyan",
                  _7 = "Book of Eibon",
                  _8 = "Grand Grimoire",
                  _9 = "Celaeno Fragments",
                  _10 = "Necronomicon",
                  _11 = "The R'lyeh Text",
                  _12 = "Eltdown Shards",
                  _13 = "The Golden Bough",
                  _14 = "Apocalypse"
               },
            },

            IItemPotion = {
               action_name = "Potion"
            },
            IItemWell = {
               action_name = "Well"
            },

            IItemZappable = {
               prompt = function(_1) return ("How do you want to zap %s?"):format(_1) end,
            },
            IItemRod = {
               action_name = "Rod"
            },

            IFeatActivatable = {
               prompt = function(_1) return ("How do you want to use %s?"):format(_1) end,
            },
            IFeatDescendable = {
               prompt = function(_1) return ("How do you want to use %s?"):format(_1) end,
            },
            IFeatLockedHatch = {
               action_name = "Hatch"
            },

            IItemChargeable = {
               action_name = "Chargeable"
            }
         }
      }
   }
}
