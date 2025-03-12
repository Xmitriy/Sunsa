local Event = require("api.Event")
local Midi = require("mod.midi.api.Midi")
local Rand = require("api.Rand")

data:add_multi(
   "base.config_option",
   {
      { _id = "enable_randomness", type = "boolean", default = false },
   }
)

local function trigger_note_on_chara_moved(chara, params)
   if not config.midi.enable_randomness then
      return false
   end

   if chara:is_player() then
      local note = (chara.x + chara.y * 10) % 128
      Midi.note_on(1, note, 90, 9)
      Midi.note_off(1, note, 90, 9)
   end
end
 --
Event.register("base.on_chara_moved", "Trigger MIDI note", trigger_note_on_chara_moved)

local function trigger_note_on_damage_chara(chara, params)
   if not config.midi.enable_randomness then
      return false
   end

   local note = (Rand.rnd(60) + 60) % 128
   Midi.note_on(1, note, 110, 1)
   Midi.note_off(1, note, 110, 1)
end
--
Event.register("base.after_damage_hp", "Trigger MIDI note", trigger_note_on_damage_chara)

Event.register("base.on_game_initialize", "Open MIDI", Midi.open)
