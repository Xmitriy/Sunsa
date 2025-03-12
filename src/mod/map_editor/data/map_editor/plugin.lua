local MapEditor122Plugin = require("mod.map_editor.api.plugin.MapEditor122Plugin")
local MapEditorLayoutPlugin = require("mod.map_editor.api.plugin.MapEditorLayoutPlugin")
local MapEditorNefiaPlugin = require("mod.map_editor.api.plugin.MapEditorNefiaPlugin")
local MapEditorWfcPlugin = require("mod.map_editor.api.plugin.MapEditorWfcPlugin")
local IMapEditorPlugin = require("mod.map_editor.api.IMapEditorPlugin")

data:add_type {
   name = "plugin",
   fields = {
      {
         name = "impl",
         type = types.class_type_implementing(IMapEditorPlugin)
      }
   }
}

data:add {
   _type = "map_editor.plugin",
   _id = "elona_122",

   impl = MapEditor122Plugin
}

data:add {
   _type = "map_editor.plugin",
   _id = "layout",

   impl = MapEditorLayoutPlugin
}

data:add {
   _type = "map_editor.plugin",
   _id = "nefia",

   impl = MapEditorNefiaPlugin
}

data:add {
   _type = "map_editor.plugin",
   _id = "wfc",

   impl = MapEditorWfcPlugin
}
