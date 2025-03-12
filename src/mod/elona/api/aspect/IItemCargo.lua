local IAspect = require("api.IAspect")

local IItemCargo = class.interface("IItemCargo",
                                   {
                                      cargo_weight = "number",
                                      cargo_quality = "number",
                                      buying_price = { type = "number", optional = true }
                                   },
                                   { IAspect })

IItemCargo.default_impl = "mod.elona.api.aspect.ItemCargoAspect"

return IItemCargo
