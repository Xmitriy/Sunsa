local Mef = require("api.Mef")
local Chara = require("api.Chara")
local Event = require("api.Event")
local I18N = require("api.I18N")
local Gui = require("api.Gui")
local Input = require("api.Input")
local Map = require("api.Map")
local World = require("api.World")
local Log = require("api.Log")
local Env = require("api.Env")
local IChara = require("api.chara.IChara")
local draw = require("internal.draw")
local field = require("game.field")
local config = require("internal.config")
local data = require("internal.data")
local save = require("internal.global.save")
local chara_make = require("game.chara_make")
local Save = require("api.Save")
local state = require("internal.global.field_logic_state")
local fs = require("util.fs")
local SaveFs = require("api.SaveFs")
local Rand = require("api.Rand")
local main_state = require("internal.global.main_state")

local DeathMenu = require("api.gui.menu.DeathMenu")

local field_logic = {}

local dt = 0

function field_logic.setup_new_game(player, save_id)
   main_state.is_in_game = true

   field.map = nil

   local scenario = data["base.scenario"]:ensure(save.base.scenario)

   assert(class.is_an(IChara, player))

   Chara.set_player(player)
   if save_id == nil then
      save_id = ("%s_%d"):format(player.name, os.time())
   end
   save_id = fs.sanitize(save_id, "_")
   if string.len(save_id) == 0 then
      error("Save ID must be greater than 0 characters in length.")
   end

   local path = SaveFs.save_path("", "save", save_id)
   if fs.exists(path) then
      error(("Save '%s' already exists."):format(save_id))
   end

   config.base._save_id = fs.sanitize(save_id)
   scenario:on_game_start(player)
   assert(Map.current(), "Scenario must set the current map")
   assert(player:current_map() == Map.current(), "Player must exist in current map")

   save.base.home_map_uid = save.base.home_map_uid or Map.current().uid
   assert(save.base.home_map_uid)
   Env.update_play_time()

   Event.trigger("base.on_new_game")

   -- >>>>>>>> shade2/economy.hsp:20 	snd seSave:gosub *game_save ..
   Save.save_game()
   -- <<<<<<<< shade2/economy.hsp:20 	snd seSave:gosub *game_save ..
end

function field_logic.quickstart()
   field:init_global_data()

   save.base.scenario = config.base.quickstart_scenario
   assert(config.base.quickstart_scenario)
   assert(save.base.scenario)

   -- We will want to act as if the character making GUI is active, because that
   -- will force the player's equipment to be generated uncursed, along with
   -- some other special behaviors (search for CharaMake.is_active()).
   chara_make.set_is_active_override(true)
   local ok, err = xpcall(function()
         local me = Chara.create(config.base.quickstart_chara_id, nil, nil, {no_build=true, ownerless=true})
         me.gender = Rand.choice { "female", "male" }

         -- HACK: We have to apply race/class ourselves as the charamake process
         -- will assume the GUI will do so
         local Skill = require("mod.elona_sys.api.Skill")
         Skill.apply_race_params(me, me.race)
         Skill.apply_class_params(me, me.class)

         me:emit("base.on_finalize_player")
         me:emit("base.on_initialize_player")

         me:build()

         return me
   end, debug.traceback)
   chara_make.set_is_active_override(false)

   if not ok then
      error(err)
   end

   local save_id = "quickstart"
   local path = SaveFs.save_path("", "save", save_id)
   if fs.exists(path) then
      fs.remove(path)
   end

   local me = err
   field_logic.setup_new_game(me, save_id)

   Gui.mes("Quickstarted game.")
end

function field_logic.setup()
   -- This function gets called again if field_logic.query() throws an
   -- error, so don't rerun base.on_game_initialize.
   if not field.repl then
      field:setup_repl()
   end
   if not main_state.is_in_game then
      Event.trigger("base.on_game_initialize")
   end
end

function field_logic.update_chara_time_this_turn(time_this_turn)
   for _, chara in Chara.iter() do
      -- Ensure all characters (including the player) have a
      -- turn cost at least as much as the player's starting
      -- turn cost, since the player always goes first at the
      -- beginning of a turn.
      chara.time_this_turn = chara.time_this_turn + chara:emit("base.on_calc_speed") * time_this_turn
   end
end

local function update_mefs(map)
   for _, mef in Mef.iter(map) do
      mef:step_turn()
   end
end

function field_logic.turn_begin()
   local turn_result = Event.trigger("base.on_turn_begin", {}, nil)
   if turn_result then
      -- return turn_result
   end

   update_mefs(field.map)

   local player = Chara.player()

   if not Chara.is_alive(player) then
      -- NOTE: should be an internal event, separate from ones that
      -- event callbacks may return.
      return "player_died", player
   end

   if player:has_activity() and config.base.auto_turn_speed ~= "highest" then
      local anim_wait = player.activity:get_animation_wait()
      if anim_wait > 0 then
         dt = coroutine.yield()
         field:update(dt)
      end
   end

   -- In Elona, the player always goes first at the start of each
   -- turn, followed by allies, adventurers, then others. This was
   -- previously accomplished by simply iterating the cdata[] array by
   -- increasing index, since the player was always index 0, allies
   -- index 1-15, adventurers 15-56, and so on.
   state.player_finished_turn = false

   state.chara_iter, state.chara_iter_state, state.chara_iter_index = Chara.iter_all()

   local speed = player:emit("base.on_calc_speed")

   -- All characters will start with at least this much time during
   -- this turn.
   local starting_turn_time = (field:turn_cost() - player.time_this_turn) / speed + 1

   -- TODO: world map continuous action

   local update_time_this_turn = true
   if update_time_this_turn then
      field_logic.update_chara_time_this_turn(starting_turn_time)
   end

   -- BUG: don't pass time if just loaded from save
   World.pass_time_in_seconds(starting_turn_time / 5 + 1)

   Event.trigger("base.on_hud_message", {action="new_turn"})

   return "pass_turns"
end

function field_logic.determine_turn()
   local player = Chara.player()
   assert(player ~= nil)

   if state.chara_iter == nil then
      Log.warn("chara iter was nil, probably hotloaded.")
      return nil
   end

   -- TODO: check if player can go first, then allies, then others.
   if not state.player_finished_turn then
      state.player_finished_turn = true
      return player
   end

   -- HACK: use a better way that also orders allies first
   local found = nil
   local chara
   local going = true
   local any_moved = true

   while going do
      repeat
         state.chara_iter_index, chara = state.chara_iter(state.chara_iter_state, state.chara_iter_index)

         if chara ~= nil and chara.time_this_turn >= field:turn_cost() then
            found = chara
            any_moved = true
         end
      until found ~= nil or state.chara_iter_index == nil

      if found or any_moved == false then
         going = false
      end

      if state.chara_iter_index == nil then
         any_moved = false
         state.chara_iter, state.chara_iter_state, state.chara_iter_index = Chara.iter_all()
      end
   end

   return found
end

function field_logic.pass_turns()
   local chara = field_logic.determine_turn()

   if chara == nil then
      -- Start a new turn.
      return "turn_begin"
   end

   if config.base.anime_wait_type == "at_turn_start" then
      Gui.wait_for_draw_callbacks()
   end

   local is_first_turn = save.base.is_first_turn
   if is_first_turn then
      save.base.is_first_turn = false
   end

   chara.time_this_turn = chara.time_this_turn - field:turn_cost()

   chara.turns_alive = chara.turns_alive + 1

   local result = chara:emit("base.before_chara_turn_start", {is_first_turn=is_first_turn}, {blocked=false})
   if result.blocked then
      if result.wait then
         Gui.wait(result.wait, true)
      end
      return result.turn_result or "turn_end", chara
   end

   -- EVENT: before_chara_begin_turn
   -- wet if outdoors and rain

   -- BUILTIN: gain level

   -- if Chara.is_player(chara) then
   -- actually means beginning of all turns.

   -- refresh speed?
   -- prevent escape
   -- RETURN: potentially exit map here
   -- proc map events
   -- ether disease
   -- end

   if chara:is_player() and not Chara.is_alive(chara) then
      return "player_died", chara
   end

   -- proc mef
   -- proc buff

   local result = chara:emit("base.on_chara_pass_turn", {}, {blocked=false})
   if result.blocked then
      return result.turn_result or "turn_end", chara
   end

   -- >>>>>>>> shade2/main.hsp:821 		if cc=pc:if (cRowAct(cc)!rowActEat)&(cRowAct(cc) ...
   if chara:is_player() and chara:has_activity() then
      chara:_proc_activity_interrupted()
   end
   -- <<<<<<<< shade2/main.hsp:821 		if cc=pc:if (cRowAct(cc)!rowActEat)&(cRowAct(cc) ..

   -- proc refresh if transferred

   if chara:has_activity() then
      local turn_result = chara:pass_activity_turn()
      if config.base.auto_turn_speed ~= "highest"
         and chara.activity
         and chara.activity:get_animation_wait() > 0
      then
         Gui.update_screen()
      end
      if turn_result then
         return turn_result, chara
      end
      Log.warn("Activity '%s' on chara %d (%s) did not return turn result", chara:get_activity()._id, chara.uid, chara._id)
      return "pass_turns"
   end

   if Chara.is_alive(chara) then
      if chara:is_player() then
         return "player_turn", chara
      else
         return "npc_turn", chara
      end
   end

   return "pass_turns"
end

function field_logic.player_turn()
   local player = Chara.player()

   player.target_location = nil

   return "player_turn_query"
end

-- base.on_player_query_frame needs to be efficient as possible since it will
-- get called on every frame, so don't allocate an event params table inside the
-- loop.
local EVENT_ARGS = {}

function field_logic.player_turn_query()
   local result
   local going = true

   local player = Chara.player()
   if not Chara.is_alive(player) then
      return "player_died", player
   end

   if state.about_to_autosave then
      state.about_to_autosave = false
      Save.save_game()
   end

   Gui.update_screen(dt, true)

   -- Wait for draw callbacks if necessary.
   dt = coroutine.yield()
   while field:update_draw_callbacks(dt) do
      dt = coroutine.yield()
   end

   if config.base.anime_wait_type == "at_turn_start" then
      Gui.wait_for_draw_callbacks()
   end

   result = Event.trigger("base.on_player_turn")
   if result then
      field:update(dt)
      return result, player
   end

   while going do
      if field.map_changed then
         -- Game was loaded while we were querying for input; clear the list of
         -- characters to act and start again from "turn_begin".
         result = "player_turn_query"
         going = false
         break
      end

      local ran, turn_result = field:run_actions(dt, player)
      field:update(dt)

      if field.repl then
         local success, turn_result = field.repl:execute_all_deferred()
         if success and turn_result then
            result = turn_result
            going = false
            break
         end
      end

      if ran == true then
         result = turn_result or "player_turn_query"
         going = false
         break
      end

      field.no_scroll_this_update = false
    
      table.clear(EVENT_ARGS)
      Event.trigger("base.on_player_turn_query_frame", EVENT_ARGS)

      dt = coroutine.yield()
   end

   -- TODO: convert public to internal event

   return result, player
end

function field_logic.npc_turn(npc)
   assert(not npc:is_player())
   local Ai = require("api.Ai")
   Ai.run(npc.ai, npc)

   return "turn_end", npc
end

function field_logic.turn_end(chara)
   if not Chara.is_alive(chara) then
      return "pass_turns"
   end

   local result = chara:emit("base.on_chara_turn_end", {}, {regeneration=true})
   local regen = result.regeneration

   if Chara.is_player(chara) then
      -- hunger
      -- sleep
   else
      -- quest delivery flag
   end

   -- party time emoicon

   if regen then
      chara:emit("base.on_regenerate")
   end

   -- proc timestop

   return "pass_turns"
end

local function do_revive_player()
   local player = Chara.player()
   assert(player:revive())

   local success, map = Map.load(save.base.home_map_uid)
   if success then
      Map.travel_to(map)
   else
      Log.error("Game has not been saved yet, reviving in current map instead. Scenarios should always save the game when first starting. (%s)", map)
   end

   player:emit("base.on_player_death_revival")
end

local function revive_player()
   state.player_about_to_respawn = true
   local ok, err = xpcall(do_revive_player, debug.traceback)
   state.player_about_to_respawn = false

   if not ok then
      error(err)
   end
end

function field_logic.player_died(player)
   Gui.play_sound("base.dead1")
   Gui.update_screen()

   local result = Event.trigger("base.on_player_death", {player = player})
   if result then
      return result
   end

   Gui.mes("misc.death.good_bye")
   Gui.mes("misc.death.you_leave_dying_message")

   local last_words = Input.query_text(16, true)
   if last_words == nil or last_words == "" then
      last_words = I18N.get("misc.death.dying_message", "system.last_words")
   else
      last_words = I18N.get("misc.death.dying_message", last_words)
   end

   local bones = save.base.bones

   --[[
   {
      title = "Elegant crimson",
      name = "Xero",
      last_words = "\"Gee, that smarts!\"",
      date = DateTime:new(),
      death_cause = "died from loss of blood",
      map_name = "Lesimas",
      score = 9999,
      image = "elona.human_male",
      color = {255, 255, 255}
   }
   --]]

   local map = Map.current()

   local bone = {
      title = player.title,
      name = player.name,
      last_words = last_words,
      date = table.deepcopy(save.base.date),
      death_cause = "TODO",
      map_name = map.name,
      score = World.calc_score(),
      image = player.image,
      color = player.color or {255, 255, 255}
   }

   local MAX_BONES = 80
   if #bones >= MAX_BONES then
      -- Remove lowest scoring record.
      bones[#bones] = bone
   else
      bones[#bones+1] = bone
   end

   table.sort(bones, function(a, b) return a.score > b.score end)
   save.base.bones = bones

   local result, canceled = DeathMenu:new(bones, bone):query()
   if canceled or result.index == 1 then
      revive_player()
      return "turn_begin"
   end

   return "title_screen"
end

function field_logic.run_one_event(event, target_chara)
   local cb = nil

   Log.trace("Turn event: %s (%s)", event, target_chara)

   if Chara.player() == nil then
      -- Something went wrong; at least boot the game back to the
      -- title so it doesn't have to be restarted.
      Log.error("Player is nil, returning to title.")
      return false
   end

   if field.map_changed == true then
      event = "turn_begin"
      field.map_changed = false
   end

   if event == "turn_begin" then
      cb = field_logic.turn_begin
   elseif event == "turn_end" then
      cb = field_logic.turn_end
   elseif event == "player_died" then
      cb = field_logic.player_died
   elseif event == "player_turn" then
      cb = field_logic.player_turn
   elseif event == "player_turn_query" then
      cb = field_logic.player_turn_query
   elseif event == "npc_turn" then
      cb = field_logic.npc_turn
   elseif event == "pass_turns" then
      cb = field_logic.pass_turns
   elseif event == "title_screen" then
      return false, event
   elseif event == "quit" then
      return false, event
   end

   if type(cb) ~= "function" then
      error("Unknown turn event " .. inspect(event))
   end

   local success
   success, event, target_chara = xpcall(function() return cb(target_chara) end, debug.traceback)

   if not success then
      -- pass the error up to the main loop so the error screen can be
      -- displayed
      coroutine.yield(event)

      event = "player_turn_query"
      target_chara = nil
   end

   return true, event, target_chara
end

function field_logic.query()
   Log.info("Entered main loop.")

   field_logic.setup()

   local event = "turn_begin"
   local going = true
   local target_chara

   main_state.is_in_game = true

   draw.push_layer(field.hud)
   draw.push_layer(field)

   field:reset_scrolling()
   Gui.update_screen()

   while going do
      going, event, target_chara = field_logic.run_one_event(event, target_chara)
   end

   draw.pop_layer()
   draw.pop_layer()

   field.map = nil
   main_state.is_in_game = false

   return event
end

return field_logic
