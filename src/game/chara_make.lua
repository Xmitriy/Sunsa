local Draw = require("api.Draw")
local CharaMakeWrapper = require("api.gui.menu.chara_make.CharaMakeWrapper")

local field = require("game.field")

local chara_make = {}

chara_make.sections = {
   "api.gui.menu.chara_make.SelectScenarioMenu",
   "api.gui.menu.chara_make.SelectRaceMenu",
   "api.gui.menu.chara_make.SelectGenderMenu",
   "api.gui.menu.chara_make.SelectClassMenu",
   "api.gui.menu.chara_make.RollAttributesMenu",
   "api.gui.menu.chara_make.SelectFeatsMenu",
   "api.gui.menu.chara_make.SelectAliasMenu",
   "api.gui.menu.chara_make.CustomizeAppearanceMenu",
   "api.gui.menu.chara_make.CharacterFinalizeMenu"
}

chara_make.wrapper = nil
local is_active = false

function chara_make.set_caption(text)
   return chara_make.wrapper and chara_make.wrapper:set_caption(text)
end

function chara_make.get_in_progress_result()
   return chara_make.wrapper and chara_make.wrapper:get_in_progress_result()
end

function chara_make.set_is_active_override(_is_active)
   -- for mocking out CharaMake.is_active(), for special player generation
   -- behavior like making sure all their equipment is generated uncursed, but
   -- without going through the charamake GUI (quickstart)
   is_active = _is_active
end

function chara_make.is_active()
   return is_active or chara_make.wrapper ~= nil
end

function chara_make.query()
   -- create a new save data so mods can access it
   field:init_global_data()

   chara_make.wrapper = CharaMakeWrapper:new(chara_make.sections)

   local res, canceled = chara_make.wrapper:query()

   chara_make.wrapper = nil

   return res, canceled
end

return chara_make
