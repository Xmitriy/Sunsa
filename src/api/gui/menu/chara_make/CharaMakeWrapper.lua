local Env = require("api.Env")
local Chara = require("api.Chara")
local Draw = require("api.Draw")
local Gui = require("api.Gui")
local Log = require("api.Log")
local MapObject = require("api.MapObject")
local ICharaMakeMenu = require("api.gui.menu.chara_make.ICharaMakeMenu")

local config = require("internal.config")
local env = require("internal.env")

local CharaMakeCaption = require("api.gui.menu.chara_make.CharaMakeCaption")
local ICharaMakeSection = require("api.gui.menu.chara_make.ICharaMakeSection")
local IInput = require("api.gui.IInput")
local IUiLayer = require("api.gui.IUiLayer")
local InputHandler = require("api.gui.InputHandler")
local UiTheme = require("api.gui.UiTheme")

local CharaMakeWrapper = class.class("CharaMakeWrapper", IUiLayer)

CharaMakeWrapper:delegate("input", IInput)

function CharaMakeWrapper:init(menus)
   self.x = 0
   self.y = 0
   self.width = Draw.get_width()
   self.height = Draw.get_height()
   self.menus = menus
   self.section = nil
   self.section_trail = {}
   self.results = {}
   self.gene_used = "gene"

   self.caption = CharaMakeCaption:new()

   self.input = InputHandler:new()

   self.results[0] = {
      chara = Chara.create("base.player", nil, nil, {ownerless = true, no_build = true})
   }

   self:proceed()
end

function CharaMakeWrapper:make_keymap()
   return {}
end

function CharaMakeWrapper:set_caption(text)
   text = text or self.section.caption
   self.caption:set_data(text)
end

function CharaMakeWrapper:get_in_progress_result()
   return self.results[#self.results]
end

function CharaMakeWrapper:has_next_section()
   if self.section then
      return self.menus[#self.section_trail+2] ~= nil
   else
      return #self.menus > 0
   end
end

function CharaMakeWrapper:proceed()
   repeat
      local menu_id
      if self.section then
         -- previous sections + current section + 1
         menu_id = self.menus[#self.section_trail+2]
      else
         menu_id = self.menus[1]
      end

      local success, layer_class = xpcall(env.safe_require, debug.traceback, menu_id)

      if not success then
         local err = layer_class
         -- TODO turn this into a log warning
         Log.error("Error loading menu %s:\n\t%s", menu_id, err)
         self:go_back()
         return
      elseif class == nil then
         Log.error("Cannot find menu %s", menu_id)
         self:go_back()
         return
      end

      -- Get the result returned from the last menu, or a blank one if
      -- still on the first menu.
      local in_progress_result = self:get_in_progress_result()

      local make_layer = function()
         local sm = layer_class:new(in_progress_result)
         class.assert_is_an(ICharaMakeSection, sm)
         return sm
      end

      local submenu
      success, submenu = xpcall(make_layer, debug.traceback)

      if not success then
         local err = submenu
         error(err)
      end

      if self.section then
         table.insert(self.section_trail, self.section)
      end
      self.section = submenu
   until class.is_an(ICharaMakeMenu, self.section)
      or not self:has_next_section()

   if class.is_an(ICharaMakeMenu, self.section) then
      self:set_caption(self.section.caption)
      self:relayout()

      if self.section.intro_sound then
         Gui.play_sound(self.section.intro_sound)
      end

      self.input:forward_to(self.section)
   else
      self.input:forward_to(nil)
   end
   self.input:halt_input()
end

function CharaMakeWrapper:go_back()
   if #self.section_trail == 0 then return end

   repeat
      self.section = table.remove(self.section_trail)
      self.section:on_charamake_query_menu()

      table.remove(self.results)
   until class.is_an(ICharaMakeMenu, self.section)
      or #self.section_trail == 0

   if class.is_an(ICharaMakeMenu, self.section) then
      self.caption:set_data(self.section.caption)
      self:relayout()

      self.input:forward_to(self.section)
   else
      self.input:forward_to(nil)
   end
   self.input:halt_input()
end

function CharaMakeWrapper:go_to_start()
   while #self.section_trail > 0 do
      self:go_back()
   end

   -- call the constructor of the first menu again.
   self.section = nil
   self:proceed()
end

function CharaMakeWrapper:relayout(x, y, width, height)
   self.x = x or 0
   self.y = y or 0
   self.width = width or Draw.get_width()
   self.height = height or Draw.get_height()
   self.t = UiTheme.load()
   self.caption:relayout(self.x + 20, self.y + 30)

   if self.section then
      self.section:relayout(self.x, self.y, self.width, self.height)
   end
end

function CharaMakeWrapper:draw()
   self.t.base.void:draw(self.x, self.y, self.width, self.height, {255, 255, 255})

   self.caption:draw()

   Draw.set_font(13, "bold") -- 13 - en * 2
   Draw.text("Press F1 to show help.", self.x + 20, self.height - 20, {0, 0, 0})

   if self.gene_used then
      Draw.text("Gene from " .. self.gene_used, self.x + 20, self.height - 36)
   end

   if self.section then
      self.section:draw()
   end
end

function CharaMakeWrapper:handle_action(act)
   if act == "go_to_start" then
      self:go_to_start()
   end
end

function CharaMakeWrapper:initialize_player(chara)
   assert(chara.name, "Character must have name set")
   assert(chara.race, "Character must have race set")
   assert(chara.class, "Character must have class set")

   chara:emit("base.on_initialize_player")
   config.base._save_id = chara.name
end

function CharaMakeWrapper:update(dt)
   if not self.section then
      return nil, "canceled"
   end

   local result, canceled = self.section:update(dt)

   if canceled then
      if type(result) == "table" and result.chara_make_action then
         self:handle_action(result.chara_make_action)
      else
         if #self.section_trail == 0 then
            self.canceled = true
         else
            self:go_back()
         end
      end
   elseif result then
      local in_progress_result = self:get_in_progress_result()

      -- Be careful not to call table.deepcopy on `in_progress_result.chara`, as
      -- that can cause all sorts of weirdness. We have to use
      -- `MapObject.clone()` instead, since it has awareness of things like
      -- location reparenting and not trying to clone class definition tables.
      local new_cm_result = MapObject.deepcopy(in_progress_result, nil, nil, nil, { preserve_uid = true })
      new_cm_result = self.section:get_charamake_result(new_cm_result, result) or in_progress_result

      assert(type(new_cm_result) == "table", "Charamake menu result must be table")
      new_cm_result.menu_id = Env.get_require_path(self.section.__class)

      -- previous sections + current section + 1
      local has_next = self:has_next_section()

      if has_next then
         self.results[#self.section_trail+1] = new_cm_result
         self:proceed()
      else
         assert(MapObject.is_map_object(new_cm_result.chara, "base.chara"))

         local success, err = xpcall(
            function()
               for _, menu in ipairs(self.section_trail) do
                  menu:on_charamake_finish(new_cm_result)
               end
               self.section:on_charamake_finish(new_cm_result)
            end,
            debug.traceback)

         if not success then
            Log.error("Error running final character making step:\n\t%s", err)
            self.section:on_query() -- reset canceled
         else
            self:initialize_player(new_cm_result.chara)
            return new_cm_result
         end
      end
   end

   if self.canceled then
      return nil, "canceled"
   end
end

return CharaMakeWrapper
