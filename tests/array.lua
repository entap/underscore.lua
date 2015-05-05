
local _ = require("lib.underscore")

local a = { 1001, 1002, 1003, 1004, 1005 }
local r = {}

r = _.slice(a, 2, 4)
print(r[1] == 1002)
print(r[2] == 1003)
print(r[3] == 1004)

print(_.first(a) == 1001)
r = _.first(a, 2)
print(r[1] == 1001)
print(r[2] == 1002)

r = _.initial(a)
print(r[1] == 1001)
print(#r == 4)
r = _.initial(a, 2)
print(#r == 3)

print(_.last(a) == 1005)
r = _.last(a, 2)
print(r[1] == 1004)
print(r[2] == 1005)

r = _.rest(a)
print(r[1] == 1002)
print(r[4] == 1005)
print(#r == 4)
r = _.rest(a, 2)
print(#r == 3)

r = _.flatten({ 1001, { 1002, 1003 }})
print(r[1] == 1001)
print(r[2] == 1002)
print(r[3] == 1003)

a = { 1001, { 1002, { 1003 }}}
r = _.flatten(a, false)
print(r[1] == 1001)
print(r[2] == 1002)
print(r[3] == 1003)
r = _.flatten(a, true)
print(r[1] == 1001)
print(r[2] == 1002)
print(r[3][1] == 1003)

a = { 1, 2, 3, 2, 3, 4, 1 }
r = _.unique(a)
print(r[1] == 1)
print(r[2] == 2)
print(r[3] == 3)
print(r[4] == 4)

a = { 1, 2, 2, 5, 5 }
r = _.unique(a, true)
print(r[1] == 1)
print(r[2] == 2)
print(r[3] == 5)

r = _.union({ 1, 2, 3 }, { 2, 3, 4 })
print(r[1] == 1)
print(r[2] == 2)
print(r[3] == 3)
print(r[4] == 4)

r = _.intersection({ 1, 2, 3, 1, 2, 3 }, { 101, 2, 1, 10 }, { 2, 1 })
print(r[1] == 1)
print(r[2] == 2)

r = _.difference({ 1, 2, 3, 4, 5 }, { 5, 2, 10 })
print(r[1] == 1)
print(r[2] == 3)
print(r[3] == 4)

