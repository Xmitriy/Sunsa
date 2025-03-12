-- We need to load all data fallbacks here so there are no issues with
-- missing data, since internal code can add its own data inline.
require("internal.data.base")
local Gui = require("api.Gui")

local Draw = require("api.Draw")
local Event = require("api.Event")
local SaveFs = require("api.SaveFs")
local RestoreSaveMenu = require("api.gui.menu.RestoreSaveMenu")
local Save = require("api.Save")
local ConfigMenuWrapper = require("api.gui.menu.config.ConfigMenuWrapper")

local chara_make = require("game.chara_make")
local config = require("internal.config")
local mod = require("internal.mod")
local startup = require("game.startup")
local field_logic = require("game.field_logic")
local save_store = require("internal.save_store")
local draw = require("internal.draw")
local main_state = require("internal.global.main_state")
local field = require("game.field")

-- TODO: this module isn't hotloadable since game.loop gets run in a
-- coroutine. Would be better to just put game.loop() into a
-- standalone function.
local game = {}

local function reset_global_state()
   field.map = nil
   field.player = nil

   -- Clear the global save.
   SaveFs.clear()
   save_store.clear()

   -- Prepare default global save data in case something in the config menus/etc
   -- needs it.
   field:init_global_data()

   Gui.stop_background_sound()
   Gui.stop_all_draw_callbacks()
end

local function main_title()
   -- enable on low power mode
   main_state.is_main_title_reached = true

   local title = require("api.gui.menu.MainTitleMenu"):new()

   local action
   local going = true
   while going do
      reset_global_state()

      local choice = title:query()

      if choice == "quickstart" then
         field_logic.quickstart()
         Event.trigger("base.on_game_initial_load")
         going = false
         action = "start"
      elseif choice == "restore" then
         local save = RestoreSaveMenu:new():query()
         if save then
            Save.load_game(save)
            Event.trigger("base.on_game_initial_load")
            going = false
            action = "start"
         end
      elseif choice == "generate" then
         local result, canceled = chara_make.query()
         if not canceled then
            going = false

            if result then
               local player = result.chara
               field_logic.setup_new_game(player)
               Event.trigger("base.on_game_initial_load")
               action = "start"
            end
         end
      elseif choice == "options" then
         ConfigMenuWrapper:new(true):query()
      elseif choice == "exit" then
         going = false
         action = "quit"
      end
   end

   return action
end

local function run_field()
   return field_logic.query()
end

-- This loop should never throw an error, to support resuming using
-- the debug server.
function game.loop()
   -- Run one frame of drawing first, to clear the screen.
   coroutine.yield()

   local mods = mod.scan_mod_dir()

   -- This function will yield to support the progress bar.
   startup.run(mods)

   Event.trigger("base.on_startup")

   local cb
   if config.base.quickstart_on_startup then
      field_logic.quickstart()
      cb = run_field
   else
      cb = main_title
   end

   local going = true
   while going do
      local success, action = xpcall(cb, debug.traceback)
      if not success then
         local err = action
         coroutine.yield(err)
      else
         if action == "start" then
            cb = run_field
         elseif action == "title_screen" then
            cb = main_title
         elseif action == "quit" then
            going = false
         else
            error("unknown top-level action " .. tostring(action))
         end
      end
   end

   startup.shutdown()
end

local function draw_progress_bar(status_text, ratio)
   Draw.clear(0, 0, 0)
   local text = "Now Loading..."
   local x = Draw.get_width() / 2
   local y = Draw.get_height() / 2
   local progress_width = 400
   local progress_height = 20

   Draw.set_font(18)
   Draw.text(text,
             x - Draw.text_width(text) / 2,
             y - Draw.text_height() / 2 - 20 - 4 - progress_height,
             {255, 255, 255})

   if status_text then
      Draw.set_font(14)
      Draw.text(status_text,
                x - Draw.text_width(status_text) / 2,
                y - Draw.text_height() / 2 - 4 - progress_height,
                {255, 255, 255})
      Draw.line_rect(x - progress_width / 2, y, progress_width, progress_height)
      Draw.filled_rect(x - progress_width / 2, y, progress_width * math.min(ratio, 1), progress_height)
   end
end

function game.draw()
   -- This gets called when game.loop() yields on the first frame.
   draw_progress_bar()

   -- Progress bar.
   local status = ""
   local last_status = ""
   local progress = 0
   local steps = 0
   while true do
      status, progress, steps = startup.get_progress()
      draw_progress_bar(status or last_status, progress / steps)
      if status == nil then break end
      last_status = status
      coroutine.yield()
   end

   local going = true

   while going do
      local ok, ret = xpcall(draw.draw_layers, debug.traceback)

      if not ok then
         going = coroutine.yield(ret)
      else
         going = coroutine.yield()
      end
   end
end

return game
