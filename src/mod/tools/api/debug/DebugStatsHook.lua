local Advice = require("api.Advice")
local MemoryProfiler = require("api.MemoryProfiler")
local Log = require("api.Log")
local Stopwatch = require("api.Stopwatch")
local state = require("mod.tools.internal.global")

local DebugStatsHook = {}

local MEMORY_OVERHEAD = 0.05

local function make_advice_id(api, fn_name)
   return ("Hook %s.%s"):format(api, fn_name)
end

function DebugStatsHook.hook_fn(api, fn_name)
   local advice_id = make_advice_id(api, fn_name)

   state.debug_stats[api] = state.debug_stats[api] or {}

   if state.debug_stats[api][fn_name] then
      return false
   end

   if Advice.is_advised(api, fn_name, _MOD_ID, advice_id) then
      return false
   end

   local hook = function(orig_fn, ...)
      if state.debug_stats[api] == nil then
         return orig_fn(...)
      end
      state.debug_stats[api][fn_name] = state.debug_stats[api][fn_name] or { mem = 0, time = 0, hits = 0, mem_hits = 0 }
      local rec = state.debug_stats[api][fn_name]

      local time = Stopwatch:new()
      local mem = MemoryProfiler:new()

      local results = {orig_fn(...)}

      rec.hits = rec.hits + 1

      local last_time = time:measure()
      rec.time = rec.time + last_time
      rec.last_time = last_time

      local last_mem = math.max(0, mem:measure() - MEMORY_OVERHEAD)
      rec.mem = rec.mem + last_mem
      rec.last_mem = last_mem

      return table.unpack(results, 1, table.maxn(results))
   end

   Advice.add("around", api, fn_name, advice_id, hook)

   return true
end

function DebugStatsHook.hook(api)
   local hooked = 0

   local tbl = require(api)
   for k, v in pairs(tbl) do
      if type(v) == "function" then
         if DebugStatsHook.hook_fn(api, k) then
            hooked = hooked + 1
         end
      end
   end

   if hooked > 0 then
      Log.info("%s: hooked %d functions.", api, hooked)
   end
end

function DebugStatsHook.unhook(api)
   if not state.debug_stats[api] then
      return
   end

   local unhooked = 0

   local tbl = require(api)
   for k, v in pairs(tbl) do
      local advice_id = make_advice_id(api, k)
      if type(v) == "function" and Advice.is_advised(api, k, _MOD_ID, advice_id) then
         Advice.remove(api, k, _MOD_ID, advice_id)
         unhooked = unhooked + 1
      end
   end

   state.debug_stats[api] = nil

   if unhooked > 0 then
      Log.info("%s: unhooked %d functions.", api, unhooked)
   end
end

function DebugStatsHook.unhook_all()
   for api, _ in pairs(state.debug_stats) do
      DebugStatsHook.unhook(api)
   end
end

function DebugStatsHook.get_results()
   return state.debug_stats
end

function DebugStatsHook.clear_results()
   for _, recordings in pairs(state.debug_stats) do
      table.clear(recordings)
   end
end

return DebugStatsHook
