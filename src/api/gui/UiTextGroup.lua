local Draw = require("api.Draw")
local Ui = require("api.Ui")
local IUiElement = require("api.gui.IUiElement")
local ISettable = require("api.gui.ISettable")
local I18N = require("api.I18N")

local UiTextGroup = class.class("UiTextGroup", {IUiElement, ISettable})

function UiTextGroup:init(texts, font, color, rows, columns, item_width, item_height)
   self.texts = texts or {}
   self.draw_texts = {}
   self.font_width, self.font_style = Ui.unpack_font_desc(font or 14)
   self.color = color or {20, 10, 0}
   self.rows = rows or 1
   self.columns = columns
   self.item_width = item_width or 190
   self.item_height = item_height or 15

   self:set_data()
end

function UiTextGroup:relayout(x, y)
   self.x = x
   self.y = y
end

function UiTextGroup:iter()
   return fun.iter(self.texts)
end

function UiTextGroup:update()
end

function UiTextGroup:set_data(texts)
   Draw.set_font(self.font_width, self.font_style)
   self.texts = texts or self.texts
   self.draw_texts = fun.iter(self.texts)
       :map(function(i) return Draw.make_text(I18N.get_optional(i) or i) end)
       :to_list()
end

function UiTextGroup:set_text(index, text)
   Draw.set_font(self.font_width, self.font_style)
   self.texts[index] = text
   self.draw_texts[index]:set(text)
end

function UiTextGroup:draw()
   Draw.set_color(self.color[1], self.color[2], self.color[3], self.color[4])
   Draw.set_font(self.font_width, self.font_style)
   if self.rows == 1 and (self.columns or #self.texts) == #self.texts then
      for i, t in ipairs(self.draw_texts) do
         Draw.text(t,
                   self.x,
                   self.y + (i - 1) * self.item_height)
      end
   else
      for i, t in ipairs(self.draw_texts) do
         Draw.text(t,
                   self.x + math.floor((i - 1) / self.rows)    * self.item_width,
                   self.y + (i - 1) % self.columns * self.item_height)
      end
   end
end

return UiTextGroup
