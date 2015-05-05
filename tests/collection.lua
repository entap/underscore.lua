
local _ = require("lib.underscore")

local a = {}
local r = {}

-- each
_.each({ 1, 2, 3 }, print)
_.each({ one = 1, two = 2, three = 3 }, print)

-- map
r = _.map({ 1, 2, 3 }, function(num) return num * 3 end)
print(r[1] == 3)
print(r[2] == 6)
print(r[3] == 9)

-- reduce
print(_.reduce({ 1, 2, 3 }, function(memo, num) return memo + num end) == 6)

-- filter
r = _.filter({ 1, 2, 3, 4, 5, 6 }, function(num) return num % 2 == 0 end)
print(r[1] == 2)
print(r[2] == 4)
print(r[3] == 6)

-- reject
r = _.reject({ 1, 2, 3, 4, 5, 6 }, function(num) return num % 2 == 0 end)
print(r[1] == 1)
print(r[2] == 3)
print(r[3] == 5)

-- every
print(_.every({ 2, 4, 6 }, function(num) return num % 2 == 0 end) == true)
print(_.every({ 2, 5, 6 }, function(num) return num % 2 == 0 end) == false)

-- some
print(_.some({ 1, 2, 3 }, function(num) return num % 2 == 0 end) == true)
print(_.some({ 1, 3, 5 }, function(num) return num % 2 == 0 end) == false)

-- invoke
local function greeting(self)
	print("Hello, " .. self.name)
end
local people = {
	{ name = "tom", age = 22, gender = "male", greeting = greeting },
	{ name = "anna", age = 18, gender = "female", greeting = greeting },
	{ name = "alan", age = 25, gender = "male", greeting = greeting },
}
_.invoke(people, "greeting")

-- pluck
r = _.pluck(people, "name")
print(r[1] == "tom")
print(r[2] == "anna")
print(r[3] == "alan")

-- where
r = _.where(people, { gender = "male" })
print(r[1].name == "tom")
print(r[2].name == "alan")

-- where
r = _.where(people, { gender = "male" })
print(r[1].name == "tom")
print(r[2].name == "alan")

-- max
r = _.max(people, function(obj) return obj.age end)
print(r.name == "alan")

-- min
r = _.min(people, function(obj) return obj.age end)
print(r.name == "tom")

-- shuffle
r = _.shuffle({ 1, 2, 3, 4, 5 })
print(r[1], r[2], r[3], r[4], r[5])

-- sample
r = _.sample({ 1, 2, 3, 4, 5 })
print(1 <= r and r <= 5)
r = _.sample({ 1, 2, 3, 4, 5 }, 3)
print(#r == 3)
print(_.every(r, function(v) return 1 <= v and v <= 5 end))

-- sortBy
r = _.sortBy(people, "name")
print(r[1].name == "alan")
print(r[2].name == "anna")
print(r[3].name == "tom")

r = _.sortBy(people, function(obj) return obj.age end)
print(r[1].name == "anna")
print(r[2].name == "tom")
print(r[3].name == "alan")

r = _.groupBy(people, "gender")
print(r["male"][1].name == "tom")
print(r["male"][2].name == "alan")
print(r["female"][1].name == "anna")

r = _.indexBy(people, "age")
print(r[18].name == "anna")
print(r[22].name == "tom")
print(r[25].name == "alan")

r = _.countBy(people, "gender")
print(r["male"] == 2)
print(r["female"] == 1)

print(_.size(nil) == 0)
print(_.size(people) == 3)

r = _.partition(people, function(obj) return obj.age % 2 == 0 end)
print(r[1][1].name == "tom")
print(r[1][2].name == "anna")
print(r[2][1].name == "alan")
