local Draw = require("api.Draw")
local Gui = require("api.Gui")
local InstancedMap = require("api.InstancedMap")

local MapRenderer = require("api.gui.MapRenderer")
local IUiLayer = require("api.gui.IUiLayer")
local IInput = require("api.gui.IInput")
local InputHandler = require("api.gui.InputHandler")

local MapViewer = class.class("MapViewer", IUiLayer)

MapViewer:delegate("input", IInput)

function MapViewer:init(map)
   class.assert_is_an(InstancedMap, map)

   self.map = map
   map:iter_tiles():each(function(x, y) map:memorize_tile(x, y) end)
   map:redraw_all_tiles()

   self.renderer = MapRenderer:new(map)

   local tw, th = Draw.get_coords():get_size()
   local mw = self.map:width() * tw
   local mh = self.map:height() * th

   self.offset_x = math.floor((Draw.get_width() - mw) / 2)
   self.offset_y = math.floor((Draw.get_height() - mh) / 2)
   self.delta = math.floor(tw / 2)

   self.input = InputHandler:new()
   self.input:bind_keys(self:make_keymap())
end

function MapViewer:default_z_order()
   return 100000000
end

function MapViewer:make_keymap()
   return {
      north = function() self:pan(0, -self.delta) end,
      south = function() self:pan(0, self.delta) end,
      east = function() self:pan(self.delta, 0) end,
      west = function() self:pan(-self.delta, 0) end,
      cancel = function() self.canceled = true end,
      escape = function() self.canceled = true end,
      enter = function() self.canceled = true end,
   }
end

function MapViewer:on_query()
   Gui.play_sound("base.pop2")
end

function MapViewer:pan(dx, dy)
   self.offset_x = math.floor(self.offset_x + dx)
   self.offset_y = math.floor(self.offset_y + dy)
end

function MapViewer:relayout(x, y, width, height)
   self.x = x
   self.y = y
   self.width = width
   self.height = height

   self.renderer:relayout(self.x, self.y, self.width, self.height)
end

function MapViewer:draw()
   local x = self.x + self.offset_x
   local y = self.y + self.offset_y

   self.renderer.x = x
   self.renderer.y = y

   Draw.set_color(255, 255, 255)
   self.renderer:draw()
end

function MapViewer:update(dt)
   self.renderer:update(dt)

   local canceled = self.canceled
   self.canceled = nil

   if canceled then
      return nil, "canceled"
   end
end

function MapViewer.start(map)
   MapViewer:new(map):query()
end

return MapViewer
