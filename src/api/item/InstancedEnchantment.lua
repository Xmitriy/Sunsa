local I18N = require("api.I18N")
local data = require("internal.data")
local InstancedEnchantment = class.class("InstancedEnchantment")

local SOURCES = table.set { "item", "material", "generated", "ego", "ego_minor", "special" }

function InstancedEnchantment:init(_id, power, params, curse_power, source)
   assert(type(power) == "number", "Enchantment power must be number")
   assert(params == "randomized" or type(params) == "table", "Params must be 'randomized' or table")
   curse_power = curse_power or 0
   assert(type(curse_power) == "number", "Curse power must be number")
   source = source or "generated"
   assert(SOURCES[source], "Must include source")
   self._id = _id
   self.power = power
   self.params = params
   self.curse_power = curse_power

   self.proto = data["base.enchantment"]:ensure(_id)
   self.source = source

   -- NOTE: unused in vanilla
   self.is_inheritable = true
end

function InstancedEnchantment:serialize()
   self.proto = nil
end

function InstancedEnchantment:deserialize()
   self.proto = data["base.enchantment"]:ensure(self._id)
end

function InstancedEnchantment:on_generate(item)
   self.params = {}
   if self.proto.on_generate then
      return self.proto.on_generate(self, item, {curse_power=self.curse_power})
   end
   return true
end

function InstancedEnchantment:on_initialize(item)
   if self.proto.on_initialize then
      return self.proto.on_initialize(self, item, {curse_power=self.curse_power})
   end
end

function InstancedEnchantment:localize(item)
   if self.proto.localize then
      return self.proto.localize(self, item)
   end

   return I18N.get("_.base.enchantment." .. self._id .. ".description")
end

function InstancedEnchantment:compare_params(other_params)
   local cmp = table.deepcompare
   if self.proto.compare then
      cmp = self.proto.compare
   end

   return not not cmp(self.params, other_params)
end

function InstancedEnchantment:is_same_as(other)
   if self.proto._id ~= other.proto._id then
      return false
   end

   return self:compare_params(other.params)
end

function InstancedEnchantment:can_merge_with(other)
   if self.proto.no_merge then
      return false
   end

   return self:is_same_as(other)
end

function InstancedEnchantment:__lt(other)
   -- >>>>>>>> shade2/item_data.hsp:496 	#deffunc sortEnc int id ...
   local my_ordering = self.proto._ordering
   local their_ordering = other.proto._ordering
   return my_ordering < their_ordering
   -- <<<<<<<< shade2/item_data.hsp:513 	#global  ..
end

return InstancedEnchantment
