require("boot")

local Draw = require("api.Draw")

local env = require("internal.env")
local game = require("game")
local debug_server = require("internal.debug_server")
local input = require("internal.input")
local draw = require("internal.draw")
local main_state = require("internal.global.main_state")
local canvas_layer = require("internal.layer.global.canvas_layer")

local loop_coro = nil
local draw_coro = nil
local server = nil

local enable_low_power_mode = true
local low_power_mode = false

function love.load(arg)
   draw.init()
   Draw.set_font(12)

   server = debug_server:new()
   server:start()

   if arg[#arg] == "-debug" then
      _DEBUG = true
   end

   loop_coro = coroutine.create(game.loop)
   draw_coro = coroutine.create(game.draw)

   draw.register_global_layer("canvas", canvas_layer:new())
end

local halt = false
local pop_draw_layer = false
local halt_error = ""

local function stop_halt()
   love.keypressed = input.keypressed

   halt = false
   low_power_mode = false
end

local function start_halt()
   input.halt_input()
   local KEYS = table.set {"return", "escape", "space"}
   love.keypressed = function(key, scancode, isrepeat)
      if KEYS[key] then
         stop_halt()
      elseif key == "backspace" then
         pop_draw_layer = true
         stop_halt()
      end
   end

   halt = true
   low_power_mode = false
end

function love.update(dt)
   input.poll_joystick_axes()

   main_state.frame_start = true

   if env.server_needs_restart then
      if server then
         server:stop()
      end
      server = debug_server:new()
      server:start()
      env.server_needs_restart = false
   end

   if server then
      local ok, cmd_name = server:step(dt)
      if not ok then
         -- Coroutine is dead. Restart server.
         -- server = debug_server:new()
         -- server:start()
      else
         if cmd_name == "run" or cmd_name == "hotload" then
            if halt then
               stop_halt()
            end
            if low_power_mode then
               low_power_mode = false
            end
         end
      end
   end

   if draw.needs_wait() then
      return
   end

   if halt then
      return
   end

   if low_power_mode then
      return
   end

   local ok, err = xpcall(draw.update_global_layers, debug.traceback, dt)
   if not ok then
      halt_error = tostring(err)
      print("Error in global layers (update):\n\t" .. debug.traceback(loop_coro, halt_error))
      start_halt()
   end

   ok, err = xpcall(draw.update_global_draw_callbacks, debug.traceback, dt)
   if not ok then
      halt_error = err
      print("Error in global draw callbacks (update):\n\t" .. debug.traceback(loop_coro, halt_error))
      start_halt()
   end

   ok, err = xpcall(draw.update_global_widgets, debug.traceback, dt)
   if not ok then
      halt_error = err
      print("Error in global widgets (update):\n\t" .. debug.traceback(loop_coro, halt_error))
      start_halt()
   end

   ok, err = coroutine.resume(loop_coro, dt, pop_draw_layer)
   pop_draw_layer = false
   if not ok or err ~= nil then
      -- we can throw anything, including non-string objects, so convert the
      -- error to a string for when something tries to concat it
      err = tostring(err)

      print("Error in loop:\n\t" .. debug.traceback(loop_coro, err))
      print()
      if not ok then
         -- Coroutine is dead. No choice but to throw.
         error(err)
      else
         -- We can continue executing since game.loop is still alive.
         start_halt()
         halt_error = err
      end
   end

   if coroutine.status(loop_coro) == "dead" then
      print("Finished.")
      love.event.quit()
   end
end

function love.draw()
   if halt then
      draw.draw_error(halt_error)
      return
   end

   if low_power_mode then
      draw.draw_low_power()
      return
   end

   love.graphics.getStats(main_state.draw_stats)

   do
      draw.draw_inner_start()

      local going = true
      local ok, err = coroutine.resume(draw_coro, going)
      if not ok or err then
         -- we can throw anything, including non-string objects, so convert the
         -- error to a string for when something tries to concat it
         err = tostring(err)

         print("Error in draw:\n\t" .. debug.traceback(draw_coro, err))
         print()
         if not ok then
            -- Coroutine is dead. No choice but to throw.
            error(err)
         else
            -- We can continue executing since game.loop is still alive.
            start_halt()
            halt_error = err
         end
      end

      draw.draw_inner_end()
   end

   do
      draw.draw_outer_start()

      local ok, err = xpcall(draw.draw_global_layers, debug.traceback)
      if not ok then
         halt_error = tostring(err)
         print("Error in global layers (draw):\n\t" .. debug.traceback(loop_coro, halt_error))
         start_halt()
      end

      ok, err = xpcall(draw.draw_global_draw_callbacks, debug.traceback)
      if not ok then
         halt_error = tostring(err)
         print("Error in global draw callbacks (draw):\n\t" .. debug.traceback(loop_coro, halt_error))
         start_halt()
      end

      ok, err = xpcall(draw.draw_global_widgets, debug.traceback)
      if not ok then
         halt_error = tostring(err)
         print("Error in global widgets (draw):\n\t" .. debug.traceback(loop_coro, halt_error))
         start_halt()
      end

      draw.draw_outer_end()
   end

   env.set_hotloaded_this_frame(false)
end

function love.focus(focused)
   if main_state.is_main_title_reached and enable_low_power_mode then
      if focused then
         low_power_mode = false
      else
         low_power_mode = true
      end
   end
end

--
--
-- LÖVE callbacks
--
--

local function wrap_error(f)
   return function(...)
      local ok, err = xpcall(f, debug.traceback, ...)
      if not ok then
         halt_error = tostring(err)
         start_halt()
      end
   end
end

love.resize = wrap_error(draw.resize)

love.mousemoved = wrap_error(input.mousemoved)
love.mousepressed = wrap_error(input.mousepressed)
love.mousereleased = wrap_error(input.mousereleased)

love.keypressed = wrap_error(input.keypressed)
love.keyreleased = wrap_error(input.keyreleased)

love.joystickpressed = wrap_error(input.joystickpressed)
love.joystickreleased = wrap_error(input.joystickreleased)

love.textinput = wrap_error(input.textinput)
