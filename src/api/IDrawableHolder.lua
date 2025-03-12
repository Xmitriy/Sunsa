local IDrawable = require("api.gui.IDrawable")
local PriorityMap = require("api.PriorityMap")

local IDrawableHolder = class.interface("IDrawableHolder", {})

function IDrawableHolder:init()
   self.drawables = nil
   self.drawables_after = nil
end

function IDrawableHolder:set_drawable(tag, drawable, where, priority)
   where = where or "below"

   local drawables
   if where == "above" then
      drawables = "drawables_after"
   elseif where == "below" then
      drawables = "drawables"
   else
      error("Invalid drawable position " .. tostring(where))
   end

   if drawable then
      class.assert_is_an(IDrawable, drawable)

      if self[drawables] == nil then
         self[drawables] = PriorityMap:new()
      end
   else
      if self[drawables] == nil then
         return
      end
   end

   self[drawables]:set(tag, drawable, priority)

   if self[drawables]:len() == 0 then
      self[drawables] = nil
   end
end

function IDrawableHolder:get_drawable(tag, where)
   where = where or "below"

   local drawables
   if where == "above" then
      drawables = "drawables_after"
   elseif where == "below" then
      drawables = "drawables"
   else
      error("Invalid drawable position " .. tostring(where))
   end

   if self[drawables] then
      return self[drawables]:get(tag)
   end

   return nil
end

return IDrawableHolder
