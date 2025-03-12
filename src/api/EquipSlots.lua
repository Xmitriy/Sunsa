--- @module EquipSlots

local ICloneable = require("api.ICloneable")
local ILocation = require("api.ILocation")
local IOwned = require("api.IOwned")
local IItemEquipment = require("mod.elona.api.aspect.IItemEquipment")
local MapObject = require("api.MapObject")
local pool = require("internal.pool")
local data = require("internal.data")

local EquipSlots = class.class("EquipSlots", {ILocation, IOwned, ICloneable})

--- @tparam {id:base.body_part,...} body_parts
--- @tparam uid:IChara owner
function EquipSlots:init(body_parts, owner)
   if owner then
      assert(class.is_an(IOwned, owner))
      self._parent = owner
   end
   body_parts = body_parts or {}

   local init = function(_type)
      data["base.body_part"]:ensure(_type)
      return {
         type = _type,
         equipped = nil
      }
   end
   self.body_parts = fun.iter(body_parts):map(init):to_list()

   self.pool = pool:new("base.item", 1, 1, self)

   self.equipped = {}
   self.blocked = table.set {} -- set of base.body_part IDs
end

function EquipSlots:get(slot_index)
   return self.body_parts[slot_index]
end

function EquipSlots:body_part_count(body_part_id)
   data["base.body_part"]:ensure(body_part_id)

   local pred = function(part) return part.type == body_part_id end

   return fun.iter(self.body_parts):filter(pred):length()
end

-- Returns true if there is a compatible slot for an item, even if
-- something is already equipped at the slot.
-- @tparam IItem item
-- @treturn bool
function EquipSlots:has_body_part_for(item)
   local pred = function(part) return item:can_equip_at(part) end

   return fun.iter(self.body_parts):any(pred)
end

-- @tparam IItem item
-- @tparam[opt] id[base.body_part] body_part_type
function EquipSlots:find_free_slot(item, body_part_type)
   local pred

   if not item:get_aspect(IItemEquipment) then
      return nil
   end

   if body_part_type then
      if not item:can_equip_at(body_part_type) then
         return nil
      end

      pred = function(part)
         return part.type == body_part_type and not part.equipped
      end
   else
      pred = function(part)
         return item:can_equip_at(part.type) and not part.equipped
      end
   end

   local part = fun.iter(self.body_parts):filter(pred):nth(1)
   local slot = fun.index(part, self.body_parts)

   return slot
end

--- Puts an item into an equip slot provided it is free. Returns the
--- object on success, nil on failure.
-- @tparam IMapObject obj
-- @tparam int slot
-- @treturn[opt] IMapObject
-- @ownership obj nil
function EquipSlots:equip(obj, slot)
   if slot == nil then
      slot = self:find_free_slot(obj)
   end

   if type(slot) ~= "number" then
      return nil, "invalid_slot"
   end

   if obj == nil then
      return nil, "invalid_object"
   end

   if slot <= 0 or slot > #self.body_parts then
      return nil, "slot_out_of_range"
   end

   local body_part = self.body_parts[slot]

   if not obj:can_equip_at(body_part.type) then
      return nil, "cannot_equip_at"
   end

   if body_part.equipped then
      return nil, "slot_is_occupied"
   end

   if self.equipped[obj.uid] then
      return nil, "is_equipped"
   end

   local ok, err = self.pool:take_object(obj)
   if not ok then
      return nil, err
   end

   self.equipped[obj.uid] = slot
   body_part.equipped = obj.uid

   return obj
end

--- Removes an item from the equip slots. Returns the object on
--- success, nil on failure.
-- @tparam IMapObject obj
-- @treturn[opt] IMapObject
-- @ownership obj self
function EquipSlots:unequip(obj)
   if obj == nil then
      return nil
   end

   local slot = self.equipped[obj.uid]
   if not slot then
      return nil
   end

   if not self.pool:remove_object(obj) then
      return nil
   end

   assert(obj.location == nil)
   self.equipped[obj.uid] = nil
   self.body_parts[slot].equipped = nil

   return obj
end

--- Adds a new body part.
-- @tparam base.body_part _type
function EquipSlots:add_body_part(_id)
   data["base.body_part"]:ensure(_id)
   self.body_parts[#self.body_parts+1] = { type = _id, equipped = nil }
end

--- Removes a body part at slot. Fails if an item is equipped there;
--- callers are expected to manage unequipping themselves.
-- @tparam int slot
-- @treturn bool
function EquipSlots:remove_body_part(slot)
   if slot <= 0 or slot > #self.body_parts then
      return false
   end

   local part = self.body_parts[slot]

   if part.equipped then
      return false
   end

   table.remove(self.body_parts, slot)

   return true
end

function EquipSlots:iter_items_equipped_at(body_part_type)
   local pred = function(v)
      return v.body_part._id == body_part_type
   end
   return self:iter_equipped_body_parts():filter(pred):extract("equipped")
end

local function iter_body_parts(state, index)
   if index > #state.body_parts then
      return nil
   end

   local entry

   repeat
      local body_part = state.body_parts[index]
      local equipped = state.pool:get_object(body_part.equipped)

      if (state.also_empty or equipped) and (state.also_blocked or not state.blocked[body_part.type]) then
         entry = {
            body_part = data["base.body_part"]:ensure(body_part.type),
            equipped = state.pool:get_object(body_part.equipped),
            slot = index
         }
      end
      index = index + 1
   until entry or index > #state.body_parts

   if entry == nil then
      return nil
   end

   return index, entry
end

function EquipSlots:iter_all_body_parts(also_blocked)
   return fun.wrap(iter_body_parts, {body_parts=self.body_parts,blocked=self.blocked,pool=self.pool,also_empty=true, also_blocked=also_blocked or false}, 1)
end

function EquipSlots:iter_equipped_body_parts(also_empty, also_blocked)
   return fun.wrap(iter_body_parts, {body_parts=self.body_parts,blocked=self.blocked,pool=self.pool,also_empty=false, also_blocked=also_blocked or false}, 1)
end

function EquipSlots:equip_slot_of(item)
   local slot = self.equipped[item.uid]
   if slot == nil then return nil end

   return self.body_parts[slot]
end

function EquipSlots:set_body_part_blocked(id, blocked)
   data["base.body_part"]:ensure(id)
   self.blocked[id] = not not blocked
end

--
-- ILocation impl
--

EquipSlots:delegate("pool",
                   {
                      "move_object",
                      "objects_at_pos",
                      "get_object",
                      "has_object",
                      "iter"
                   })

function EquipSlots:is_positional()
   return false
end

function EquipSlots:is_in_bounds(x, y)
   return true
end

function EquipSlots:remove_object(obj)
   return self:unequip(obj)
end

function EquipSlots:can_take_object(obj)
   return self:find_free_slot(obj) ~= nil
end

function EquipSlots:take_object(obj)
   if not self:can_take_object(obj) then
      return nil
   end

   local slot = self:find_free_slot(obj)
   if not slot then
      return nil
   end

   return self:equip(obj, slot)
end

--
-- ICloneable impl
--

function EquipSlots:clone(uid_tracker, cache, uid_mapping, opts)
   local new = MapObject.deepcopy(self, uid_tracker, cache, uid_mapping, opts)

   new.equipped = {}
   for old_uid, slot in pairs(self.equipped) do
      local new_uid = uid_mapping[old_uid]
      new.equipped[new_uid] = slot
      new.body_parts[slot].equipped = new_uid
   end

   return new
end

return EquipSlots
