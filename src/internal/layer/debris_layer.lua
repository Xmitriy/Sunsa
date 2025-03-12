local UiTheme = require("api.gui.UiTheme")
local Gui = require("api.Gui")
local Map = require("api.Map")
local IDrawLayer = require("api.gui.IDrawLayer")
local Draw = require("api.Draw")

local debris_layer = class.class("debris_layer", IDrawLayer)

function debris_layer:init(width, height)
   self.top_shadows = {}
   self.bottom_shadows = {}
   self.tile_width = nil
   self.tile_height = nil

   self.t = nil

   self.blood_batch = nil
   self.fragment_batch = nil
end

function debris_layer:default_z_order()
   return Gui.LAYER_Z_ORDER_TILEMAP + 10000
end

function debris_layer:on_theme_switched(coords)
   self.coords = coords
   local tw, th = self.coords:get_size()

   self.tile_width = tw
   self.tile_height = th
end

function debris_layer:relayout()
   self.t = UiTheme.load()
   self.blood_asset = self.t.base.debris_blood:make_instance()
   self.fragment_asset = self.t.base.debris_fragment:make_instance()
end

function debris_layer:reset()
   self.top_shadows = {}
   self.bottom_shadows = {}
   self.blood_batch = nil
   self.fragment_batch = nil
end

function debris_layer:update(map, dt, screen_updated)
   if not screen_updated then return end

   assert(map ~= nil)

   local blood_parts = {}
   local fragment_parts = {}

   for ind, d in map:iter_debris_memory() do
      local x = (ind-1) % map:width()
      local y = math.floor((ind-1) / map:width())
      local sx, sy = Gui.tile_to_screen(x, y)

      -- TODO we shouldn't have to allocate new tables here
      if (d.blood or 0) > 0 then
         blood_parts[#blood_parts+1] = { d.blood, sx, sy }
      end
      if (d.fragments or 0) > 0 then
         fragment_parts[#fragment_parts+1] = { d.fragments, sx, sy }
      end
   end

   if self.blood_batch then
      self.blood_batch:release()
   end
   if self.fragment_batch then
      self.fragment_batch:release()
   end
   self.blood_batch = self.blood_asset:make_batch(blood_parts)
   self.fragment_batch = self.fragment_asset:make_batch(fragment_parts)
end

function debris_layer:draw(draw_x, draw_y)
   Draw.set_color(255, 255, 255)

   if self.fragment_batch then
      Draw.image(self.fragment_batch, draw_x, draw_y)
   end
   if self.blood_batch then
      Draw.image(self.blood_batch, draw_x, draw_y)
   end
end

return debris_layer
