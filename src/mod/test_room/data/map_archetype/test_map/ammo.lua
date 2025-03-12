local Item = require("api.Item")
local utils = require("mod.test_room.data.map_archetype.utils")

local ammo = {
   _id = "ammo"
}

local function make_ammo_enchantments(x, y, map)
   local ix = x
   local iy = y
   for _, idx, ammo_enc in data["base.ammo_enchantment"]:iter():enumerate() do
      ix = x + ((idx - 1) % (map:width() - x - 2))
      iy = y + math.floor((idx - 1) / (map:width() - x - 2))
      if not map:can_access(ix, iy) then
         break
      end

      for i= -1, 1, 2 do
         local power = 150 * i
         local item = assert(Item.create("elona.bullet", ix, iy, {}, map))
         item:add_enchantment("elona.ammo", power, {ammo_enchantment_id = ammo_enc._id}, 0)
      end
   end

   return 2, iy + 2
end

function ammo.on_generate_map(area, floor)
   local map = utils.create_map(20, 20)
   utils.create_stairs(2, 2, area, map)

   local x = 2
   local y = 4

   utils.create_sandbag(4, 2, map)
   utils.create_sandbag(6, 2, map, "elona.public_performer")
   Item.create("elona.machine_gun", 3, 2, {}, map)

   x, y = make_ammo_enchantments(x, y, map)

   utils.normalize_items(map)

   return map
end

return ammo
