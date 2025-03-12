local config = require("internal.config")
local save = require("internal.global.save")
local shadow_batch = require("internal.draw.shadow_batch")
local Chara = require("api.Chara")
local Draw = require("api.Draw")
local IDrawLayer = require("api.gui.IDrawLayer")
local Pos = require("api.Pos")
local Rand = require("api.Rand")
local UiTheme = require("api.gui.UiTheme")
local Gui = require("api.Gui")

local shadow_layer = class.class("shadow_layer", IDrawLayer)

function shadow_layer:init(width, height)
   self.width = width
   self.height = height
   self.shadow_batch = shadow_batch:new(self.width, self.height)
   self.lights = {}
   self.frames = 0
   self.reupdate_light = false
end

function shadow_layer:default_z_order()
   return Gui.LAYER_Z_ORDER_TILEMAP + 60000
end

function shadow_layer:on_theme_switched(coords)
   self.coords = coords
   self.shadow_batch:on_theme_switched(nil, coords)
end

function shadow_layer:relayout()
   self.t = UiTheme.load(self)
end

function shadow_layer:reset()
   self.batch_inds = {}
   self.lights = {}
   self.frames = 0
   self.reupdate_light = false
end

function shadow_layer:rebuild_light(map)
   self.lights = {}

   local player = Chara.player()
   local hour = save.base.date.hour

   local shadow = save.base.shadow
   local has_light_source = save.base.has_light_source

   if player then
      for _, item in player:iter_items() do
         if item:calc("is_light_source") then
            has_light_source = true
            break
         end
      end
   end

   local is_dungeon = map:has_type("dungeon")
   if has_light_source and is_dungeon then
      shadow = shadow - 50
   end

   if player then
      for _, x, y, _ in map:iter_tiles() do
         local light = map:light(x, y)
         if light then
            local show_light = light.always_on or (hour > 17 or hour < 6)
            if show_light then
               local power = 6 - Pos.dist(player.x, player.y, x, y)
               power = math.clamp(power, 0, 6) * light.power
               shadow = shadow - power

               if map:is_in_fov(x, y) then
                  local sx, sy = self.coords:tile_to_screen(x, y)
                  table.insert(self.lights, {
                                  chip = light.chip,
                                  flicker = light.flicker,
                                  brightness = light.brightness,
                                  x = sx,
                                  y = sy,
                                  offset_y = light.offset_y,
                                  color = {255, 255, 255, 255},
                                  frame = 1
                  })
               end
            end
         end
      end
   end

   shadow = math.max(shadow, 25)

   self.shadow_batch.shadow_strength = shadow
end

function shadow_layer:update_light_flicker()
   for _, light in ipairs(self.lights) do
      local flicker = light.brightness + Rand.rnd(light.flicker + 1)
      light.color[4] = flicker

      local frame_count = #self.t.base[light.chip].quads
      if frame_count > 1 then
         light.frame = Rand.rnd(frame_count) + 1
      else
         light.frame = 1
      end
   end
end

function shadow_layer:update(map, dt, screen_updated)
   self.frames = self.frames + dt / (config.base.screen_refresh * (16.66 / 1000))
   if self.frames > 1 then
      self.frames = math.fmod(self.frames, 1)
      self.reupdate_light = true
   end

   if screen_updated then
      self:rebuild_light(map)
   end

   if screen_updated or self.reupdate_light then
      self:update_light_flicker()
      self.reupdate_light = false
   end

   if not screen_updated then return false end

   self.shadow_batch.updated = true

   assert(map ~= nil)

   local shadow_map, offset_tx, offset_ty = map:shadow_map()
   if #shadow_map > 0 then
      self.shadow_batch:set_tiles(shadow_map, offset_tx, offset_ty)
   end

   return false
end

function shadow_layer:draw(draw_x, draw_y, width, height)
   Draw.set_blend_mode("add")
   for _, light in ipairs(self.lights) do
      local asset = self.t.base[light.chip]
      local x = draw_x + light.x
      local y = draw_y + light.y - light.offset_y
      if #asset.quads == 0 then
         asset:draw(x, y, nil, nil, light.color)
      else
         asset:draw_region(light.frame, x, y, nil, nil, light.color)
      end
   end

   self.shadow_batch:draw(draw_x, draw_y, width, height)
end

return shadow_layer
