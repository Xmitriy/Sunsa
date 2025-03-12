local IEventEmitter = require("api.IEventEmitter")
local IUiElement = require("api.gui.IUiElement")

local IUiWidget = class.interface("IUiWidget",
                                {
                                   default_widget_position = "function",
                                   default_widget_refresh = "function",
                                   default_widget_z_order = "function",
                                   set_transparency = "function",
                                   bind_events = "function"
                                },
                                {IUiElement, IEventEmitter})

function IUiWidget:default_widget_position(x, y, width, height)
   return x, y, width, height
end

function IUiWidget:default_widget_refresh(player)
end

function IUiWidget:default_widget_z_order()
   return 100000
end

function IUiWidget:set_transparency(amount)
end

function IUiWidget:bind_events()
end

return IUiWidget
