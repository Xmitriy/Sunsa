local Inventory = require("api.Inventory")
local ILocation = require("api.ILocation")
local Log = require("api.Log")

--- Interface for character inventory. Allows characters to store map
--- objects.
local ICharaInventory = class.interface("ICharaInventory", {}, {ILocation})

ICharaInventory:delegate("inv",
                        {
                           "is_positional",
                           "can_take_object",
                           "is_in_bounds",
                           "objects_at_pos"
                        })

function ICharaInventory:iter()
   -- HACK for purposes of IOwned:get_location() (see #149)
   return fun.chain(self:iter_items(), self:iter_shop_inventory())
end


--- Iterates both the character's inventory and equipment.
---
--- @treturn Iterator(IItem)
function ICharaInventory:iter_items()
   return fun.chain(self:iter_inventory(), self:iter_equipment())
end

-- HACK see #149
function ICharaInventory:iter_shop_inventory()
   if self.shop_inventory == nil then
      return fun.iter({})
   end
   return self.shop_inventory:iter()
end

function ICharaInventory:get_object(uid)
   local obj = self.inv:get_object(uid)
   if not obj then
      obj = self.equip:get_object(uid)
   end
   -- HACK see #149
   if not obj and self.shop_inventory then
      obj = self.shop_inventory:get_object(uid)
   end
   return obj
end

function ICharaInventory:move_object(obj, x, y)
   if self.inv:has_object(obj) then
      return self.inv:move_object(obj, x, y)
   elseif self.equip:has_object(obj) then
      return self.equip:move_object(obj, x, y)
   -- HACK see #149
   elseif self.shop_inventory and self.shop_inventory:has_object(obj) then
      return self.shop_inventory:move_object(obj, x, y)
   end
   return nil
end

function ICharaInventory:remove_object(obj)
   if self.inv:has_object(obj) then
      return self.inv:remove_object(obj)
   elseif self.equip:has_object(obj) then
      return self.equip:remove_object(obj)
   -- HACK see #149
   elseif self.shop_inventory and self.shop_inventory:has_object(obj) then
      return self.shop_inventory:remove_object(obj)
   end
   return nil
end

function ICharaInventory:has_object(obj)
   if self.inv:has_object(obj) then
      return true
   elseif self.equip:has_object(obj) then
      return true
   -- HACK see #149
   elseif self.shop_inventory and self.shop_inventory:has_object(obj) then
      return true
   end
   return false
end

function ICharaInventory:init()
   self.inv = Inventory:new(200, "base.item", self)
end

function ICharaInventory:take_object(obj)
   if not self:can_take_object(obj) then
      return nil
   end

   if not self.inv:take_object(obj) then
      return nil
   end

   self:refresh_weight()

   return obj
end


function ICharaInventory:drop_item(item, amount)
   if not self:has_item_in_inventory(item) then
      Log.warn("Character %d tried dropping item, but it was not in their inventory. %d", self.uid, item.uid)
      return nil
   end

   local map = self:current_map()
   if not map then
      Log.warn("Character tried dropping item, but was not in map. %d", self.uid)
      return nil
   end

   return item:move_some(amount, map, self.x, self.y)
end

function ICharaInventory:has_item_in_inventory(item)
   return self.inv:has_object(item)
end

function ICharaInventory:take_item(item, amount)
   return item:move_some(amount, self)
end

function ICharaInventory:find_items(_id)
   return self:iter_inventory():filter(function(i) return i.amount > 0 and i._id == _id end)
end

function ICharaInventory:find_item(_id)
   return self:find_items(_id):nth(1)
end

--- Iterates the items in the character's inventory (excluding
--- equipment).
---
--- @treturn iterator(IItem)
function ICharaInventory:iter_inventory()
   return self.inv:iter()
end

function ICharaInventory:free_inventory_slots()
   return self.inv:free_slots()
end

function ICharaInventory:is_inventory_full()
   return self.inv:is_full()
end

return ICharaInventory
