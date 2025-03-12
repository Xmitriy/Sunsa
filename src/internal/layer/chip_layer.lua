local IDrawLayer = require("api.gui.IDrawLayer")
local Draw = require("api.Draw")
local Gui = require("api.Gui")
local UiTheme = require("api.gui.UiTheme")
local sparse_batch = require("internal.draw.sparse_batch")
local atlas = require("internal.draw.atlas")
local atlases = require("internal.global.atlases")

local chip_layer = class.class("chip_layer", IDrawLayer)

function chip_layer:init(width, height)
   self.width = width
   self.height = height

   self.chip_atlas = nil
   self.item_shadow_atlas = nil

   self.chip_batch = sparse_batch:new(self.width, self.height)
   self.shadow_batch = sparse_batch:new(self.width, self.height)
   self.drop_shadow_batch = sparse_batch:new(self.width, self.height)

   self.chip_batch_inds = {}
   self.shadow_batch_inds = {}
   self.drop_shadow_batch_inds = {}
   self.stacking_inds = {}
   self.uid_to_index = {}

   self.shadow_shader = love.graphics.newShader([[
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 textureColor = Texel(tex, texture_coords);
    return vec4(1, 1, 1, textureColor.a * color.a);
}
]])
end

function chip_layer:default_z_order()
   return Gui.LAYER_Z_ORDER_TILEMAP + 30000
end

function chip_layer:set_atlases(chip_atlas, item_shadow_atlas)
   if chip_atlas ~= nil then
      assert(class.is_an(atlas, chip_atlas))
   end
   if item_shadow_atlas ~= nil then
      assert(class.is_an(atlas, item_shadow_atlas))
   end
   self.chip_atlas = chip_atlas
   self.item_shadow_atlas = item_shadow_atlas
end

function chip_layer:on_theme_switched(coords)
   local chip_atlas = self.chip_atlas or atlases.get().chip
   local item_shadow_atlas = self.item_shadow_atlas or atlases.get().item_shadow

   local shadow_atlas = atlas:new(48, 48)
   self.t = UiTheme.load(self)

   local tiles = {{
         _id = "shadow",
         image = self.t.base.character_shadow
   }}
   shadow_atlas:load(tiles, coords)

   self.chip_batch:on_theme_switched(chip_atlas, coords)
   self.shadow_batch:on_theme_switched(shadow_atlas, coords)
   self.drop_shadow_batch:on_theme_switched(item_shadow_atlas, coords)
end

function chip_layer:relayout()
   self.t = UiTheme.load(self)
end

function chip_layer:reset()
   self.chip_batch_inds = {}
   self.shadow_batch_inds = {}
   self.drop_shadow_batch_inds = {}
   self.stacking_inds = {}
   self.uid_to_index = {}

   self.chip_batch:clear()
   self.shadow_batch:clear()
   self.drop_shadow_batch:clear()
end

function chip_layer:draw_drop_shadow(index, i, x, y, y_offset)
   local batch_ind = self.drop_shadow_batch_inds[index]
   local image = i.image
   local x_offset = i.x_offset or 0
   local rotation = i.shadow_angle or 20

   -- TODO no idea what the rotation amounts should be
   x_offset = x_offset + rotation / 8
   y_offset = y_offset - 2
   rotation = rotation / 16

   local draw = true

   if draw then
      if batch_ind == nil then
         self.drop_shadow_batch_inds[index] = self.drop_shadow_batch:add_tile(index, {
            tile = image,
            x = x,
            y = y,
            x_offset = x_offset,
            y_offset = y_offset,
            rotation = math.rad(rotation),
            z_order = 0,
         })
      else
         self.drop_shadow_batch:set_tile_image(index, image)
         self.drop_shadow_batch.xcoords[index] = x
         self.drop_shadow_batch.ycoords[index] = y
         self.drop_shadow_batch.xoffs[index] = x_offset
         self.drop_shadow_batch.yoffs[index] = y_offset
         self.drop_shadow_batch.rotations[index] = math.rad(rotation)
         self.drop_shadow_batch.updated = true
      end
   else
      self.drop_shadow_batch:remove_tile(index)
      self.drop_shadow_batch_inds[index] = nil
   end
end

local CONFIG = {
   ["base.chara"] = {
      z_order = 3,
      y_offset = 0
   },
   ["base.item"] = {
      z_order = 2,
      y_offset = 0,
      show_memory = true,
      is_stacking = true
   },
   ["base.mef"] = {
      z_order = 1,
      y_offset = 0,
      show_memory = true
   },
   ["base.feat"] = {
      z_order = 0,
      y_offset = 0,
      show_memory = true
   }
}

local TYPES = table.keys(CONFIG)

function chip_layer:draw_one(index, ind, x, y, i, chip_type, map_size, z_order)
   local shadow_type = i.shadow_type
   local batch_ind = self.chip_batch_inds[index]
   local image = i.drawable or i.image
   local x_offset = i.x_offset or 0
   local y_offset_base = CONFIG[chip_type].y_offset
   local y_offset = (i.y_offset or 0) + y_offset_base
   local z_order = ind * CONFIG[chip_type].z_order * map_size + z_order
   local is_stacking = CONFIG[chip_type].is_stacking
   if batch_ind == nil then
      -- tiles at the top of the screen should be drawn
      -- first, so they have the lowest z-order. conveniently
      -- this is already representable by tile indices since
      -- index 0 represents (0, 0), 1 represents (1, 0), and
      -- so on.

      self.chip_batch:add_tile(index, {
         tile = image,
         x = x,
         y = y,
         x_offset = x_offset,
         y_offset = y_offset,
         color = i.color,
         z_order = z_order,
         drawables = i.drawables,
         drawables_after = i.drawables_after,
      })

      -- Extra data needed for rendering non-chip things like
      -- the HP bar.
      batch_ind = {
         index = index,
         ind = ind,
         is_stacking = is_stacking,
         x = x,
         y = y,
         y_offset = y_offset,
         x_scroll_offset = 0,
         y_scroll_offset = 0,
         hp_ratio = i.hp_ratio,
         hp_bar = i.hp_bar,
         stack_height = i.stack_height
      }
      self.chip_batch_inds[index] = batch_ind

      if batch_ind.is_stacking then
         self.stacking_inds[ind] = self.stacking_inds[ind] or {}
         table.insert(self.stacking_inds[ind], index)
      end
   else
      self.chip_batch:set_tile_image(index, image)
      self.chip_batch.xcoords[index] = x
      self.chip_batch.ycoords[index] = y
      self.chip_batch.xoffs[index] = x_offset
      self.chip_batch.yoffs[index] = y_offset
      if i.color then
         self.chip_batch.colors_r[index] = (i.color[1] or 255) / 255
         self.chip_batch.colors_g[index] = (i.color[2] or 255) / 255
         self.chip_batch.colors_b[index] = (i.color[3] or 255) / 255
      else
         self.chip_batch.colors_r[index] = 1
         self.chip_batch.colors_g[index] = 1
         self.chip_batch.colors_b[index] = 1
      end
      self.chip_batch:set_z_order(index, z_order)
      self.chip_batch.drawables[index] = i.drawables
      self.chip_batch.drawables_after[index] = i.drawables_after
      self.chip_batch.updated = true

      if batch_ind.is_stacking then
         local old_ind = batch_ind.ind
         self.stacking_inds[old_ind] = self.stacking_inds[old_ind] or {}
         table.iremove_value(self.stacking_inds[old_ind], index)

         self.stacking_inds[ind] = self.stacking_inds[ind] or {}
         table.insert(self.stacking_inds[ind], index)

         -- Refresh stacking chip for both tiles
         self.stacking_inds[old_ind].is_chip_set = nil
         self.stacking_inds[ind].is_chip_set = nil
      end

      batch_ind.ind = ind
      batch_ind.x = x
      batch_ind.y = y
      batch_ind.y_offset = y_offset
      batch_ind.hp_ratio = i.hp_ratio
      batch_ind.hp_bar = i.hp_bar
      batch_ind.stack_height = i.stack_height
   end

   if batch_ind.shadow_type ~= shadow_type then
      if batch_ind.shadow_type == "normal" then
         self.shadow_batch:remove_tile(index)
         self.shadow_batch_inds[index] = nil
         self.shadow_batch.updated = true
      elseif batch_ind.shadow_type == "drop_shadow" then
         self.drop_shadow_batch:remove_tile(index)
         self.drop_shadow_batch_inds[index] = nil
         self.drop_shadow_batch.updated = true
      end
   end

   if shadow_type == "drop_shadow" then

      --
      -- Item drop shadow.
      --
      self:draw_drop_shadow(index, i, x, y, y_offset)
   elseif shadow_type == "normal" then
      if self.shadow_batch_inds[index] then
         self.shadow_batch.xcoords[index] = x
         self.shadow_batch.ycoords[index] = y
         self.shadow_batch.yoffs[index] = 0
         self.shadow_batch.updated = true
      else
         self.shadow_batch:add_tile(index, {
            tile = "shadow",
            x = x,
            y = y,
            y_offset = 0,
            z_order = 0
         })
         self.shadow_batch_inds[index] = true
      end
   end
end

function chip_layer:scroll_chip(index, sx, sy)
   self.chip_batch.x_scroll_offs[index] = -sx
   self.chip_batch.y_scroll_offs[index] = -sy
   self.chip_batch.updated = true

   self.shadow_batch.x_scroll_offs[index] = -sx
   self.shadow_batch.y_scroll_offs[index] = -sy
   self.shadow_batch.updated = true

   local batch_ind = self.chip_batch_inds[index]
   batch_ind.x_scroll_offset = -sx
   batch_ind.y_scroll_offset = -sy
end

function chip_layer:draw_normal(index, ind, map, mem, chip_type)
   local x = (ind-1) % map:width()
   local y = math.floor((ind-1) / map:width())

   local show = mem.show
   if map._in_sight[ind] ~= map._last_sight_id then -- if not map:is_in_fov(x, y) then
      show = show and CONFIG[chip_type].show_memory
   end

   if show then
      local z_order = map._object_memory_z_order[index]
      self:draw_one(index, ind, x, y, mem, chip_type, map:width() * map:height(), z_order)
   end
end

function chip_layer:set_stacking_chip(ind)
   local stack = self.stacking_inds[ind]
   local index = stack[1]

   if stack.is_chip_set then
      return
   end

   self.chip_batch:set_tile_image(index, "elona.item_stack")
   self.chip_batch.xoffs[index] = 0
   self.chip_batch.yoffs[index] = 0
   self.chip_batch.colors_r[index] = 1
   self.chip_batch.colors_g[index] = 1
   self.chip_batch.colors_b[index] = 1
   self.chip_batch.drawables[index] = nil
   self.chip_batch.drawables_after[index] = nil
   self.chip_batch.hiddens[index] = nil

   self.drop_shadow_batch:set_tile_image(index, "elona.item_stack")
   self.drop_shadow_batch.yoffs[index] = 0
   self.shadow_batch.yoffs[index] = 0

   stack.is_chip_set = true
end

function chip_layer:unset_stacking_chip(ind, map, mem)
   local stack = self.stacking_inds[ind]
   local index = stack[1]

   if not stack.is_chip_set then
      return
   end

   local x = (ind-1) % map:width()
   local y = math.floor((ind-1) / map:width())
   local chip_type = mem._type

   self:draw_normal(index, ind, map, mem, chip_type)

   stack.is_chip_set = nil
end

function chip_layer:update_stacking(map)
   for ind, stack in pairs(self.stacking_inds) do
      local x = (ind-1) % map:width()
      local y = math.floor((ind-1) / map:width())

      if #stack > 3 then
         for i = 2, #stack do
            local index = stack[i]
            self.chip_batch.hiddens[index] = true
            self.shadow_batch.hiddens[index] = true
            self.drop_shadow_batch.hiddens[index] = true
         end

         local first_ind = stack[1]
         self.drop_shadow_batch.hiddens[first_ind] = nil
         self.drop_shadow_batch:set_tile_image(first_ind, "elona.item_stack")

         self:set_stacking_chip(ind)
      else
         local stack_height = 0
         local map_size = map:width() * map:height()

         for _, index in ipairs(stack) do
            local batch_ind = self.chip_batch_inds[index]
            self.chip_batch.hiddens[index] = nil
            self.shadow_batch.hiddens[index] = nil
            self.drop_shadow_batch.hiddens[index] = nil

            local yoff = batch_ind.y_offset - stack_height

            self.chip_batch.yoffs[index] = yoff
            self.shadow_batch.yoffs[index] = yoff
            self.drop_shadow_batch.yoffs[index] = yoff
            stack_height = stack_height + batch_ind.stack_height or 0

            local mem = map._object_memory[index]
            local z_order = ind * CONFIG[mem._type].z_order * map_size + map._object_memory_z_order[index]

            self.chip_batch:set_z_order(index, z_order)
            self.shadow_batch:set_z_order(index, z_order)
            self.drop_shadow_batch:set_z_order(index, z_order)
         end

         self:unset_stacking_chip(ind, map, map._object_memory[stack[1]])
      end
   end
end

function chip_layer:update(map, dt, screen_updated)
   self.chip_batch:update(dt)
   self.drop_shadow_batch:update(dt)

   if not screen_updated then return end

   assert(map ~= nil)

   if map._redraw_all then
      self:reset()
      map._redraw_all = false
   end

   for index, _ in pairs(map._object_memory_removed) do
      local batch_ind = self.chip_batch_inds[index]

      self.chip_batch_inds[index] = nil
      self.shadow_batch_inds[index] = nil
      self.drop_shadow_batch_inds[index] = nil

      self.chip_batch:remove_tile(index)
      self.shadow_batch:remove_tile(index)
      self.drop_shadow_batch:remove_tile(index)

      local stacked = batch_ind and batch_ind.is_stacking and self.stacking_inds[batch_ind.ind]
      if stacked then
         local old_ind = batch_ind.ind
         table.iremove_value(self.stacking_inds[old_ind], index)
         if #self.stacking_inds[old_ind] == 0 then
            self.stacking_inds[old_ind] = nil
         end
      end
   end
   table.clear(map._object_memory_removed)

   for index, _ in pairs(map._object_memory_added) do
      local mem = map._object_memory[index]
      if mem then
         local ind = map._object_memory_pos[index]
         local chip_type = mem._type
         self:draw_normal(index, ind, map, mem, chip_type)
      end
   end
   table.clear(map._object_memory_added)

   table.clear(self.uid_to_index)
   for index, ind in pairs(map._object_memory_pos) do
      if map._in_sight[ind] == map._last_sight_id then -- if map:is_in_fov(x, y) then
         local mem = map._object_memory[index]
         if mem then
            self.uid_to_index[mem.uid] = index
         end
      else
         local mem = map._object_memory[index]
         if mem and not CONFIG[mem._type].show_memory then
            local batch_ind = self.chip_batch_inds[index]

            self.chip_batch_inds[index] = nil
            self.shadow_batch_inds[index] = nil
            self.drop_shadow_batch_inds[index] = nil

            self.chip_batch:remove_tile(index)
            self.shadow_batch:remove_tile(index)
            self.drop_shadow_batch:remove_tile(index)

            if batch_ind and batch_ind.is_stacking and self.stacking_inds[batch_ind.ind] then
               local old_ind = batch_ind.ind
               table.iremove_value(self.stacking_inds[old_ind], index)
               if #self.stacking_inds[old_ind] == 0 then
                  self.stacking_inds[old_ind] = nil
               end
            end
         end
      end
   end

   self:update_stacking(map)
end

function chip_layer:draw_hp_bars(draw_x, draw_y, offx, offy)
   -- TODO: rewrite this as a batched draw layer
   for _, ind in pairs(self.chip_batch_inds) do
      if ind.hp_bar then
         if self["i_" .. ind.hp_bar] == nil then
            self["i_" .. ind.hp_bar] = self.t.base[ind.hp_bar]:make_instance()
         end

         local ratio = math.clamp(ind.hp_ratio or 1.0, 0.0, 1.0)
         self["i_" .. ind.hp_bar]:draw_percentage_bar(draw_x + offx + ind.x * 48 + ind.x_scroll_offset + 9,
                                                      draw_y + offy + ind.y * 48 + ind.y_scroll_offset + CONFIG["base.chara"].y_offset + 48,
                                                      ratio * 30)
      end
   end
end

function chip_layer:draw(draw_x, draw_y, width, height)
   local offx, offy = 0, 0
   love.graphics.setShader(self.shadow_shader)
   Draw.set_color(255, 255, 255, 80)
   Draw.set_blend_mode("subtract")
   self.drop_shadow_batch:draw(draw_x, draw_y, width, height)
   love.graphics.setShader()

   Draw.set_blend_mode("subtract")
   Draw.set_color(255, 255, 255, 110)
   self.shadow_batch:draw(draw_x + 8, draw_y + 36, width, height)

   Draw.set_color(255, 255, 255)
   Draw.set_blend_mode("alpha")
   self.chip_batch:draw(draw_x, draw_y, width, height)

   self:draw_hp_bars(draw_x, draw_y, offx, offy)
end

return chip_layer
