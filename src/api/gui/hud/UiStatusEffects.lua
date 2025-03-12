local data = require("internal.data")
local Draw = require("api.Draw")
local Event = require("api.Event")
local ISettable = require("api.gui.ISettable")
local IUiWidget = require("api.gui.IUiWidget")
local UiTheme = require("api.gui.UiTheme")
local I18N = require("api.I18N")

local UiStatusEffects = class.class("UiStatusEffects", {ISettable, IUiWidget})

function UiStatusEffects:init()
   self.indicators = {}
   self.max_width = 50
   self.base_y = 0
end

local function make_status_indicators(_, params, result)
   local chara = params.chara

   for _, v in data["base.ui_indicator"]:iter() do
      if v.indicator then
         local raw = v.indicator(chara)
         if type(raw) == "table" then
            raw.text = I18N.get_optional(raw.text) or raw.text
            result[#result+1] = raw
         end
      end
   end

   return result
end

function UiStatusEffects:default_widget_refresh(player)
   self:set_data(player)
end

local hook_make_status_indicators =
   Event.define_hook("make_status_indicators",
                     "Gets the list of status indicators to display.",
                     {},
   nil,
   make_status_indicators)

function UiStatusEffects:set_data(player)
   self.indicators = {}
    -- TODO: allow source in hook
   local raw = hook_make_status_indicators({chara=player})

   for _, ind in ipairs(raw) do
      if type(ind) == "table" then
         self.indicators[#self.indicators + 1] = ind
      end
   end

   if self.t then
      self:calc_max_width()
   end
end

function UiStatusEffects:calc_max_width()
   self.max_width = 50
   Draw.set_font(self.t.base.status_indicator_font)
   for _, indicator in ipairs(self.indicators) do
      self.max_width = math.max(self.max_width, Draw.text_width(indicator.text) + 20)
   end

   self.height = math.min(#self.indicators * 20, self.base_height or 10000)
   self.y = self.base_y - self.height
end

function UiStatusEffects:default_widget_position(x, y, width, height)
   return x + 8, height - (72 + 16) - 50
end

function UiStatusEffects:relayout(x, y, width, height)
   self.width = width
   self.base_height = height
   self.x = x
   self.base_y = y
   self.t = UiTheme.load(self)

   self:calc_max_width()
end

function UiStatusEffects:draw()
   Draw.set_font(self.t.base.status_indicator_font)
   local y = self.y
   for _, indicator in ipairs(self.indicators) do
      Draw.set_color(255, 255, 255)
      self.t.base.status_effect_bar:draw(self.x, y, self.max_width, nil, nil)
      if indicator.color then
         Draw.set_color(indicator.color)
      else
         Draw.set_color(0, 0, 0)
      end
      Draw.text(indicator.text, self.x + 6, y + 1) -- y + vfix + 1
      y = y + 20
   end
end

function UiStatusEffects:update()
end

return UiStatusEffects
