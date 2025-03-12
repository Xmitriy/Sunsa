local pool = require("internal.pool")
local ITypedLocation = require("api.ITypedLocation")

-- A pool that stores objects of multiple types.
local multi_pool = class.class("multi_pool", ITypedLocation)

local function t(o)
   return setmetatable(o or {}, { __inspect = tostring })
end

function multi_pool:init(width, height, owner)
   if owner then
      -- assert(class.is_an(ITypedLocation, owner))
      self._parent = owner
   end
   self.width = width
   self.height = height

   self.subpools = t()
   self.refs = setmetatable({}, { __mode = "v", __inspect = tostring })

   self.positional = {}
end

function multi_pool:get_subpool(type_id)
   -- TODO: preregister known objects types beforehand
   self.subpools[type_id] = self.subpools[type_id] or pool:new(type_id, self.width, self.height, self)
   return self.subpools[type_id]
end

function multi_pool:is_positional()
   return true
end

function multi_pool:is_in_bounds(x, y)
   return x >= 0 and y >= 0 and x < self.width and y < self.height
end

function multi_pool:take_object(obj, x, y)
   local subpool = self:get_subpool(obj._type)
   if subpool:take_object(obj, x, y) == nil then
      return nil
   end

   self.refs[obj.uid] = subpool:get_object(obj.uid)
   local idx = obj.y*self.width+obj.x+1
   if self.positional[idx] == nil then
      self.positional[idx] = {}
   end
   table.insert(self.positional[idx], obj)

   return obj
end

function multi_pool:remove_object(obj)
   local obj = self:get_subpool(obj._type):remove_object(obj)
   assert(obj.location == nil)

   local idx = obj.y*self.width+obj.x+1
   self.refs[obj.uid] = nil
   table.iremove_value(self.positional[idx], obj)
   if #self.positional[idx] == 0 then
      self.positional[idx] = nil
   end

   return obj
end

function multi_pool:move_object(obj, x, y)
   local prev_x, prev_y = obj.x, obj.y

   local obj = self:get_subpool(obj._type):move_object(obj, x, y)

   local prev_idx = prev_y*self.width+prev_x+1
   table.iremove_value(self.positional[prev_idx], obj)
   if #self.positional[prev_idx] == 0 then
      self.positional[prev_idx] = nil
   end
   local new_idx = y*self.width+x+1
   if self.positional[new_idx] == nil then
      self.positional[new_idx] = {}
   end
   table.insert(self.positional[new_idx], obj)

   return obj
end

function multi_pool:objects_at_pos(x, y)
   if not self:is_in_bounds(x, y) then
      return fun.iter({})
   end
   return fun.iter(table.shallow_copy(self.positional[y*self.width+x+1] or {}))
end

function multi_pool:get_object(uid)
   return self.refs[uid]
end

function multi_pool:has_object(uid_or_obj)
   local uid = uid_or_obj
   if type(uid_or_obj) == "table" then
      uid = uid_or_obj.uid
   end
   return self.refs[uid] ~= nil
end

local function iter(state, index)
   if index > #state.uids then
      return nil
   end

   local data = state.refs[state.uids[index]]
   index = index + 1
   return index, data
end

function multi_pool:iter()
   -- luafun will try to iterate self.refs as an array if #self.refs >
   -- 0 (e.g. UID 1 exists), but it's always meant to be a map, so
   -- wrap it manually.
   local ordering = table.keys(self.refs)
   table.sort(ordering)
   return fun.wrap(iter, {uids=ordering, refs=self.refs}, 1)
end

function multi_pool:iter_type(_type)
   return self:get_subpool(_type):iter()
end

function multi_pool:iter_type_at_pos(_type, x, y)
   return self:get_subpool(_type):objects_at_pos(x, y)
end

function multi_pool:has_object_of_type(_type, uid)
   local obj = self.refs[uid]
   return obj and obj._type == _type
end

function multi_pool:get_object_of_type(_type, uid)
   local obj = self.refs[uid]
   if obj == nil then
      return nil
   end
   assert(obj._type == _type, obj._type)
   return obj
end

function multi_pool:can_take_object(obj)
   return true
end

return multi_pool
