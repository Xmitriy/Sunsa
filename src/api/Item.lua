--- Functions for manipulating items.
--- @module Item
local ILocation = require("api.ILocation")
local Map = require("api.Map")
local MapObject = require("api.MapObject")
local Enum = require("api.Enum")
local I18N = require("api.I18N")
local Log = require("api.Log")
local Chara = require("api.Chara")
local IChara = require("api.chara.IChara")

local data = require("internal.data")
local field = require("game.field")

local Item = {}

--- Returns the items at a given map position.
---
--- @tparam uint x
--- @tparam uint y
--- @tparam InstancedMap map
--- @treturn Iterator(IItem)
function Item.at(x, y, map)
   map = map or field.map

   if not map:is_in_bounds(x, y) then
      return fun.iter({})
   end

   return map:iter_type_at_pos("base.item", x, y):filter(Item.is_alive)
end

--- @tparam[opt] InstancedMap map
--- @treturn Iterator(IItem)
function Item.iter_all(map)
   return (map or field.map):iter_items()
end

--- @tparam[opt] InstancedMap map
--- @treturn Iterator(IItem)
function Item.iter(map)
   return Item.iter_all(map):filter(Item.is_alive)
end

--- @tparam[opt] InstancedMap map
--- @treturn Iterator(IItem)
function Item.iter_in_everything(map)
   local iters = Chara.iter(map):map(IChara.iter_items):to_list()
   iters[#iters+1] = Item.iter(map)
   return fun.chain(table.unpack(iters))
end

--- @tparam[opt] InstancedMap map
--- @treturn Iterator(IItem)
function Item.iter_ground(map)
   map = map or field.map
   local is_on_ground = function(i)
      return i:current_map() ~= nil
   end
   return Item.iter(map):filter(is_on_ground)
end

--- Returns true if this item has any amount remaining. Will also
--- handle nil values.
---
--- @tparam[opt] IItem item
--- @tparam[opt] InstancedMap map Map to check for existence in
function Item.is_alive(item, map)
   if type(item) ~= "table" or item.amount <= 0 then
      return false
   end

   if map == nil then
      return item.location ~= nil
   end

   local their_map = item:current_map()
   if not their_map then
      return false
   end

   return their_map.uid == map.uid
end

--- Creates a new item. Returns the item on success, or nil if
--- creation failed.
---
--- @tparam id:base.item id
--- @tparam[opt] int x Defaults to a random free position on the map.
--- @tparam[opt] int y
--- @tparam[opt] table params Extra parameters.
---  - ownerless (bool): Do not attach the item to a map. If true, then `where` is ignored.
---  - no_build (bool): Do not call :build() on the object.
---  - no_stack (bool): Do not attempt to stack this item with others like it on the same tile.
---  - approximate_pos (bool): If position is not accessable, put the item somewhere close.
---  - copy (table): A dict of fields to copy to the newly created item. Overrides fix_level, quality, and amount.
---  - amount (int): Amount of the item to create.
---  - quality (Enum.Quality): Quality of the item. Defaults to Quality.Bad.
--- @tparam[opt] ILocation map Where to instantiate this item.
---   Defaults to the current map.
--- @treturn[opt] IItem
--- @treturn[opt] string error
function Item.create(id, x, y, params, where)
   params = params or {}

   if params.ownerless then
      where = nil
   else
      if where == nil then
         Log.warn("Implicit global map used in Item.create().")
         if Log.has_level("debug") then
            Log.debug("%s", debug.traceback())
         end
      end
      where = where or field.map
   end

   if not class.is_an(ILocation, where) and not params.ownerless then
      return nil, "invalid location"
   end

   if where and where:is_positional() and (not x or params.approximate_pos) then
      x, y = Map.find_free_position(x, y, {only_map=true}, where)
      if not x then
         return nil, "out of bounds"
      end
   end

   local gen_params = {
      no_build = params.no_build,
      build_params = params
   }
   local item = MapObject.generate_from("base.item", id, params.uid_tracker or nil)

   item.quality = params.quality or Enum.Quality.Bad

   if where then
      item = where:take_object(item, x, y)

      if not item then
         return nil, "location failed to receive object"
      end
   end

   local ok, err = xpcall(MapObject.finalize, debug.traceback, item, gen_params)
   if not ok then
      Log.error(err)
      item:remove_ownership()
      return nil, err
   end

   item:emit("base.on_item_generate", params)

   -- >>>>>>>> shade2/item.hsp:728 	if initNum!0:iNum(ci)=initNum ..
   if type(params.amount) == "number" then
      item.amount = math.floor(params.amount)
   end

   if not params.no_stack then
      item:stack()
   end

   item:refresh()
   -- <<<<<<<< shade2/item.hsp:730 	if val=-1:cell_refresh iX(ci),iY(ci) ..

   return item
end

--- Looks for an item with the given UID or base.item ID in the
--- current map.
---
--- @tparam id:base.item|uid id
--- @tparam string kind "all", "ground", "inventory" or "equipment"
--- @tparam[opt] InstancedMap map
--- @treturn[opt] IItem
function Item.find(id, kind, map)
   map = map or field.map

   kind = kind or "ground"

   local iter
   if kind == "ground" then
      iter = Item.iter(map)
   elseif kind == "all" then
      local chain = {}
      chain[#chain+1] = Item.iter(map)
      for _, chara in Chara.iter(map) do
         chain[#chain+1] = chara:iter_items()
      end
      iter = fun.chain(table.unpack(chain))
   else
      error(("Unknown Item.find kind '%s'"):format(kind))
   end

   local compare_field
   if type(id) == "number" then
      compare_field = "uid"
   else
      compare_field = "_id"
   end

   local pred = function(item)
      return Item.is_alive(item) and item[compare_field] == id
   end

   return iter:filter(pred):nth(1)
end

return Item
