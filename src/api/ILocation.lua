--- @module ILocation

local ILocation = class.interface("ILocation",
                 {
                    is_positional = "function",
                    move_object = "function",
                    remove_object = "function",
                    take_object = "function",
                    objects_at_pos = "function",
                    is_in_bounds = "function",

                    get_object = "function",
                    has_object = "function",
                    can_take_object = "function",
                    iter = "function",
                 })

--- Attempts to take ownership of map object. This function may fail.
--- If it fails, no state in the location is expected to be changed.
--- Returns the map object on success or nil on failure.
-- @function take_object
-- @tparam ILocation self
-- @tparam IMapObject obj
-- @treturn[opt] IMapObject obj

return ILocation
