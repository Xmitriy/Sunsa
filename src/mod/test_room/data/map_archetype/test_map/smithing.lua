local utils = require("mod.test_room.data.map_archetype.utils")
local Item = require("api.Item")
local Charagen = require("mod.elona.api.Charagen")
local Itemgen = require("mod.elona.api.Itemgen")
local IItemFromChara = require("mod.elona.api.aspect.IItemFromChara")

local smithing = {
   _id = "smithing"
}

function smithing.on_generate_map(area, floor)
   local map = utils.create_map(20, 20)
   utils.create_stairs(2, 2, area, map)

   Item.create("smithing.blacksmith_hammer", 3, 2, {}, map)
   Item.create("elona.broken_sword", 4, 2, { amount = 100 }, map)
   Item.create("elona.vanilla_rock", 5, 2, { amount = 100 }, map)
   local skin = Item.create("elona.remains_skin", 6, 2,
                            { amount = 100, aspects={[IItemFromChara]={chara_id="elona.lizard_man"}} },
                            map)
   Item.create("elona.anvil", 7, 2, {}, map)
   Item.create("elona.furnace", 8, 2, {}, map)

   for _ = 1, 20 do
      local skin = Item.create("elona.remains_skin", nil, nil,
                               { amount = 100, aspects={[IItemFromChara]={chara_id=Charagen.random_chara_id_raw(100)}} },
                               map)
   end
   for _ = 1, 20 do
      Itemgen.create(nil, nil, { categories = {"elona.ore_valuable"}, amount = 100 }, map)
   end

   return map
end

return smithing
