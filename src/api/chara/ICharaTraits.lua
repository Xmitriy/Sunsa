local Gui = require("api.Gui")
local I18N = require("api.I18N")
local Log = require("api.Log")
local data = require("internal.data")

local ICharaTraits = class.interface("ICharaTraits")

function ICharaTraits:init()
   self.traits = self.traits or {}
end

function ICharaTraits:has_trait(trait_id)
   data["base.trait"]:ensure(trait_id)
   return self.traits[trait_id] and self.traits[trait_id].level ~= 0
end

function ICharaTraits:trait_level(trait_id)
   data["base.trait"]:ensure(trait_id)
   local trait = self.traits[trait_id]
   if trait == nil then
      return 0
   end
   return trait.level
end

function ICharaTraits:iter_traits()
   return fun.iter(table.keys(self.traits))
   :filter(function(trait_id) return self.traits[trait_id].level ~= 0 end)
   :map(function(trait_id) return { proto = data["base.trait"]:ensure(trait_id), level = self.traits[trait_id].level, _id = trait_id } end)
end

function ICharaTraits:on_refresh()
   local remove = {}
   for trait_id, _ in pairs(self.traits) do
      local trait = data["base.trait"][trait_id]
      if not trait then
         Gui.report_error("No trait with ID " .. trait_id)
         remove[#remove+1] = trait_id
      end
   end

   for _, trait_id in ipairs(remove) do
      self.traits[trait_id] = nil
   end

   for trait_id, entry in pairs(self.traits) do
      local trait = data["base.trait"]:ensure(trait_id)
      if entry.level ~= 0 and trait.on_refresh then
         trait.on_refresh(entry, self)
      end
   end
end

function ICharaTraits:modify_trait_level(trait_id, delta, no_message)
   if delta == 0 then
      return
   end

   local success = false
   data["base.trait"]:ensure(trait_id)

   if delta < 0 then
      for _ = 1, math.abs(delta) do
         success = self:decrement_trait(trait_id, no_message) or success
      end
   else
      for _ = 1, delta do
         success = self:increment_trait(trait_id, no_message) or success
      end
   end

   return success
end

function ICharaTraits:increment_trait(trait_id, no_message)
   local trait = data["base.trait"]:ensure(trait_id)

   if self.traits[trait_id] == nil then
      self.traits[trait_id] = { level = 0 }
   elseif self.traits[trait_id].level >= trait.level_max then
      return false
   end

   local prev_level = self.traits[trait_id].level

   if self.traits[trait_id].level < trait.level_max then
      self.traits[trait_id].level = self.traits[trait_id].level + 1

      if not no_message then
         local mes = I18N.localize_optional("base.trait", trait_id, "on_gain_level")
         if mes then
            Gui.mes_c(mes, "Green")
         else
            Log.warn("No trait gain level message for '%s'", trait_id)
         end
      end

      if self.traits[trait_id].level == 0 then
         self.traits[trait_id] = nil
      end
   end

   if trait.on_modify_level then
      local cur_level = self:trait_level(trait_id)
      trait.on_modify_level(cur_level, self, prev_level)
   end

   return true
end

function ICharaTraits:decrement_trait(trait_id, no_message)
   local trait = data["base.trait"]:ensure(trait_id)

   if self.traits[trait_id] == nil then
      self.traits[trait_id] = { level = 0 }
   elseif self.traits[trait_id].level <= trait.level_min then
      return false
   end

   local prev_level = self.traits[trait_id].level

   self.traits[trait_id].level = self.traits[trait_id].level - 1

   if not no_message then
      local mes = I18N.localize_optional("base.trait", trait_id, "on_lose_level")
      if mes then
         Gui.mes_c(mes, "Red")
      else
         Log.warn("No trait lose level message for '%s'", trait_id)
      end
   end

   if self.traits[trait_id].level == 0 then
      self.traits[trait_id] = nil
   end

   if trait.on_modify_level then
      local cur_level = self:trait_level(trait_id)
      trait.on_modify_level(cur_level, self, prev_level)
   end

   return true
end

return ICharaTraits
