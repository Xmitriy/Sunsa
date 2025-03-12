local ILocation = require("api.ILocation")

-- A location that can store objects of more than one type.
return class.interface("ITypedLocation",
                 {
                    iter_type = "function",
                    iter_type_at_pos = "function",
                    get_object_of_type = "function",
                    has_object_of_type = "function",
                 },
                 ILocation)
