--- @module Event

local data = require("internal.data")

local Event = {}

local global_events = require("internal.global.global_events")

Event.Result = {
   Blocked = "blocked"
}

function Event.global()
   return global_events
end

--- Registers a new event handler.
---
--- This should only be called on mod startup.
---
--- @tparam id:base.event event_id Event ID to register for.
--- @tparam string name A uniquely idenfiying name for the event;
---   intended for debugging use. Can be as long as needed. Please be
---   descriptive in the event's behavior to aid discovery.
--- @tparam function cb Event callback.
--- @tparam[opt] table opts
function Event.register(event_id, name, cb, opts)
   global_events:register(event_id, name, cb, opts)
end

--- Replaces an event handler with a new callback.
---
--- This should only be called on mod startup.
---
--- @tparam id:base.event event_id Event ID to register for.
--- @tparam string name The name of a registered event handler for the event ID.
--- @tparam function cb Event callback.
--- @tparam[opt] table opts
function Event.replace(event_id, name, cb, opts)
   global_events:replace(event_id, name, cb, opts)
end

--- Unregisters an event handler.
---
--- This should only be called on mod startup.
---
--- @tparam id:base.event event_id Event ID to register for.
--- @tparam string name The name of a registered event handler for the event ID.
function Event.unregister(event_id, name)
   global_events:unregister(event_id, name)
end

--- Triggers an event globally.
---
--- @tparam id:base.event event_id
--- @tparam[opt] table args Arguments for the event.
--- @tparam[opt] any default Default return value for the event.
--- @treturn[opt] any The event's returned result
function Event.trigger(event_id, args, default)
   return global_events:trigger(event_id, nil, args, default)
end

--- Returns a string with the list of registered events for an event
--- ID. Intended to be used from the REPL.
---
--- @tparam id:base.event event_id
--- @treturn string
function Event.list(event_id)
   return global_events:print(event_id)
end

--- Creates a new entry of type base.event in the current mod.
---
--- @tparam string id Event ID.
--- @tparam table types
--- @tparam string desc
function Event.create(id, types, desc)
   local dat = data:add {
      _type = "base.event",
      _id = id
   }

   assert(dat)
   local full_id = dat._id

   return function(params)
      return Event.trigger(full_id, params)
   end
end

--- Creates a new entry to type base.event with a default callback.
---
--- TODO remove this or make it play better with IEventEmitter objects
---
--- @tparam string id Event ID.
--- @tparam string desc
--- @tparam[opt] any default
--- @tparam[opt] string field
--- @tparam[opt] function cb
function Event.define_hook(id, desc, default, field, cb)
   local access_field = type(field) == "string"

   if cb == nil then
      cb = function(_, _, result) return result end
   end

   local dat = data:add {
      _type = "base.event",
      _id = "hook_" .. id
   }

   local full_id = (dat and dat._id) or nil

   local env = require("internal.env")
   if not env.is_hotloading() then
      assert(dat)
      full_id = dat._id
   end

   local result_extractor
   if type(field) == "function" then
      result_extractor = field
   else
      result_extractor = function(result, default)
         if field == nil then
            return result
         elseif type(result) == "table" and access_field then
            return result[field] or default
         end

         return default
      end
   end

   local func = function(params, _default)
      _default = _default or default
      if type(_default) == "table" then
         _default = table.deepcopy(_default)
      end

      local success, result = xpcall(function() return Event.trigger(full_id, params, _default) end, debug.traceback)
      if not success then
         local Gui = require("api.Gui")
         Gui.report_error(result, "Error running hook")
         result = _default
      end

      return result_extractor(result, _default)
   end

   local name = string.format("Default hook handler (%s)", full_id)
   Event.register(full_id, name, cb, {priority=100000})

   return func
end

return Event
