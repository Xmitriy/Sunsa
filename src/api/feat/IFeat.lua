local IEventEmitter = require("api.IEventEmitter")
local IMapObject = require("api.IMapObject")
local IModdable = require("api.IModdable")
local IObject = require("api.IObject")

-- A feat is anything that is a part of the map with a position. Feats
-- also include traps.
local IFeat = class.interface("IFeat", {}, { IMapObject, IModdable, IEventEmitter })

function IFeat:pre_build()
   IModdable.init(self)
   IMapObject.init(self)
   IEventEmitter.init(self)
end

function IFeat:normal_build(params)
   IObject.normal_build(self, params)
end

function IFeat:build()
end

function IFeat:instantiate(no_bind_events)
   self.params = self.params or {}
   IMapObject.instantiate(self, no_bind_events)
   self:emit("base.on_feat_instantiated")
end

function IFeat:refresh()
   IMapObject.on_refresh(self)
   self:emit("elona_sys.on_feat_refresh") -- TODO move or rename
end

function IFeat:produce_memory(memory)
   memory.uid = self.uid
   memory.show = not self:calc("is_invisible")
   memory.image = (self:calc("image") or "")
   memory.color = self:calc("color")
   memory.shadow_type = self:calc("shadow_type")
   memory.drawables = self.drawables
   memory.drawables_after = self.drawables_after
end

return IFeat
