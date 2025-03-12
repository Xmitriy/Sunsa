local Env = require("api.Env")
local Log = require("api.Log")
local Stopwatch = class.class("Stopwatch")

function Stopwatch:init(log_level, precision)
   self.time = Env.get_time()
   self.framerate = 60
   self.precision = precision or 5
   self.log_level = log_level or "debug"
   self:measure()
end

function Stopwatch:measure()
   local new = Env.get_time()
   local result = new - self.time
   self.time = new
   return math.round(result * 1000, self.precision)
end

local function msecs_to_frames(msecs, framerate)
   local msecs_per_frame = (1 / framerate) * 1000
   local frames = msecs / msecs_per_frame
   return frames
end

function Stopwatch:measure_and_format(text)
   if text then
      text = string.format("[%s]", text)
   else
      text = ""
   end

   local msecs = self:measure()
   return string.format("%s\t%02." .. string.format("%02d", self.precision) .. "fms\t(%02.02f frames)",
                        text,
                        msecs,
                        msecs_to_frames(msecs, self.framerate))
end

function Stopwatch:p(text)
   Log[self.log_level](self:measure_and_format(text))
end

function Stopwatch:bench(f, ...)
   self:measure()
   f(...)
   return self:measure_and_format()
end

return Stopwatch
