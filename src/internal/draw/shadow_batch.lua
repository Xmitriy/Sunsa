local IBatch = require("internal.draw.IBatch")
local Draw = require("api.Draw")
local draw = require("internal.draw")
local UiTheme = require("api.gui.UiTheme")

local shadow_batch = class.class("shadow_batch", IBatch)

local deco = {
--                 W           E            WE          S            S E          SW           SWE
-- 0000         0001         0010         0011         0100         0101         0110         0111
   { 0, 0,  0}, { 0, 1,  0}, { 1, 2,  0}, { 0, 0,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  00000000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  00001000 N
   {-1, 1,  0}, { 0, 1,  0}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  00010000
   { 2, 1,  1}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  00011000 N
   {-1, 2,  0}, { 0, 1,  0}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  00100000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  00101000 N
   {-1, 5,  0}, { 0, 1,  2}, { 1, 2,  1}, { 0, 2,  0}, { 1, 0,  2}, { 0, 0,  2}, {-1, 21, 0}, {-1, 30, 0},  --  00110000
   { 2, 1,  1}, {-1, 20, 0}, { 2, 2,  1}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  00111000 N
   {-1, 3,  0}, { 0, 1,  0}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  01000000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  01001000 N
   {-1, 9,  0}, { 0, 1,  0}, { 1, 2,  1}, { 0, 2,  0}, { 1, 0,  3}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  01010000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, { 0, 1,  0}, { 2, 0,  0}, { 0, 1,  0}, {-1, 31, 0}, { 3, 1,  0},  --  01011000 N
   {-1, 7,  0}, { 0, 1,  2}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  01100000
   { 2, 1,  3}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  01101000 N
   {-1, -1, 0}, { 0, 1,  2}, { 1, 2,  1}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  2}, {-1, 21, 0}, {-1, 30, 0},  --  01110000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  1}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  01111000 N
   {-1, 4,  0}, { 0, 1,  0}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  10000000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  10001000 N
   {-1, 8,  0}, { 0, 1,  4}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  10010000
   { 2, 1,  1}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  10011000 N
   {-1, 10, 0}, { 0, 1,  0}, { 1, 2,  4}, { 0, 2,  0}, { 1, 0,  2}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  10100000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  10101000 N
   {-1, -1, 0}, { 0, 1,  0}, { 1, 2,  8}, { 0, 2,  0}, { 1, 0,  2}, { 0, 0,  2}, {-1, 21, 0}, {-1, 30, 0},  --  10110000
   { 2, 1,  1}, {-1, 20, 0}, { 2, 2,  1}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  10111000 N
   {-1, 6,  0}, { 0, 1,  0}, { 1, 2,  4}, { 0, 2,  4}, { 1, 0,  3}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  11000000
   { 2, 1,  3}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  3}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  11001000 N
   {-1, -1, 0}, { 0, 1,  4}, { 1, 2,  0}, { 0, 2,  0}, { 1, 0,  3}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  11010000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  3}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  11011000 N
   {-1, -1, 0}, { 0, 1,  0}, { 1, 2,  4}, { 0, 2,  0}, { 1, 0,  0}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  11100000
   { 2, 1,  3}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  3}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  --  11101000 N
   {-1, -1, 0}, { 0, 1, 10}, { 1, 2,  8}, { 0, 2,  4}, { 1, 0,  7}, { 0, 0,  0}, {-1, 21, 0}, {-1, 30, 0},  --  11110000
   { 2, 1,  0}, {-1, 20, 0}, { 2, 2,  0}, {-1, 33, 0}, { 2, 0,  0}, {-1, 32, 0}, {-1, 31, 0}, { 3, 1,  0},  -- 100000000
};

local shadowmap = {
    0, 9, 10, 5, 12, 7, 0, 1, 11, 0, 6, 3, 8, 4, 2, 0, 0,
};

function shadow_batch:init(width, height)
   self.width = width
   self.height = height

   self.tiles = table.of_2d(0, width + 4, height + 4, true)

   self.quad = {}
   self.corner_quad = {}
   self.edge_quad = {}

   self.updated = true
   self.tile_width = 48
   self.tile_height = 48

   self.shadow_strength = 70
end

function shadow_batch:on_theme_switched(atlas, coords)
   self.coords = coords

   self.t = UiTheme.load(self)
   self.image = self.t.base.shadow.image
   self.edge_image = self.t.base.shadow_edges.image
   self.batch = love.graphics.newSpriteBatch(self.image)
   self.edge_batch = love.graphics.newSpriteBatch(self.edge_image)
   self.offset_tx = 0
   self.offset_ty = 0

   self.quad = {}
   self.corner_quad = {}
   self.edge_quad = {}

   local iw,ih
   iw = self.image:getWidth()
   ih = self.image:getHeight()
   for i=1,8 do
      self.quad[i] = {}
      for j=1,6 do
         self.quad[i][j] = love.graphics.newQuad((i-1) * 24, (j-1) * 24, 24, 24, iw, ih)
      end
   end
   for i=1,4 do
      for j=1,3 do
         self.corner_quad[(j-1)*4+i] = love.graphics.newQuad((i-1) * 48, (j-1) * 48, 48, 48, iw, ih)
      end
   end

   iw = self.edge_image:getWidth()
   ih = self.edge_image:getHeight()
   for i=1,17 do
      self.edge_quad[i] = love.graphics.newQuad((i-1) * 48, 0, 48, 48, iw, ih)
   end

   self.updated = true
end

function shadow_batch:relayout()
end

function shadow_batch:find_bounds(x, y)
   return -1, -1, draw.get_tiled_width() + 2, draw.get_tiled_height() + 2
end

function shadow_batch:set_tiles(tiles, offset_tx, offset_ty)
   self.tiles = tiles
   self.width = #tiles + (tiles[0] ~= nil and 1 or 0)
   self.height = #tiles[1] + (tiles[1][0] ~= nil and 1 or 0)
   self.offset_tx = offset_tx
   self.offset_ty = offset_ty
   self.updated = true
end

function shadow_batch:update_tile(x, y, tile)
   if x >= 0 and y >= 0 and x < self.width and y < self.height then
      self.tiles[y*self.width+x+1] = tile
      self.updated = true
   end
end

function shadow_batch:add_one_deco(d, x, y)
   if d == 1 then
      -- upper-left inner
      self.batch:add(self.quad[8][2], x, y)
   elseif d == 2 then
      -- lower-right inner
      self.batch:add(self.quad[7][1], x + 24, y + 24)
   elseif d == 3 then
      -- lower-left inner
      self.batch:add(self.quad[8][1], x, y + 24)
   elseif d == 4 then
      -- upper-right inner
      self.batch:add(self.quad[7][2], x + 24, y)
   elseif d == 5 then
      -- upper-left inner
      -- lower-right inner
      self.batch:add(self.quad[7][1], x + 24, y + 24)
      self.batch:add(self.quad[8][2], x, y)
   elseif d == 6 then
      -- upper-right inner
      -- lower-left inner
      self.batch:add(self.quad[8][1], x, y + 24)
      self.batch:add(self.quad[7][2], x + 24, y)
   elseif d == 7 then
      -- lower-right inner
      -- lower-left inner
      self.batch:add(self.quad[8][1], x, y + 24)
      self.batch:add(self.quad[7][1], x + 24, y + 24)
   elseif d == 8 then
      -- upper-right inner
      -- upper-left inner
      self.batch:add(self.quad[8][2], x, y)
      self.batch:add(self.quad[7][2], x + 24, y)
   elseif d == 9 then
      -- upper-left inner
      -- lower-left inner
      self.batch:add(self.quad[8][2], x, y)
      self.batch:add(self.quad[8][1], x, y + 24)
   elseif d == 10 then
      -- upper-right inner
      -- lower-right inner
      self.batch:add(self.quad[7][2], x + 24, y)
      self.batch:add(self.quad[7][1], x + 24, y + 24)
   elseif d == 20 then
      -- left border
      -- right border
      self.batch:add(self.quad[1][3], x, y)
      self.batch:add(self.quad[1][4], x, y + 24)
      self.batch:add(self.quad[6][3], x + 24, y)
      self.batch:add(self.quad[6][4], x + 24, y + 24)
   elseif d == 21 then
      -- top border
      -- bottom border
      self.batch:add(self.quad[3][1], x, y)
      self.batch:add(self.quad[4][1], x + 24, y)
      self.batch:add(self.quad[3][6], x, y + 24)
      self.batch:add(self.quad[4][6], x + 24, y + 24)
   elseif d == 30 then
      -- right outer dart
      self.batch:add(self.quad[1][1], x, y)
      self.batch:add(self.quad[2][1], x + 24, y)
      self.batch:add(self.quad[1][6], x, y + 24)
      self.batch:add(self.quad[2][6], x + 24, y + 24)
   elseif d == 31 then
      -- left outer dart
      self.batch:add(self.quad[5][1], x, y)
      self.batch:add(self.quad[6][1], x + 24, y)
      self.batch:add(self.quad[5][6], x, y + 24)
      self.batch:add(self.quad[6][6], x + 24, y + 24)
   elseif d == 32 then
      self.batch:add(self.quad[1][1], x, y)
      -- upper outer dart
      self.batch:add(self.quad[1][2], x, y + 24)
      self.batch:add(self.quad[6][1], x + 24, y)
      self.batch:add(self.quad[6][2], x + 24, y + 24)
   elseif d == 33 then
      -- lower outer dart
      self.batch:add(self.quad[1][5], x, y)
      self.batch:add(self.quad[1][6], x, y + 24)
      self.batch:add(self.quad[6][5], x + 24, y)
      self.batch:add(self.quad[6][6], x + 24, y + 24)
   end
end

function shadow_batch:add_deco(shadow, x, y)
   local d0 = deco[shadow+1][1]
   local d1 = deco[shadow+1][2]

   if d0 == -1 then
      self:add_one_deco(d1, x, y)
   else
      -- d0, d1 is x, y index into shadow image by size 48
      self.batch:add(self.corner_quad[d1*4+d0+1], x, y)
   end

   local d2 = deco[shadow+1][3]

   if d2 ~= 0 then
      self:add_one_deco(d2, x, y)
   end
end

function shadow_batch:add_one(shadow, x, y)
   if shadow <= 0 then
      return
   end

   local is_shadow = bit.band(shadow, 0x100) == 0x100

   if not is_shadow then
      -- Tile is lighted. Draw the fancy quarter-size shadow corners
      -- depending on the directions that border a shadow.
      self:add_deco(shadow, x, y)
      return
   end

   -- remove shadow flag
   local p2 = bit.band(bit.bnot(0x100), shadow)

   -- extract the cardinal part (NSEW)
   -- 00001111
   local p3 = bit.band(p2, 0x0F)

   local tile = 0
   if p3 == 0x0F then
      -- All four cardinal directions border a shadow. Check the
      -- corner directions.

      -- extract the intercardinal part
      -- 11110000
      p3 = bit.band(p2, 0xF0)

      if     p3 == 0x70 then -- 0111     SW SE SW
         tile = 13
      elseif p3 == 0xD0 then -- 1101  NE SW    NW
         tile = 14
      elseif p3 == 0xB0 then -- 1011  NE    SE NW
         tile = 15
      elseif p3 == 0xE0 then -- 1110  NE SW SE
         tile = 16
      elseif p3 == 0xC0 then -- 1100  NE SW
         tile = 17
      elseif p3 == 0x30 then -- 0011        SE NW
         tile = 17
      end
   else
      tile = shadowmap[p3+1]
   end

   if tile == 0 then
      self.batch:add(self.corner_quad[12], x, y)
   else
      self.edge_batch:add(self.edge_quad[tile], x, y)
   end
end

function shadow_batch:draw(x, y, width, height)
   local offx, offy = 0, 0
   x = x + offx
   y = y + offy

   if self.updated then
      local tx, ty, tdx, tdy = self.coords:find_bounds(x, y, width, height)
      local self_tiles = self.tiles
      local offset_tx, offset_ty = self.offset_tx, self.offset_ty

      self.scissor_x, self.scissor_y = self.coords:tile_to_screen(tx + 3, ty + 3)
      self.scissor_width, self.scissor_height = self.coords:tile_to_screen(math.min(tdx-tx, self.width), math.min(tdy-ty, self.height))

      self.batch:clear()
      self.edge_batch:clear()

      for iy=ty-1,tdy+1 do
         if iy >= 0 and iy-ty+1 < self.height then
            for ix=tx-1,tdx+1 do
               if ix >= 0 and ix-tx+1 < self.width then
                  local tiles = self_tiles[ix-tx+1]
                  if tiles then
                     local tile = tiles[iy-ty+1]
                     local i, j = self.coords:tile_to_screen(ix - tx + offset_tx, iy - ty + offset_ty)
                     self:add_one(tile, i, j)
                  else
                     break
                  end
               end
            end
         end
      end

      self.batch:flush()
      self.edge_batch:flush()

      self.updated = false
   end

   local i = math.ceil((x % 48) / self.tile_width)
   local j = math.ceil((y % 48) / self.tile_height)
   local ocx, ocy = self.coords:tile_to_screen(self.offset_tx + i, self.offset_ty + j)
   local scx, scy = x + ocx, y + ocy
   local scw, sch = self.scissor_width, self.scissor_height

   Draw.set_scissor(scx, scy, scw, sch)
   Draw.set_color(255, 255, 255, self.shadow_strength)
   Draw.set_blend_mode("subtract")
   Draw.image(self.batch, x, y)
   Draw.image(self.edge_batch, x, y)
   Draw.set_scissor()
   Draw.set_color(255, 255, 255, self.shadow_strength * ((256-9) / 256))
   if x < scx then
      Draw.filled_rect(x, scy, scx - x, sch + height * 2)
   end
   if y < scy then
      Draw.filled_rect(x, y, scw + width, scy - y)
   end
   if scx + scw < width then
      Draw.filled_rect(scx + scw, scy, width - (scx + scw), sch + height * 2)
   end
   if scy + sch < height then
      Draw.filled_rect(scx, scy + sch, scw, height - (scy + sch))
   end
   Draw.set_blend_mode("alpha")
end

return shadow_batch
