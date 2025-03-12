local IDrawLayer = require("api.gui.IDrawLayer")
local tile_batch = require("internal.draw.tile_batch")
local atlases = require("internal.global.atlases")
local atlas = require("internal.draw.atlas")

local tile_layer = class.class("tile_layer", IDrawLayer)

function tile_layer:init(width, height)
   self.width = width
   self.height = height

   self.atlas = nil
   self.tile_batch = tile_batch:new(self.width, self.height)
   self.tile_width = nil
   self.tile_height = nil
end

function tile_layer:default_z_order()
   return 100000
end

function tile_layer:set_atlas(the_atlas)
   if the_atlas ~= nil then
      assert(class.is_an(atlas, the_atlas))
   end
   self.atlas = the_atlas
end

function tile_layer:on_theme_switched(coords)
   self.coords = coords
   local tile_atlas = self.atlas or atlases.get().tile
   local tw, th = coords:get_size()

   self.tile_batch:on_theme_switched(tile_atlas, coords)
   self.tile_width = tw
   self.tile_height = th
end

function tile_layer:relayout()
end

function tile_layer:reset()
   self.batch_inds = {}
end

function tile_layer:update(map, dt, screen_updated)
   self.tile_batch:update(dt)

   if not screen_updated then return end

   assert(map ~= nil)

   for _, p in ipairs(map._tiles_dirty) do
      local x = (p - 1) % map:width()
      local y = math.floor((p - 1) / map:width())
      local t = map._tile_memory[p]

      if t then
         local id = t._id
         if t.wall then
            local one_tile_down = map:tile(x, y+1)
            local is_memorized = map:is_memorized(x, y+1)
            if one_tile_down ~= nil and not one_tile_down.wall and is_memorized then
               id = t.wall
            end
         end

         self.tile_batch:update_tile(x, y, id)
      else
         self.tile_batch:update_tile(x, y, map.default_tile)
      end
   end

   -- The shadow can only be applied once (inside tile_overhang_layer), because
   -- it's a screen-global effect.
   self.tile_batch.shadow = {0, 0, 0}
   self.tile_batch.updated = true
end

function tile_layer:draw(draw_x, draw_y, width, height)
   self.tile_batch:draw(draw_x, draw_y, width, height)
end

return tile_layer
