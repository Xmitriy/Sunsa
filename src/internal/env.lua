local Log = require("api.Log")
local fs = require("util.fs")
local paths = require("internal.paths")
local main_state = require("internal.global.main_state")

--- Module and mod environment functions. This module implements
--- seamless hotloading by replacing the global `require` with one
--- that can update the result of `require` in-place if a hotload is
--- requested. This is not without some caveats though:
---
--- 1. The result of `require` should be a table to enable hotloading.
--- 2. All local upvalues inside the chunk will be lost on hotloading.
---    To support hotloading, code should minimize the usage of
---    top-level locals or otherwise provide support for hotloading by
---    calling env.is_hotloading() in the appropriate places.
--- 3. For now it is assumed that any require path starting with `mod`
---    will be a part of a mod's code, so a mod sandbox should be
---    applied to it. Any other path will use the global environment.
---
--- The goal is to be able to completely reload a mod's code at
--- runtime without any significant side effects warranting a full
--- restart (save for user code).
---
--- If a hotloaded chunk returns "no_hotload" instead of a table, the
--- existing table will be preserved. This is so those chunks can
--- custom implement hotloading support. See `internal.data` for an
--- example.
local env = {}

--- Globals for use inside mods. All of these should be loaded by the
--- time this file is loaded.
--- @field SANDBOX_GLOBALS
local SANDBOX_GLOBALS = {
   -- Lua basic functions
   "assert",
   "error",
   "ipairs",
   "next",
   "pairs",
   "pcall",
   "print",
   "select",
   "tonumber",
   "tostring",
   "type",
   "unpack",
   "xpcall",
   "collectgarbage",
   "getmetatable",
   "setmetatable",

   -- Lua stdlib
   "table",
   "string",
   "utf8",
   "math",
   "coroutine",

   -- LuaJIT stdlib
   "bit",

   -- OOP library
   "class",

   -- Typechecking
   "types",

   -- misc. globals
   "inspect",
   "fun",
}

local UNSAFE_HOTLOAD_PATHS = {
   "internal.env",
   "util.class",
}

local HOTLOADING_PATH = false
local HOTLOAD_DEPS = false
local HOTLOADED = {}
local LOADING = {}
local LOADING_STACK = {}
local LOADING_MODS = {}

-- To determine the require path of a chunk, it is necessary to keep a
-- cache. If a chunk is hotloaded, the table it returns will be merged
-- into the one already existing in any upvalues, but the table
-- upvalue that was created inside the chunk itself will still
-- reference a completely different table (the one that was merged
-- into the existing one). Since this upvalue can be local there may
-- be no way to access it, so in the end there can be more than one
-- table at the same require path. This cache table is a mapping from
-- a table to its require path.
--
-- TODO: actually you can use a function called debug.setupvalue to
-- modify upvalues. it should be used instead.
local require_path_cache = setmetatable({}, { __mode = "k" })

local paths_loaded_by_hooked_require = {}

-- This table supports retrieving a module/class table given a function object.
local fn_to_module = setmetatable({}, { __mode = "k" })

-- Paths with in-memory Lua code strings. Used for testing.
-- Looks like {{ mod_id = "@test@", code = "require()..." }}
local transient_paths = {}

-- This flag is used for e.g. relayouting all UI layers on hotload so
-- the changes are visible immediately and on_hotload() can be called.
local hotloaded_this_frame = false
function env.set_hotloaded_this_frame(val)
   hotloaded_this_frame = val
end

function env.hotloaded_this_frame()
   return hotloaded_this_frame
end

local function path_is_in_mod(path)
   return string.match(path, "^mod%.([^.]+)")
end

-- Tries to find the mod that is calling the current function by
-- looking up the list of paths for one contained in a mod. If not
-- found, returns "base".
--
-- When hotloading, this uses the currently hotloading require path to
-- see if a mod is being hotloaded at the top level instead, since the
-- caller of this function will be the debug server or REPL.
function env.find_calling_mod(offset)
   offset = offset or 0
   local hotload_path = env.is_hotloading()
   if hotload_path then
      return path_is_in_mod(hotload_path) or "base"
   end

   if #LOADING_STACK > 0 then
      for i = #LOADING_STACK-offset, 1, -1 do
         local path = LOADING_STACK[i]
         local mod_name = path_is_in_mod(path)
         if mod_name then
            local info = debug.getinfo(i, "S")
            local loc
            if info.what == "main" then
               loc = info
            end
            return mod_name, loc
         end
      end
   else
      local info
      local i = offset + 1
      repeat
         info = debug.getinfo(i, "S")
         if info then
            local mod_name = nil
            local loc
            local funcinfo = debug.getinfo(i, "f")
            if funcinfo then
               local funcenv = getfenv(funcinfo.func)
               if funcenv then
                  local mn = rawget(funcenv, "_MOD_ID")
                  if mn then
                     mod_name = mn
                     loc = info
                  end
               end
            end
            if info.what == "main" then
               loc = info
            end
            if mod_name then
               return mod_name, loc
            end
         end
         i = i + 1
      until not info
   end

   return "base", debug.getinfo(2, "S")
end

local LOVE2D_REQUIRES = table.set {
   "socket",
   "socket.core",
   "socket.http",
   "socket.https",
   "ltn12"
}

local NATIVE_REQUIRES = table.set {
   "vips"
}

local global_require = require

local function can_load_native_libs(mod_env)
   local setting = "always"
   if setting == "base" then
      return not not mod_env
   elseif setting == "always" then
      return true
   end

   return false
end

local function get_require_path(path, mod_env)
   if transient_paths[path] then
      return path
   end

   local resolved = package.searchpath(path, package.path)

   if resolved == nil and can_load_native_libs(mod_env) then
      -- Also try cpath, but only when not using the love runtime
      -- (tests). Mods shouldn't be able to load arbitrary native
      -- libraries.
      Log.debug("Searching cpath for lib '%s'", path)

      resolved = package.searchpath(path, package.cpath)
      if resolved then
         return path, true -- return the original path
      end

      if NATIVE_REQUIRES[path] then
         return path, true
      end

      if not mod_env and path == "ffi" then
         return path, true
      end
   end

   if resolved == nil then
      -- Some modules like luasocket aren't in package.cpath but can
      -- be loaded with 'require' anyway because they're a part of
      -- LÖVE.
      if LOVE2D_REQUIRES[path] then
         -- Catch any errors that might occur if we attempt to load the native
         -- library but fail.
         local ok, err = xpcall(global_require, debug.traceback, path)
         if ok then
            return path, true
         end

         Log.debug("Failed to load native library \"%s\": %s", path, err)

         return nil, false
      end
   end

   return resolved, false
end

--- Loads a chunk from a package search path ignoring
--- `package.loaded`. If no environment is passed, the returned chunk
--- will have access to the global environment.
-- @tparam string path
-- @tparam[opt] table mod_env
local function env_dofile(path, mod_env)
   local resolved, require_now = get_require_path(path, mod_env)

   Log.trace("resolved path: %s -> %s", path, resolved)

   if require_now then
      -- Catch any errors that might occur if we attempt to load a native
      -- library but fail.
      local success, err = xpcall(global_require, debug.traceback, resolved)
      if not success then
         return nil, err
      end

      local result = err
      return result, nil
   end

   if resolved == nil then
      local tried_paths = ""
      local function split_path(path_string)
         for _, s in ipairs(string.split(path_string, ";")) do
            tried_paths = tried_paths .. "\n" .. s
         end
      end
      split_path(package.path)
      if can_load_native_libs(mod_env) then
          split_path(package.cpath)
      end
      return nil, ("Cannot find path '%s'. Tried searching the following: %s"):format(path, tried_paths)
   end

   local chunk, err

   -- `transient` is a "virtually loaded" file with no on-disk counterpart. It
   -- is associated with a Lua require path, and is used for filesystem mocking
   -- during tests.
   local transient = transient_paths[path]
   if transient then
      chunk, err = loadstring(transient.code)
   else
      -- We will assume `resolved` points to a .lua file.
      chunk, err = loadfile(resolved)
   end

   if chunk == nil then
      return nil, err
   end

   mod_env = mod_env or _G
   setfenv(chunk, mod_env)

   local success, err = xpcall(chunk, debug.traceback)
   if not success then
      return nil, err
   end

   local result = err
   return result
end

function env.load_sandboxed_chunk(path, mod_name)
   mod_name = mod_name or env.find_calling_mod()

   local transient = transient_paths[path]
   if transient then
      mod_name = transient.mod_id
   end

   -- TODO: cache this somewhere.
   local mod_env = env.generate_sandbox(mod_name, true)

   return env_dofile(path, mod_env)
end


local function get_load_type(path)
   if string.match(path, "^api%.") or string.match(path, "^thirdparty%.") then
      return "api"
   elseif string.match(path, "^test%.") then
      return "test"
   elseif path_is_in_mod(path) then
      return "mod"
   elseif LOVE2D_REQUIRES[path] then
      return "thirdparty"
   elseif NATIVE_REQUIRES[path] or package.searchpath(path, package.cpath) then
      return "native"
   end

   return nil
end

local function can_hotload(path)
   if transient_paths[path] then
      return true
   end

   if get_require_path(path) == nil then
      return false
   end

   for _, patt in ipairs(UNSAFE_HOTLOAD_PATHS) do
      if string.match(path, patt) then
         return false
      end
   end

   return true
end

local function extract_mod_name(path)
   return string.match(path, "^mod%.([^.]+)[%.]?")
end

function env.is_valid_ident(ident)
   return string.match(ident, "^[_a-z][_a-z0-9]*$")
end

function env.assert_is_valid_ident(ident)
   if not env.is_valid_ident(ident) then
      error(("'%s' is not a valid identifier (must consist of lowercase letters, numbers and underscores only, cannot start with a number)"):format(ident), 2)
   end
end

--- Loads a chunk without updating the global package.loaded table.
--- The load method chosen depends on the path prefix: "api" will load
--- with the global environment, "mod" will use a sandboxed
--- environment.
-- @tparam string path
local function safe_load_chunk(path)
   local load_type = get_load_type(path)

   if load_type == "api" or load_type == "thirdparty" or load_type == "test" then
      Log.debug("Loading chunk %s with global env.", path)
      return env_dofile(path)
   elseif load_type == "mod" then
      local mod_name = extract_mod_name(path)

      local disable_strict_load_order = true
      if not disable_strict_load_order
         and not (mod_name == main_state.currently_loading_mod or main_state.loaded_mods[mod_name])
      then
         error(("Mod name '%s' is not yet loaded. Please ensure you've specified it as a dependency of %s."):format(mod_name, main_state.currently_loading_mod))
      end

      Log.debug("Loading chunk %s with mod sandbox for %s.", path, mod_name)
      return env.load_sandboxed_chunk(path, mod_name)
   elseif load_type == "native" then
      Log.debug("Attempting to load native library '%s'", path)
      return env_dofile(path)
   end

   return nil
end

--- Requires a path with either the mod environment or the global
--- environment depending on its prefix.
local function env_dofile_or_safe_load(path)
   if path_is_in_mod(path) then
      return safe_load_chunk(path)
   end

   return env_dofile(path)
end

local function gen_require(chunk_loader, can_load_path)
   return function(path, hotload)
      local req_path = paths.convert_to_require_path(path)

      LOADING_STACK[#LOADING_STACK+1] = req_path

      if can_load_path and not can_load_path(req_path) then
         LOADING_STACK[#LOADING_STACK] = nil
         error(("cannot load path '%s'"):format(req_path))
      end

      if LOADING[req_path] then
         local loop = {}
         local found = false
         for _, p in ipairs(LOADING_STACK) do
            if p == req_path then
               found = true
            end
            if found then
               loop[#loop+1] = p
            end
         end
         LOADING = {}
         LOADING_STACK = {}
         error("Loop while loading " .. req_path .. ":\n" .. inspect(loop))
      end

      hotload = hotload or HOTLOAD_DEPS

      if hotload and not can_hotload(req_path) then
         hotload = false
      end

      -- Don't hotload again if the req_path was already hotloaded
      -- earlier.
      if hotload and HOTLOADED[req_path] then
         hotload = false
      end

      if not hotload and package.loaded[req_path] then
         LOADING_STACK[#LOADING_STACK] = nil
         return package.loaded[req_path]
      end

      LOADING[req_path] = true
      local result, err = chunk_loader(req_path)
      LOADING_STACK[#LOADING_STACK] = nil
      LOADING[req_path] = false

      if err then
         HOTLOADING_PATH = false
         error(("%s:\n\t%s"):format(path, string.strip_whitespace(err)), 0)
      end

      if HOTLOADING_PATH and result == "no_hotload" then
         HOTLOADING_PATH = false
         Log.error("Chunk %s does not support hotloading", req_path)
         return
      end

      if type(package.loaded[req_path]) == "table"
         and type(result) == "table"
      then
         Log.debug("Hotload: %s %s <- %s", req_path, string.tostring_raw(package.loaded[req_path]), string.tostring_raw(result))
         if Log.has_level("trace") then
            Log.trace("\n%s\n========\n%s",
                      inspect(package.loaded[req_path], {override_mt = true}),
                      inspect(result, {override_mt = true}))
         end
         if type(result.on_hotload) == "function" then
            Log.warn("Table has overridden 'on_hotload' function. Using it instead of default.")
            result.on_hotload(package.loaded[req_path], result)
         else
            if class.is_class(result) or class.is_interface(result) then
               class.hotload(package.loaded[req_path], result)
            else
               table.replace_with(package.loaded[req_path], result)
            end
         end
         if Log.has_level("trace") then
            Log.trace("Hotload result: %s", inspect(package.loaded[req_path], {override_mt = true}))
         end
      elseif result == nil then
         package.loaded[req_path] = true
      else
         package.loaded[req_path] = result
      end

      if hotload then
         HOTLOADED[req_path] = true
      end

      if type(result) == "table" then
         require_path_cache[result] = req_path

         for k, v in pairs(result) do
            if type(v) == "function" then
               -- Save the module and identifier of this function.
               --
               -- NOTE: This will overwrite the existing metadata for a function
               -- defined elsewhere that is later copied to another module. For
               -- example, the `Draw` module copies a set of functions from the
               -- internal `draw` module using assignment, instead of defining a
               -- new function that calls the internal one, so the function
               -- returned from the two modules will reference the same object
               -- in memory.
               fn_to_module[v] = { module = package.loaded[req_path], identifier = k }
            end
         end

         if class.is_class(result) or class.is_interface(result) then
            local ok, on_require = pcall(function() return result.__on_require end)
            if type(on_require) == "function" then
               on_require(package.loaded[req_path], result)
            end
         end
      end

      paths_loaded_by_hooked_require[req_path] = true

      return package.loaded[req_path]
   end
end

--- Version of `require` that will load sandboxed mod environments if
--- the path is prefixed with "mod", and will update the table in
--- place if hotloading, but disallow loading non-public files.
-- @function env.safe_require
env.safe_require = gen_require(safe_load_chunk, get_load_type)

--- Version of `require` for the global environment that will respect
--- hotloading and mod environments, and also allow requiring
--- non-public files.
-- @function env.require
env.require = gen_require(env_dofile_or_safe_load)

--- Reloads a path that has been required already by updating its
--- table in-place. If either the result of `require` or the existing
--- item in package.loaded are not tables, the existing item is
--- overwritten instead.
-- @tparam string path
-- @tparam bool also_deps If true, also hotload any nested
-- dependencies loaded with `require` that any hotloaded chunk tries
-- to load.
-- @treturn table
function env.hotload_path(path, also_deps)
   -- The require path can come from an editor that preserves an
   -- "init.lua" at the end. We still need to strip "init.lua" from
   -- the end if that's the case, in order to make the paths
   -- "api/Api.lua" and "api/Api/init.lua" resolve to the same thing.
   path = paths.convert_to_require_path(path)

   HOTLOADED = {}

   if not can_hotload(path) then
      error("Can't hotload the path " .. path)
   end

   if get_load_type(path) == "mod" then
      local mod_name = extract_mod_name(path)
      assert(mod_name, "No mod name for " .. path)
      if not LOADING_MODS[mod_name] then
         local mod = require("internal.mod")
         if not mod.is_loaded(mod_name) then
            Log.warn("Mod '%s' is not yet loaded, attempting to load...", mod_name)
            LOADING_MODS[mod_name] = true
            local chunk, err = mod.hotload_mod(mod_name)
            LOADING_MODS[mod_name] = nil
            if err then
               error(err)
            end
            return chunk, err
         end
      end

      -- if we tried hotloading the mod manifest, just return nothing.
      if string.match(path, "^mod%." .. mod_name .. "%.mod$") then
         Log.info("Hotloaded mod manifest for '%s'.", mod_name)
         return nil
      end

      -- Hotload files holding translations (they have a "locale"
      -- directory in the mod root)
      local lang = string.match(path, "^mod%." .. mod_name .. "%.locale%.([a-z_]+)%.")
      if lang then
         local i18n = require("internal.i18n")
         local filepath = get_require_path(path)
         filepath = filepath:gsub("^%./", "")
         local namespace = string.match(path, "^mod%." .. mod_name .. "%.locale%.[a-z_]+%.([a-z_]+)%..*$") or "base"
         Log.info("Hotloading translations at %s:%s for language '%s'.", namespace, path, lang)

         -- The locale DB might not be loaded yet, so we should create
         -- it if so.
         i18n.db[lang] = i18n.db[lang] or {}
         i18n.db[lang][namespace] = i18n.db[lang][namespace] or {}
         i18n.data[lang] = i18n.data[lang] or {}

         i18n.load_single_translation(filepath, i18n.db[lang][namespace], i18n.data[lang], namespace)

         i18n.index = nil
         i18n.key_index = nil

         return nil
      end
   end

   local loaded = package.loaded[path]
   if not loaded then
      Log.warn("Tried to hotload '%s', but path was not yet loaded. Requiring normally.", path)

      local result = env.safe_require(path, false)
      return {
         require_path = path,
         module = result
      }
   end

   if also_deps then
      -- Enable hotloading for any call to a hooked `require` until
      -- the top-level `hotload` call finishes.
      HOTLOAD_DEPS = true
   end

   Log.trace("Begin hotload: %s", path)
   HOTLOADING_PATH = path
   local result = env.require(path, true)
   HOTLOADING_PATH = false
   Log.trace("End hotload: %s %s", path, result)

   if also_deps then
      HOTLOAD_DEPS = false
   end

   hotloaded_this_frame = true

   return {
      require_path = path,
      module = result
   }
end

function env.hotload_all()
   for path, _ in pairs(package.loaded) do
      if can_hotload(path) then
         env.hotload_path(path)
      end
   end
end

--- Returns the currently hotloading path if hotloading is ongoing.
--- Used to implement specific support for hotloading in global
--- variables besides the entries in package.loaded.
-- @treturn bool
function env.is_hotloading()
   return HOTLOADING_PATH
end

--- Overwrites Lua's builtin `require` with a version compatible with
--- the hotloading system.
function env.hook_global_require()
   require = function(path)
      -- ignore second argument (`hotload`)
      return env.require(path)
   end
end

local mod_require = function(path)
   -- ignore second argument (`hotload`)
   return env.safe_require(path)
end

function env.generate_sandbox(mod_name, is_strict)
   assert(type(mod_name) == "string", "mod_name is required")

   local sandbox = {}

   for _, k in ipairs(SANDBOX_GLOBALS) do
      sandbox[k] = _G[k]
   end

   sandbox["_MOD_ID"] = mod_name

   sandbox["require"] = mod_require
   sandbox["dofile"] = function(path) return env.load_sandboxed_chunk(path, mod_name) end
   sandbox["data"] = require("internal.data")
   sandbox["config"] = require("internal.config")
   sandbox["pause"] = function(...) return _G.pause(...) end
   sandbox["_G"] = sandbox

   sandbox["save"] = require("internal.global.save")

   sandbox["debug"] = { traceback = debug.traceback }

   sandbox["loadstring"] = function(str)
      local chunk, err = loadstring(str)
      if chunk == nil then
         return nil, err
      end

      setfenv(chunk, sandbox)
      return chunk, nil
   end

   if is_strict then
      -- copy the strict metatable from the global environment
      -- (thirdparty/strict.lua)
      local strict = getmetatable(_G)
      setmetatable(sandbox, strict)
   end

   return sandbox
end

-- Given a table loaded with require, a class/interface table or a
-- class instance, returns its require path.
function env.get_require_path(tbl)
   assert(type(tbl) == "table")

   if tbl.__class then
      tbl = tbl.__class
   end

   local path = require_path_cache[tbl]

   if path == nil then
      Log.warn("Cannot find require path for %s (%s)", tostring(tbl), string.tostring_raw(tbl))
   end

   return path
end

-- Given a function defined on a module or class, returns its module/class and
-- identifier.
function env.get_module_of_member(fn)
   local entry = fn_to_module[fn]
   if entry == nil then
      return nil, nil
   end

   return entry.module, entry.identifier
end

function env.get_loaded_module_paths()
   return table.values(require_path_cache)
end

function env.is_loaded(path)
   return package.loaded[path] ~= nil
end

function env.unload_path(path)
   paths_loaded_by_hooked_require[path] = nil
   require_path_cache[path] = nil
   transient_paths[path] = nil
   package.loaded[path] = nil
end

function env.load_transient_path(path, mod_id, code)
   assert(type(mod_id) == "string")
   assert(type(code) == "string")
   transient_paths[path] = { mod_id = mod_id, code = code }
end

function env.unload_transient_paths()
   for path, _ in pairs(transient_paths) do
      env.unload_path(path)
   end
   transient_paths = {}
end

function env.restart_debug_server()
   Log.warn("Restarting debug server...")
   env.server_needs_restart = true
end

function env.reset()
   -- Unload all tables that were loaded though the hooked 'require' added by
   -- env.hook_global_require(). This should not unload the chunk for
   -- `internal.env`, which was put inside `package.loaded` by the original
   -- `require` function.
   for path, _ in pairs(paths_loaded_by_hooked_require) do
      package.loaded[path] = nil
   end

   -- Some paths with global state need to be be required again, using the
   -- global context (bypassing the hooked `require`).
   local function rerequire_globally(path)
      package.loaded[path] = nil
      package.loaded[path] = global_require(path)
   end

   -- `api.Log` is weird, since we use it in really low level places like
   -- `internal.env`, but it also has a dependency on an event
   -- (`base.on_log_message`), meaning we need to flush its chunk references so
   -- it can get a pointer to the new global data table.
   package.loaded["api.Log"] = nil

   -- `internal.global.main_state` is also weird, since it doesn't get loaded by
   -- the hooked require, so we must make sure it's in package.loaded before the
   -- hooked require gets run on it.
   rerequire_globally("internal.global.main_state")

   -- `util.class` is also weird, because it depends on binser. binser's
   -- serializers are global, so we need to reset those too.
   local binser = assert(package.loaded["thirdparty.binser"])
   binser.clearRegistry()

   paths_loaded_by_hooked_require = {}
   require_path_cache = setmetatable({}, { __mode = "k" })
   fn_to_module = setmetatable({}, { __mode = "k" })
   transient_paths = {}
   hotloaded_this_frame = false

   Log = require("api.Log")
end

return env
