
local _ = require("lib.underscore")

local stooge = { name = "moe" }
print(_.property("name")(stooge) == "moe")

