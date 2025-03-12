local fs = {}

local dir_sep = package.config:sub(1,1)
local is_windows = dir_sep == "\\"

-- LOVE always expects the directory separator to be a forward slash ('/').
dir_sep = "/"

local function string_split(str,sep)
   sep = sep or "\n"
   local ret={}
   local n=1
   for w in str:gmatch("([^"..sep.."]*)") do
      ret[n] = ret[n] or w
      if w=="" then
         n = n + 1
      end
   end
   return ret
end

local function wrap(cb)
   return function(path, ...) return cb(fs.to_relative(path), ...) end
end


local function gen_recursive_delete(rm_fn)
   return function(path)
      local function recursively_delete(item)
         if fs.is_directory(item) then
            for _, child in pairs(fs.get_directory_items(item)) do
               local child_path = fs.join(item, child)
               recursively_delete(child_path)
               rm_fn(child_path)
            end
         elseif fs.get_info(item) then
            rm_fn(item)
         end
         rm_fn(item)
      end
      recursively_delete(fs.to_relative(path))
      return true
   end
end

local working_dir_prefix = nil

function fs.set_global_working_directory(prefix)
   working_dir_prefix = prefix
end

function fs.get_global_working_directory()
   return working_dir_prefix
end

if not love or love.getVersion() == "lovemock" then
   local ok, lfs = pcall(require, "lfs")
   assert(ok, "luafilesystem not installed")
   fs.get_directory_items = function(dir, recursive)
      if working_dir_prefix and not fs.is_absolute(dir) then
         dir = fs.join(working_dir_prefix, dir)
      end
      dir = fs.to_relative(dir)
      local items = {}

      local function get_paths(dir, rest)
         for path in lfs.dir(dir) do
            if path ~= "." and path ~= ".." then
               local child_path = fs.join(dir, path)
               local child_path_rel = fs.join(rest, path)
               items[#items+1] = child_path_rel
               if recursive and fs.is_directory(child_path) then
                  get_paths(child_path, child_path_rel)
               end
            end
         end
      end

      get_paths(dir, "")

      return items
   end
   fs.get_info = function(path)
      local other_path = fs.to_relative(path)
      local attrs = lfs.attributes(other_path)
      if attrs == nil then
         attrs = lfs.attributes(path)
         if attrs == nil then
            return nil
         end
      end

      return {
         type = attrs.mode,
         size = attrs.size,
         modtime = attrs.modification
      }
   end
   fs.get_save_directory = function()
      return fs.join(fs.get_temporary_directory(), ".local", "share", "love", "OpenNefia")
   end
   fs.create_directory = function(name)
      name = fs.to_relative(name)
      local path = string_split(name, dir_sep)[1] .. dir_sep
      if not fs.is_root(path) then
         path = ""
      end
      for dir in string.gmatch(name, "[^\"" .. dir_sep .. "\"]+") do
         -- avoid appending the root directory ("C:") on windows; it results in "C:\C:\the\path"
         local do_create = not is_windows or (is_windows and not string.match(dir, "^[a-zA-Z]:$"))
         path = path .. dir .. dir_sep

         if do_create then
            lfs.mkdir(path)
         end
      end
      return path
   end
   fs.read = function(name, size)
      name = fs.to_relative(name)
      assert(fs.exists(name), ("file does not exist: %s"):format(name))
      local f = io.open(name, "rb")
      local data = f:read(size or "*all")
      f:close()
      return data, nil
   end
   fs.write = function(name, data, size)
      name = fs.to_relative(name)
      local f = io.open(name, "wb")
      assert(f, ("could not open %s"):format(name))
      f:write(data)
      f:close()
      return true, nil
   end
   fs.remove = gen_recursive_delete(os.remove)
   fs.get_working_directory = function()
      if working_dir_prefix then
         return fs.join(lfs.currentdir(), working_dir_prefix)
      end
      return lfs.currentdir()
   end

   fs.attributes = lfs.attributes
else
   fs.get_directory_items = function(path, recursive)
      local items = {}
      local function get_paths(dir)
         for _, item in ipairs(love.filesystem.getDirectoryItems(dir)) do
            items[#items+1] = item
            local child_path = fs.join(dir, item)
            if recursive and fs.is_directory(child_path) then
               get_paths(child_path, items)
            end
         end
      end

      get_paths(fs.to_relative(path))

      return items
   end
   fs.get_info = wrap(love.filesystem.getInfo)
   fs.get_save_directory = love.filesystem.getSaveDirectory
   fs.create_directory = wrap(love.filesystem.createDirectory)
   fs.write = wrap(love.filesystem.write)
   fs.read = wrap(love.filesystem.read)
   fs.remove = gen_recursive_delete(love.filesystem.remove)
   fs.get_working_directory = love.filesystem.getWorkingDirectory

   fs.attributes = function(filepath, aname, atable)
      filepath = fs.to_relative(filepath)
      local info = fs.get_info(filepath)
      if info == nil then
         return nil, "file does not exist"
      end

      if info.type == "symlink" then
         info.type = "link"
      end

      info.mode = info.type
      info.type = nil

      if aname then
         info = info[aname]
      end

      return info
   end
end

function fs.to_relative(filepath, parent)
   parent = fs.normalize(parent or fs.get_working_directory())
   filepath = fs.normalize(filepath)
   filepath = string.strip_prefix(filepath, parent .. "/")
   return filepath
end

function fs.iter_directory_items(dir, recursive)
   return ipairs(fs.get_directory_items(dir, recursive))
end

local function iter_paths(state, index)
   if index > #state.dirs then
      return nil
   end

   local path
   repeat
      path = fs.join(state.base, state.dirs[index])
      index = index + 1
   until index > #state.dirs or fs.is_file(path)

   if index > #state.dirs + 1 then
      return nil
   end

   return index, path
end

function fs.iter_directory_paths(dir, recursive)
   return iter_paths, {dirs=fs.get_directory_items(dir, recursive), base=dir}, 1
end

function fs.exists(path)
   if _IS_LOVEJS then
      return love.filesystem.exists(path)
   end

   if working_dir_prefix and not fs.is_absolute(path) then
      path = fs.join(working_dir_prefix, path)
   end
   return fs.get_info(path) ~= nil
end

function fs.is_directory(path)
   if _IS_LOVEJS then
      return love.filesystem.isDirectory(path)
   end

   if working_dir_prefix and not fs.is_absolute(path) then
      path = fs.join(working_dir_prefix, path)
   end
   local info = fs.get_info(path)
   return info ~= nil and info.type == "directory"
end

function fs.is_file(path)
   if _IS_LOVEJS then
      return love.filesystem.isFile(path)
   end

   if working_dir_prefix and not fs.is_absolute(path) then
      path = fs.join(working_dir_prefix, path)
   end
   local info = fs.get_info(path)
   return info ~= nil and info.type == "file"
end

function fs.basename(path)
   return string.gsub(path, "(.*" .. dir_sep .. ")(.*)", "%2")
end

function fs.filename_part(path)
   return string.gsub(fs.basename(path), "(.*)%..*", "%1")
end

function fs.extension_part(path)
   return string.gsub(fs.basename(path), ".*%.(.*)", "%1")
end

function fs.parent(path)
   return string.match(path, "^(.+)" .. dir_sep)
end

function fs.is_root(path)
   if is_windows then
      return string.match(path, "^[a-zA-Z]:\\$")
   else
      return path == "/"
   end
end

function fs.copy(from, to)
   if not fs.is_file(from) then
      return false, string.format("file not found or is directory: %s", from)
   end

   local content, err = fs.read(from)
   if not content then
      return false, string.format("error reading file %s: %s", from, err)
   end

   fs.create_directory(fs.parent(to))

   return fs.write(to, content)
end

function fs.copy_directory(from, to)
   if not fs.is_directory(from) then
      return false, string.format("file not found or is not directory: %s", from)
   end

   local last_dir = fs.basename(from)
   local to = fs.join(to, last_dir)
   fs.create_directory(to)

   for _, entry in fs.iter_directory_items(from) do
      local from_item = fs.join(from, entry)
      local to_item = fs.join(to, entry)

      if fs.is_file(from_item) then
         local success, err = fs.copy(from_item, to_item)
         if not success then
            return success, err
         end
      elseif fs.is_directory(from_item) then
         fs.create_directory(to_item)
         local success, err = fs.copy_directory(from_item, to_item)
         if not success then
            return success, err
         end
      end
   end

   return true, nil
end

function fs.move(from, to)
   local ok, err = fs.copy(from, to)
   if not ok then
      return false, err
   end

   return fs.remove(from)
end

function fs.get_temporary_directory()
   if is_windows then
      -- os.tmpname() doesn't include %TEMP% on Windows
      return os.getenv("TEMP")
   else
      return fs.parent(os.tmpname())
   end
end


--
-- These functions are from luacheck.
--

local function ensure_dir_sep(path)
   if string.sub(path, -1) ~= dir_sep then
      return path .. dir_sep
   end

   return path
end

function fs.split_base(path)
   if is_windows then
      if string.match(path, "^%a:\\") then
         return string.sub(path, 1, 3), string.sub(path, 4)
      else
         -- Disregard UNC paths and relative paths with drive letter.
         return "", path
      end
   else
      if string.match(path, "^/") then
         if string.match(path, "^//") then
            return "//", string.sub(path, 3)
         else
            return "/", string.sub(path, 2)
         end
      else
         return "", path
      end
   end
end

function fs.is_absolute(path)
   return fs.split_base(path) ~= ""
end

local function join_two_paths(base, path)
   if base == "" or fs.is_absolute(path) then
      return path
   else
      return ensure_dir_sep(base) .. path
   end
end

function fs.normalize(path)
   -- if is_windows then
   --    path = path:lower()
   -- end
   path = path:gsub("[/\\]", dir_sep)
   local base, rest = fs.split_base(path)

   local parts = {}

   for part in rest:gmatch("[^"..dir_sep.."]+") do
      if part ~= "." then
         if part == ".." and #parts > 0 and parts[#parts] ~= ".." then
            parts[#parts] = nil
         else
            parts[#parts + 1] = part
         end
      end
   end

   if base == "" and #parts == 0 then
      return "."
   else
      return base..table.concat(parts, dir_sep)
   end
end

function fs.join(base, ...)
   local res = base

   for i = 1, select("#", ...) do
      res = join_two_paths(res, select(i, ...))
   end

   res = fs.normalize(res)

   return res
end

local EXTS = { "lua" }
function fs.can_load(path)
   local my_ext = fs.extension_part(path)
   for _, ext in ipairs(EXTS) do
      if my_ext == ext then
         return true
      end
   end
   return false
end

-- Searches for a file loadable with `require` at the nested path, which is one
-- that ends with .lua.
-- @param ... Set of directory components, without file
-- extension @treturn[opt] string
function fs.find_loadable(...)
   local path = fs.join(...)
   for _, ext in ipairs(EXTS) do
      local full_path = path .. "." .. ext
      if fs.is_file(full_path) then
         return full_path
      end
   end

   return nil
end

local function case_insensitive(pattern)
  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end

local WINDOWS_RESERVED = {
   "con",
   "prn",
   "aux",
   "nul",
   "com[0-9]",
   "lpt[0-9]",
}

-- Converts an arbitrary string to a valid filename, if any.
function fs.sanitize(path, rep)
   rep = rep or ""
   path = path:gsub("[/?<>\\:*|\"]", rep)
      :gsub("^%.+$", rep)
      :gsub("[. ]+$", rep)

   for _, pat in ipairs(WINDOWS_RESERVED) do
      path = path:gsub(case_insensitive(pat) .. "%..*", rep)
      path = path:gsub(case_insensitive(pat), rep)
   end

   return path:sub(0, 255)
end

return fs
