local IEventEmitter = require("api.IEventEmitter")
local IMapObject = require("api.IMapObject")
local IModdable = require("api.IModdable")
local Mef = require("api.Mef")
local IObject = require("api.IObject")

-- A mef, short for map effect, is an obstacle that can occupy a tile. There can
-- only be a single mef on a tile at a time.
local IMef = class.interface("IMef", {}, { IMapObject, IModdable, IEventEmitter })

function IMef:pre_build()
   IModdable.init(self)
   IMapObject.init(self)
   IEventEmitter.init(self)
end

function IMef:normal_build(params)
   IObject.normal_build(self, params)
end

function IMef:build()
   self:emit("base.on_build_mef")
end

function IMef:instantiate(no_bind_events)
   IMapObject.instantiate(self, no_bind_events)
   self:emit("base.on_mef_instantiated")
end

function IMef:refresh()
   IMapObject.on_refresh(self)
   if self.on_refresh then
      self:on_refresh()
   end
end

function IMef:step_turn(turns)
   turns = turns or 1
   self:emit("base.on_mef_updated", { turns_elapsed = turns })

   if self.turns > -1 then
      self.turns = math.max(self.turns - turns, -1)

      -- A turn number of -1 signifies the mef should last forever.
      if self.turns == 0 then
         self:remove_ownership()
      end
   end
end

function IMef:produce_memory(memory)
   memory.uid = self.uid
   memory.show = not self:calc("is_invisible")
   memory.image = (self:calc("image") or "")
   memory.color = self:calc("color")
   memory.shadow_type = self:calc("shadow_type")
   memory.drawables = self.drawables
   memory.drawables_after = self.drawables_after
end

--- Sets this mef's position. Use this function instead of updating x and y manually.
---
--- @tparam int x
--- @tparam int y
--- @tparam bool force
--- @treturn bool true on success.
--- @overrides IMapObject.set_pos
function IMef:set_pos(x, y, force)
   local map = self:current_map()
   if not map then
      return false
   end

   if Mef.at(x, y, map) then
      return false
   end

   return IMapObject.set_pos(self, x, y, force)
end

function IMef:get_origin()
   if self.origin_uid == nil then
      return nil
   end

   local map = self:current_map()
   if not map then
      return nil
   end

   return map:get_object(self.origin_uid)
end

return IMef
