local IComparable = require("api.IComparable")
local IDrawable = require("api.gui.IDrawable")
local Draw = require("api.Draw")

local CardDrawable = class.class("CardDrawable", { IDrawable, IComparable })

function CardDrawable:init(chip_id, color)
   self.dirty = true
   self.batch = nil
   self.chip_id = chip_id
   self.color = color
end

function CardDrawable:serialize()
   self.batch = nil
end

function CardDrawable:deserialize()
   self.dirty = true
end

function CardDrawable:update(dt)
end

function CardDrawable:draw(x, y, w, h, centered, rot)
   if self.dirty then
      self.batch = Draw.make_chip_batch("chip")
      self.dirty = false
   end

   -- >>>>>>>> shade2/module.hsp:576 	:if %%1=528:gmode 2:pos 0,960:gcopy selItem,0,768, ...
   if self.chip_id and self.chip_id ~= "" then
      Draw.set_color(255, 255, 255, 255)
      self.batch:clear()
      self.batch:add(self.chip_id, x + 6, y + 14, 22, 20, self.color)
      self.batch:draw()
   end
   -- <<<<<<<< shade2/module.hsp:576 	:if %%1=528:gmode 2:pos 0,960:gcopy selItem,0,768, ..
end

function CardDrawable:compare(other)
   if self.chip_id ~= other.chip_id then
      return false
   end

   if self.color and other.color then
      return table.deepcompare(self.color, other.color)
   end

   return self.color == nil and other.color == nil
end

return CardDrawable
