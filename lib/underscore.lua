-- Underscore.lua 1.8.3.0
-- http://entap.github.io/underscore.lua
-- Ported by Toshimasa Matsuoka, Entap Inc.
--
-- Underscore.js 1.8.3
-- http://underscorejs.org
-- (c) 2009-2015 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
-- Underscore may be freely distributed under the MIT license.

-- Baseline setup
-- --------------

local underscore = {}

-- Current version.
underscore.VERSION = "1.8.3"

-- Internal function that returns an efficient (for current engines) version
-- of the passed-in callback, to be repeatedly applied in other Underscore
-- functions.
local function optimizeCb(func, context)
	if context == nil then
		return func
	else
		return function(...)
			return func(context, ...)
		end
	end
end

-- A mostly-internal function to generate callbacks that can be applied
-- to each element in a collection, returning the desired result — either
-- identity, an arbitrary callback, a property matcher, or a property accessor.
local function cb(value, context)
	if value == nil then
		return underscore.identity
	elseif underscore.isFunction(value) then
		return optimizeCb(value, context)
	elseif underscore.isTable(value) then
		return underscore.matcher(value)
	else
		return underscore.property(value)
	end
end
function underscore.iteratee(value, context)
	return cb(value, context)
end

-- Similar to ES6's rest param (http://ariya.ofilabs.com/2013/03/es6-and-rest-parameter.html)
-- This accumulates the arguments passed into an array, after a given index.
local function restArgs(func, startIndex)
	return function(...)
		local args = {...}
		local rest = {}
		local n = #args - startIndex + 1
		for i = 1, n do
			local j = startIndex + i - 1
			rest[i] = args[j]
			args[j] = nil
		end
		args[startIndex] = rest
		return func(unpack(args))
	end
end

local function property(key)
	return function(obj)
		return obj and obj[key]
	end
end

-- Collection Functions
-- --------------------

---
-- Iterates over a list of elements,
-- yielding each in turn to an iteratee function.
--
function underscore.each(obj, iteratee, context)
	iteratee = optimizeCb(iteratee, context)
	for k, v in pairs(obj) do
		iteratee(v, k, obj)
	end
	return obj
end

---
-- Produces a new array of values by mapping each value in list
-- through a transformation function (iteratee).
--
function underscore.map(obj, iteratee, context)
	local results = {}
	for k, v in pairs(obj) do
		results[k] = iteratee(v, k, obj)
	end
	return results
end

-- Create a reducing function iterating left or right.
local createReduce = function(dir)
--  -- Optimized iterator function as using arguments.length
--  -- in the main function will deoptimize the, see #1991.
--  local iterator = function(obj, iteratee, memo, keys, index, length)
--    for (; index >= 0 && index < length; index += dir) {
--      local currentKey = keys ? keys[index] : index;
--      memo = iteratee(memo, obj[currentKey], currentKey, obj);
--    }
--    return memo;
--  };

--  return function(obj, iteratee, memo, context)
--    iteratee = optimizeCb(iteratee, context, 4);
--    local keys = !isArrayLike(obj) && underscore.keys(obj),
--        length = (keys || obj).length,
--        index = dir > 0 ? 0 : length - 1;
--    -- Determine the initial value if none is provided.
--    if (arguments.length < 3) {
--      memo = obj[keys ? keys[index] : index];
--      index += dir;
--    }
--    return iterator(obj, iteratee, memo, keys, index, length);
--  };
end

-- **Reduce** builds up a single result from a list of values, aka `inject`,
-- or `foldl`.
function underscore.reduce(obj, iteratee, memo, context)
	local k
	iteratee = optimizeCb(iteratee, context)
	if memo == nil then
		k, memo = next(obj)
	end
	for k, v in next, obj, k do
		memo = iteratee(memo, v, k, obj)
	end
	return memo
end
underscore.foldl = underscore.reduce
underscore.inject = underscore.reduce

-- The right-associative version of reduce, also known as `foldr`.
--underscore.reduceRight = createReduce(-1)
underscore.foldr = underscore.reduceRight

-- Return the first value which passes a truth test. Aliased as `detect`.
function underscore.find(obj, predicate, context)
	local k = underscore.findKey(obj, predicate, context)
	return obj and k and obj[k]
end
underscore.detect = underscore.find

-- Return all the elements that pass a truth test.
-- Aliased as `select`.
function underscore.filter(obj, predicate, context)
	local results = {}
	local i = 1
	predicate = cb(predicate, context)
	for k, v in pairs(obj) do
		if predicate(v, k, obj) then
			results[i] = v
			i = i + 1
		end
	end
	return results
end
underscore.select = underscore.filter

-- Return all the elements for which a truth test fails.
function underscore.reject(obj, predicate, context)
	return underscore.filter(obj, underscore.negate(cb(predicate)), context)
end

-- Determine whether all of the elements match a truth test.
-- Aliased as `all`.
function underscore.every(obj, predicate, context)
	predicate = cb(predicate, context)
	for k, v in pairs(obj) do
		if not predicate(v, k, obj) then
			return false
		end
	end
	return true
end
underscore.all = underscore.every

-- Determine if at least one element in the object matches a truth test.
-- Aliased as `any`.
function underscore.some(obj, predicate, context)
	predicate = cb(predicate, context)
	for k, v in pairs(obj) do
		if predicate(v, k, obj) then
			return true
		end
	end
	return false
end
underscore.any = underscore.some

-- Determine if the array or object contains a given item (using `===`).
-- Aliased as `includes` and `include`.
function underscore.contains(obj, item, fromIndex, guard)
--  if (!isArrayLike(obj)) obj = underscore.values(obj);
--  if (typeof fromIndex != 'number' || guard) fromIndex = 0;
--  return underscore.indexOf(obj, item, fromIndex) >= 0;
end
underscore.includes = underscore.contains
underscore.include = underscore.contains

-- Invoke a method (with arguments) on every item in a collection.
underscore.invoke = restArgs(function(obj, method, args)
	local isFunc = underscore.isFunction(method)
	return underscore.map(obj, function(value)
		if isFunc then
			return value and method(value, unpack(args))
		else
			return value and value[method] and value[method](value, unpack(args))
		end
	end)
end, 3)

-- Convenience version of a common use case of `map`: fetching a property.
function underscore.pluck(obj, key)
	return underscore.map(obj, underscore.property(key))
end

-- Convenience version of a common use case of `filter`: selecting only objects
-- containing specific `key:value` pairs.
function underscore.where(obj, attrs)
	return underscore.filter(obj, underscore.matcher(attrs))
end

-- Convenience version of a common use case of `find`: getting the first object
-- containing specific `key:value` pairs.
function underscore.findWhere(obj, attrs)
	return underscore.find(obj, underscore.matcher(attrs))
end

-- Return the maximum element (or element-based computation).
function underscore.max(obj, iteratee, context)
	iteratee = iteratee and cb(iteratee, context) or underscore.identity
	local k, result = next(obj)
	local lastComputed = iteratee(result)
	for k, v in next, obj, k do
		local computed = iteratee(v, k, obj)
		if computed > lastComputed then
			result = v
			lastComputed = computed
		end
	end
	return result
end

-- Return the minimum element (or element-based computation).
function underscore.min(obj, iteratee, context)
	iteratee = iteratee and cb(iteratee, context) or underscore.identity
	return underscore.max(obj, function(...) return -iteratee(...) end)
end

-- Shuffle a collection, using the modern version of the
-- [Fisher-Yates shuffle](http://en.wikipedia.org/wiki/Fisher–Yates_shuffle).
function underscore.shuffle(obj)
	local shuffled = {}
	for i, v in ipairs(obj) do
		local r = math.random(1, i)
		if rand ~= i then
			shuffled[i] = shuffled[r]
		end
		shuffled[r] = obj[i]
	end
	return shuffled
end

-- Sample **n** random values from a collection.
-- If **n** is not specified, returns a single random element.
-- The internal `guard` argument allows it to work with `map`.
function underscore.sample(obj, n, guard)
	if n == nil or guard then
		return obj[math.random(1, #obj)]
	else
		local shuffled = underscore.shuffle(obj)
		local results = {}
		n = math.min(n, #shuffled)
		for i = 1, n do
			results[i] = shuffled[i]
		end
		return results
	end
end

-- Sort the object's values by a criterion produced by an iteratee.
function underscore.sortBy(obj, iteratee, context)
	iteratee = cb(iteratee, context)
	local tmp = underscore.map(obj, function(v, k, obj)
		return { v = v, k = k, c = iteratee(v, k, obj) }
	end)
	table.sort(tmp, function(a, b)
		if a.c ~= b.c then
			return a.c < b.c
		else
			return a.k < b.k
		end
	end)
	return underscore.pluck(tmp, "v")
end

-- An internal function used for aggregate "group by" operations.
local group = function(behavior, partition)
	return function(obj, iteratee, context)
		local result = partition and {{},{}} or {}
		iteratee = cb(iteratee, context)
		for k, v in pairs(obj) do
			behavior(result, v, iteratee(v, k, obj))
		end
		return result
	end
end

-- Groups the object's values by a criterion. Pass either a string attribute
-- to group by, or a function that returns the criterion.
underscore.groupBy = group(function(result, value, key)
	if result[key] then
		table.insert(result[key], value)
	else
		result[key] = {value}
	end
end)

-- Indexes the object's values by a criterion, similar to `groupBy`, but for
-- when you know that your index values will be unique.
underscore.indexBy = group(function(result, value, key)
	result[key] = value
end)

-- Counts instances of an object that group by a certain criterion. Pass
-- either a string attribute to count by, or a function that returns the
-- criterion.
underscore.countBy = group(function(result, value, key)
	if result[key] then
		result[key] = result[key] + 1
	else
		result[key] = 1
	end
end)

-- Safely create a real, live array from anything iterable.
function underscore.toArray(obj)
	if obj == nil then
		return {}
	else
		return obj
	end
--  if (!obj) return [];
--  if (underscore.isArray(obj)) return slice.call(obj);
--  if (isArrayLike(obj)) return underscore.map(obj, underscore.identity);
--  return underscore.values(obj);
end

-- Return the number of elements in an object.
function underscore.size(obj)
	if obj == nil then
		return 0
	else
		local size = 0
		for k, v in pairs(obj) do
			size = size + 1
		end
		return size
	end
end

-- Split a collection into two arrays: one whose elements all satisfy the given
-- predicate, and one whose elements all do not satisfy the predicate.
underscore.partition = group(function(result, value, pass)
	table.insert(result[pass and 1 or 2], value)
end, true)

-- Array Functions
-- ---------------

function underscore.slice(array, startIndex, endIndex)
	local results = {}
	local j = 1
	endIndex = endIndex or #array
	for i = startIndex, endIndex do
		results[j] = array[i]
		j = j + 1
	end
	return results
end

-- Get the first element of an array. Passing **n** will return the first N
-- values in the array. Aliased as `head` and `take`. The **guard** check
-- allows it to work with `underscore.map`.
function underscore.first(array, n, guard)
	if array == nil then
		return nil
	elseif n == nil or guard then
		return array[1]
	else
		return underscore.slice(array, 1, n)
	end
end
underscore.head = underscore.first
underscore.take = underscore.first

-- Returns everything but the last entry of the array. Especially useful on
-- the arguments object. Passing **n** will return all the values in
-- the array, excluding the last N.
function underscore.initial(array, n, guard)
	return underscore.slice(array, 1, #array - ((n == nil or guard) and 1 or n))
end

-- Get the last element of an array. Passing **n** will return the last N
-- values in the array.
function underscore.last(array, n, guard)
	if array == nil then
		return nil
	elseif n == nil or guard then
		return array[#array]
	else
		return underscore.slice(array, #array - n + 1)
	end
end

-- Returns everything but the first entry of the array. Aliased as `tail` and `drop`.
-- Especially useful on the arguments object. Passing an **n** will return
-- the rest N values in the array.
function underscore.rest(array, n, guard)
	return underscore.slice(array, (n == nil or guard) and 2 or (n + 1))
end
underscore.tail = underscore.rest
underscore.drop = underscore.rest

-- Trim out all falsy values from an array.
--underscore.compact = function(array)
--	local results = {}
--	for i, v in ipairs(array) do
--		results[i] = v
--	end
--	return results
--end

-- Internal implementation of a recursive `flatten` function.
local function flatten(input, shallow, strict, startIndex)
	local output = {}
	local j = 1
	for k, v in pairs(input) do
		if type(v) == "table" then
			--flatten current level of array or arguments object
			if not shallow then
				v = flatten(v, shallow, strict)
			end
			for i, w in ipairs(v) do
				output[j] = w
				j = j + 1
			end
		elseif not strict then
			output[j] = v
			j = j + 1
		end
	end
	return output
end

-- Flatten out an array, either recursively (by default), or just one level.
function underscore.flatten(array, shallow)
	return flatten(array, shallow, false)
end

-- Return a version of the array that does not contain the specified value(s).
underscore.without = restArgs(function(array, otherArrays)
	return underscore.difference(array, otherArrays)
end)

-- Produce a duplicate-free version of the array. If the array has already
-- been sorted, you have the option of using a faster algorithm.
-- Aliased as `unique`.
function underscore.uniq(array, isSorted, iteratee, context)
	if not underscore.isBoolean(isSorted) then
		context = iteratee
		iteratee = isSorted
		isSorted = false
	end
	iteratee = iteratee and cb(iteratee, context) or underscore.identity
	local result = {}
	local j = 1
	local seen = {}
	for i, v in ipairs(array) do
		local computed = iteratee(v, i, array)
		if isSorted then
			if seen ~= computed then
				seen = computed
				result[j] = v
				j = j + 1
			end
		else
			if not seen[computed] then
				seen[computed] = true
				result[j] = v
				j = j + 1
			end
		end
	end
	return result
end
underscore.unique = underscore.uniq

-- Produce an array that contains the union: each distinct element from all of
-- the passed-in arrays.
function underscore.union(...)
	return underscore.uniq(flatten({...}, true, true))
end

-- Produce an array that contains every item shared between all the
-- passed-in arrays.
function underscore.intersection(...)
	local args = {...}
	local counts = {}
	for i, array in ipairs(args) do
		local seen = {}
		for k, v in pairs(array) do
			if not seen[v] then
				counts[v] = counts[v] and (counts[v] + 1) or 1
				seen[v] = true
			end
		end
	end
	local result = {}
	local argc = #args
	local i = 1
	for k, v in pairs(counts) do
		if v == argc then
			result[i] = k
			i = i + 1
		end
	end
	return result
end

-- Take the difference between one array and a number of other arrays.
-- Only the elements present in just the first array will remain.
function underscore.difference(array, ...)
	local t = {}
	for k, v in pairs(array) do
		t[v] = true
	end
	local args = {...}
	for i, arg in pairs(args) do
		for k, v in pairs(arg) do
			t[v] = nil
		end
	end
	local result = {}
	local i = 1
	for k, v in pairs(t) do
		result[i] = k
		i = i + 1
	end
	return result
end

-- Zip together multiple lists into a single array -- elements that share
-- an index go together.
underscore.zip = function(array)
	return underscore.unzip(array)
end

-- Complement of underscore.zip. Unzip accepts an array of arrays and groups
-- each array's elements on shared indices
underscore.unzip = function(array)
	local n = underscore.max(array, table.maxn)
	local result = {}
	for i, _ in ipairs(array[1]) do
		result[i] = underscore.pluck(array, i)
	end
	return result
--  local length = array && underscore.max(array, getLength).length || 0;
--  local result = Array(length);

--  for (local index = 0; index < length; index++) {
--    result[index] = underscore.pluck(array, index);
--  }
--  return result;
end

-- Converts lists into objects. Pass either a single array of `[key, value]`
-- pairs, or two parallel arrays of the same length -- one of keys, and one of
-- the corresponding values.
underscore.object = function(list, values)
	local result = {}
	for i, v in ipairs(list) do
		if values then
			result[v] = values[i]
		else
			result[v[1]] = v[2]
		end
	end
	return result
--  local result = {};
--  for (local i = 0, length = getLength(list); i < length; i++) {
--    if (values) {
--      result[list[i]] = values[i];
--    } else {
--      result[list[i][0]] = list[i][1];
--    }
--  }
--  return result;
end

-- Generator function to create the findIndex and findLastIndex functions
local createPredicateIndexFinder = function(dir)
	return function(array, predicate, context)
		predicate = cb(predicate, context)
	end
--  return function(array, predicate, context)
--    predicate = cb(predicate, context);
--    local length = getLength(array);
--    local index = dir > 0 ? 0 : length - 1;
--    for (; index >= 0 && index < length; index += dir) {
--      if (predicate(array[index], index, array)) return index;
--    }
--    return -1;
--  };
end

-- Returns the first index on an array-like that passes a predicate test
function underscore.findIndex(array, predicate, context)
	predicate = cb(predicate, context)
	for i, v in ipairs(array) do
		if predicate(v) then
			return i
		end
	end
	return -1
end

function underscore.findLastIndex(array, predicate, context)
	predicate = cb(predicate, context)
	for i = #array, 1, -1 do
		if predicate(array[i]) then
			return i
		end
	end
	return -1
end

-- Use a comparator function to figure out the smallest index at which
-- an object should be inserted so as to maintain order. Uses binary search.
function underscore.sortedIndex(array, obj, iteratee, context)
	iteratee = cb(iteratee, context, 1)
	local value = iteratee(obj)
	local low = 1
	local high = #array
	while low < high do
		local mid = math.floor((low + high) / 2)
		if iteratee(array[mid]) < value then
			low = mid + 1
		else
			high = mid
		end
	end
	return low
end

-- Generator function to create the indexOf and lastIndexOf functions
local createIndexFinder = function(dir, predicateFind, sortedIndex)
--  return function(array, item, idx)
--    local i = 0, length = getLength(array);
--    if (typeof idx == 'number') {
--      if (dir > 0) {
--          i = idx >= 0 ? idx : Math.max(idx + length, i);
--      } else {
--          length = idx >= 0 ? Math.min(idx + 1, length) : idx + length + 1;
--      }
--    } else if (sortedIndex && idx && length) {
--      idx = sortedIndex(array, item);
--      return array[idx] === item ? idx : -1;
--    }
--    if (item !== item) {
--      idx = predicateFind(slice.call(array, i, length), underscore.isNaN);
--      return idx >= 0 ? idx + i : -1;
--    }
--    for (idx = dir > 0 ? i : length - 1; idx >= 0 && idx < length; idx += dir) {
--      if (array[idx] === item) return idx;
--    }
--    return -1;
--  };
end

-- Return the position of the first occurrence of an item in an array,
-- or -1 if the item is not included in the array.
-- If the array is large and already in sort order, pass `true`
-- for **isSorted** to use binary search.
underscore.indexOf = createIndexFinder(1, underscore.findIndex, underscore.sortedIndex)
underscore.lastIndexOf = createIndexFinder(-1, underscore.findLastIndex)

-- Generate an integer Array containing an arithmetic progression. A port of
-- the native Python `range()` function. See
-- [the Python documentation](http://docs.python.org/library/functions.html#range).
function underscore.range(start, stop, step)
	if stop == nil then
		stop = start or 1
		start = 1
	end
	step = step or 1
	local range = {}
	local i = 1
	while start < stop do
		range[i] = start
		i = i + 1
		start = start + step
	end
	return range
end

-- Function (ahem) Functions
-- ------------------

-- Determines whether to execute a function as a constructor
-- or a normal function with the provided arguments
local executeBound = function(sourceFunc, boundFunc, context, callingContext, args)
--  if (!(callingContext instanceof boundFunc)) return sourceFunc.apply(context, args);
--  local self = baseCreate(sourceFunc.prototype);
--  local result = sourceFunc.apply(self, args);
--  if (underscore.isObject(result)) return result;
--  return self;
end

-- Create a function bound to a given object (assigning `this`, and arguments,
-- optionally). Delegates to **ECMAScript 5**'s native `Function.bind` if
-- available.
underscore.bind = function(func, ...)
	local bindArgs = ...
	return function(...)
		return func(bindArgs, ...)
	end
--  if (nativeBind && func.bind === nativeBind) return nativeBind.apply(func, slice.call(arguments, 1));
--  if (!underscore.isFunction(func)) throw new TypeError('Bind must be called on a function');
--  local args = slice.call(arguments, 2);
--  local bound = restArgs(function(callArgs)
--    return executeBound(func, bound, context, this, args.concat(callArgs));
--  });
--  return bound;
end

-- Partially apply a function by creating a version that has had some of its
-- arguments pre-filled, without changing its dynamic `this` context. _ acts
-- as a placeholder by default, allowing any combination of arguments to be
-- pre-filled. Set `underscore.partial.placeholder` for a custom placeholder argument.
underscore.partial = restArgs(function(func, boundArgs)
--  local placeholder = underscore.partial.placeholder;
--  local bound = function()
--    local position = 0, length = boundArgs.length;
--    local args = Array(length);
--    for (local i = 0; i < length; i++) {
--      args[i] = boundArgs[i] === placeholder ? arguments[position++] : boundArgs[i];
--    }
--    while (position < arguments.length) args.push(arguments[position++]);
--    return executeBound(func, bound, this, this, args);
--  };
--  return bound;
end)

-- underscore.partial.placeholder = _;

-- Bind a number of an object's methods to that object. Remaining arguments
-- are the method names to be bound. Useful for ensuring that all callbacks
-- defined on an object belong to it.
underscore.bindAll = restArgs(function(obj, keys)
--  if (keys.length < 1) throw new Error('bindAll must be passed function names');
--  return underscore.each(keys, function(key)
--    obj[key] = underscore.bind(obj[key], obj);
--  });
end)

-- Memoize an expensive function by storing its results.
underscore.memoize = function(func, hasher)
	local cache = {}
	hasher = hasher or _.first
	return function(...)
		local address = hasher(...)
		if cache[address] == nil then
			cache[address] = func(...)
		end
		return cache[address]
	end
--  local memoize = function(key)
--    local cache = memoize.cache;
--    local address = '' + (hasher ? hasher.apply(this, arguments) : key);
--    if (!underscore.has(cache, address)) cache[address] = func.apply(this, arguments);
--    return cache[address];
--  };
--  memoize.cache = {};
--  return memoize;
end

-- Delays a function for the given number of milliseconds, and then calls
-- it with the arguments supplied.
underscore.delay = restArgs(function(func, wait, args)
--  return setTimeout(function(){
--    return func.apply(null, args);
--  }, wait);
end)

-- Defers a function, scheduling it to run after the current call stack has
-- cleared.
-- underscore.defer = underscore.partial(underscore.delay, _, 1);

-- Returns a function, that, when invoked, will only be triggered at most once
-- during a given window of time. Normally, the throttled function will run
-- as much as it can, without ever going more than once per `wait` duration;
-- but if you'd like to disable the execution on the leading edge, pass
-- `{leading: false}`. To disable execution on the trailing edge, ditto.
underscore.throttle = function(func, wait, options)
--  local context, args, result;
--  local timeout = null;
--  local previous = 0;
--  if (!options) options = {};
--  local later = function()
--    previous = options.leading === false ? 0 : underscore.now();
--    timeout = null;
--    result = func.apply(context, args);
--    if (!timeout) context = args = null;
--  };
--  return function()
--    local now = underscore.now();
--    if (!previous && options.leading === false) previous = now;
--    local remaining = wait - (now - previous);
--    context = this;
--    args = arguments;
--    if (remaining <= 0 || remaining > wait) {
--      if (timeout) {
--        clearTimeout(timeout);
--        timeout = null;
--      }
--      previous = now;
--      result = func.apply(context, args);
--      if (!timeout) context = args = null;
--    } else if (!timeout && options.trailing !== false) {
--      timeout = setTimeout(later, remaining);
--    }
--    return result;
--  };
end

-- Returns a function, that, as long as it continues to be invoked, will not
-- be triggered. The function will be called after it stops being called for
-- N milliseconds. If `immediate` is passed, trigger the function on the
-- leading edge, instead of the trailing.
underscore.debounce = function(func, wait, immediate)
--  local timeout, args, context, timestamp, result;

--  local later = function()
--    local last = underscore.now() - timestamp;

--    if (last < wait && last >= 0) {
--      timeout = setTimeout(later, wait - last);
--    } else {
--      timeout = null;
--      if (!immediate) {
--        result = func.apply(context, args);
--        if (!timeout) context = args = null;
--      }
--    }
--  };

--  return function()
--    context = this;
--    args = arguments;
--    timestamp = underscore.now();
--    local callNow = immediate && !timeout;
--    if (!timeout) timeout = setTimeout(later, wait);
--    if (callNow) {
--      result = func.apply(context, args);
--      context = args = null;
--    }

--    return result;
--  };
end

-- Returns the first function passed as an argument to the second,
-- allowing you to adjust arguments, run code before and after, and
-- conditionally execute the original function.
underscore.wrap = function(func, wrapper)
	return underscore.partial(wrapper, func)
end

-- Returns a negated version of the passed-in predicate.
underscore.negate = function(predicate)
	return function(...)
		return not predicate(...)
	end
end

-- Returns a function that is the composition of a list of functions, each
-- consuming the return value of the function that follows.
underscore.compose = function(...)
	local funcs = {...}
	return function(...)
		local result = funcs[#funcs](...)
		for i = #funcs-1, 1, -1 do
			result = funcs[i](result)
		end
		return result
	end
--  local args = arguments;
--  local start = args.length - 1;
--  return function()
--    local i = start;
--    local result = args[start].apply(this, arguments);
--    while (i--) result = args[i].call(this, result);
--    return result;
--  };
end

-- Returns a function that will only be executed on and after the Nth call.
underscore.after = function(times, func)
	return function(...)
		times = times - 1
		if (times < 1) then
			return func(...)
		end
	end
--  return function()
--    if (--times < 1) {
--      return func.apply(this, arguments);
--    }
--  };
end

-- Returns a function that will only be executed up to (but not including) the Nth call.
underscore.before = function(times, func)
	local memo
	return function(...)
		times = times - 1
		if times > 0 then
			memo = func(...)
		end
		if times <= 1 then
			func = nil
		end
		return memo
	end
--  local memo;
--  return function()
--    if (--times > 0) {
--      memo = func.apply(this, arguments);
--    }
--    if (times <= 1) func = null;
--    return memo;
--  };
end

-- Returns a function that will be executed at most one time, no matter how
-- often you call it. Useful for lazy initialization.
-- underscore.once = underscore.partial(underscore.before, 2);

underscore.restArgs = restArgs

-- Object Functions
-- ----------------

-- Retrieve the names of an object's own properties.
underscore.keys = function(obj)
	local keys = {}
	local i = 1
	for k, _ in pairs(obj) do
		keys[i] = k
		i = i + 1
	end
	return keys
end

-- Retrieve all the property names of an object.
underscore.allKeys = underscore.keys

-- Retrieve the values of an object's properties.
underscore.values = function(obj)
	local values = {}
	local i = 1
	for _, v in pairs(obj) do
		values[i] = v
		i = i + 1
	end
	return values
end

-- Returns the results of applying the iteratee to each element of the object
-- In contrast to underscore.map it returns an object
underscore.mapObject = underscore.map

-- Convert an object into a list of `[key, value]` pairs.
underscore.pairs = function(obj)
	local list = {}
	local i = 1
	for k, v in pairs(obj) do
		list[i] = { k, v }
	end
	return list
end

-- Invert the keys and values of an object. The values must be serializable.
underscore.invert = function(obj)
	local result = {}
	for k, v in pairs(obj) do
		result[v] = k
	end
	return result
end

-- Return a sorted list of the function names available on the object.
-- Aliased as `methods`
underscore.functions = function(obj)
	local names = {}
	local i = 1
	for k, _ in obj do
		if underscore.isFunction(v) then
			names[i] = v
			i = i + 1
		end
	end
	return names
end
underscore.methods = underscore.functions

-- An internal function for creating assigner functions.
local createAssigner = function(keysFunc, undefinedOnly)
--  return function(obj)
--    local length = arguments.length;
--    if (length < 2 || obj == null) return obj;
--    for (local index = 1; index < length; index++) {
--      local source = arguments[index],
--          keys = keysFunc(source),
--          l = keys.length;
--      for (local i = 0; i < l; i++) {
--        local key = keys[i];
--        if (!undefinedOnly || obj[key] === void 0) obj[key] = source[key];
--      }
--    }
--    return obj;
--  };
end

-- Extend a given object with all the properties in passed-in object(s).
underscore.extend = createAssigner(underscore.allKeys)

-- Assigns a given object with all the own properties in the passed-in object(s)
-- (https:--developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Object/assign)
underscore.extendOwn = createAssigner(underscore.keys)
underscore.assign = underscore.extendOwn

-- Returns the first key on an object that passes a predicate test
underscore.findKey = function(obj, predicate, context)
--  predicate = cb(predicate, context);
--  local keys = underscore.keys(obj), key;
--  for (local i = 0, length = keys.length; i < length; i++) {
--    key = keys[i];
--    if (predicate(obj[key], key, obj)) return key;
--  }
end

-- Return a copy of the object only containing the whitelisted properties.
underscore.pick = function(object, oiteratee, context)
--  local result = {}, obj = object, iteratee, keys;
--  if (obj == null) return result;
--  if (underscore.isFunction(oiteratee))
--    keys = underscore.allKeys(obj);
--    iteratee = optimizeCb(oiteratee, context);
--  } else {
--    keys = flatten(arguments, false, false, 1);
--    iteratee = function(value, key, obj) { return key in obj; };
--    obj = Object(obj);
--  }
--  for (local i = 0, length = keys.length; i < length; i++) {
--    local key = keys[i];
--    local value = obj[key];
--    if (iteratee(value, key, obj)) result[key] = value;
--  }
--  return result;
end

 -- Return a copy of the object without the blacklisted properties.
underscore.omit = function(obj, iteratee, context)
--  if (underscore.isFunction(iteratee))
--    iteratee = underscore.negate(iteratee);
--  } else {
--    local keys = underscore.map(flatten(arguments, false, false, 1), String);
--    iteratee = function(value, key)
--      return !underscore.contains(keys, key);
--    };
--  }
--  return underscore.pick(obj, iteratee, context);
end

-- Fill in a given object with default properties.
underscore.defaults = createAssigner(underscore.allKeys, true);

-- Creates an object that inherits from the given prototype object.
-- If additional properties are provided then they will be added to the
-- created object.
underscore.create = function(prototype, props)
--  local result = baseCreate(prototype);
--  if (props) underscore.extendOwn(result, props);
--  return result;
end

-- Create a (shallow-cloned) duplicate of an object.
underscore.clone = function(obj)
--  if (!underscore.isObject(obj)) return obj;
--  return underscore.isArray(obj) ? obj.slice() : underscore.extend({}, obj);
end

-- Invokes interceptor with the obj, and then returns obj.
-- The primary purpose of this method is to "tap into" a method chain, in
-- order to perform operations on intermediate results within the chain.
underscore.tap = function(obj, interceptor)
	interceptor(obj)
	return obj
end

-- Returns whether an object has a given set of `key:value` pairs.
underscore.isMatch = function(obj, attrs)
	for k, v in pairs(attrs) do
		if obj[k] ~= v then
			return false
		end
	end
	return true
end

-- Internal recursive comparison function for `isEqual`.
local eq = function(a, b, aStack, bStack)
--  -- Identical objects are equal. `0 === -0`, but they aren't identical.
--  -- See the [Harmony `egal` proposal](http://wiki.ecmascript.org/doku.php?id=harmony:egal).
--  if (a === b) return a !== 0 || 1 / a === 1 / b;
--  -- A strict comparison is necessary because `null == undefined`.
--  if (a == null || b == null) return a === b;
--  -- Unwrap any wrapped objects.
--  if (a instanceof _) a = a._wrapped;
--  if (b instanceof _) b = b._wrapped;
--  -- Compare `[[Class]]` names.
--  local className = toString.call(a);
--  if (className !== toString.call(b)) return false;
--  switch (className) {
--    -- Strings, numbers, regular expressions, dates, and booleans are compared by value.
--    case '[object RegExp]':
--    -- RegExps are coerced to strings for comparison (Note: '' + /a/i === '/a/i')
--    case '[object String]':
--      -- Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
--      -- equivalent to `new String("5")`.
--      return '' + a === '' + b;
--    case '[object Number]':
--      -- `NaN`s are equivalent, but non-reflexive.
--      -- Object(NaN) is equivalent to NaN
--      if (+a !== +a) return +b !== +b;
--      -- An `egal` comparison is performed for other numeric values.
--      return +a === 0 ? 1 / +a === 1 / b : +a === +b;
--    case '[object Date]':
--    case '[object Boolean]':
--      -- Coerce dates and booleans to numeric primitive values. Dates are compared by their
--      -- millisecond representations. Note that invalid dates with millisecond representations
--      -- of `NaN` are not equivalent.
--      return +a === +b;
--  }

--  local areArrays = className === '[object Array]';
--  if (!areArrays) {
--    if (typeof a != 'object' || typeof b != 'object') return false;

--    -- Objects with different constructors are not equivalent, but `Object`s or `Array`s
--    -- from different frames are.
--    local aCtor = a.constructor, bCtor = b.constructor;
--    if (aCtor !== bCtor && !(underscore.isFunction(aCtor) && aCtor instanceof aCtor &&
--                             underscore.isFunction(bCtor) && bCtor instanceof bCtor)
--                        && ('constructor' in a && 'constructor' in b)) {
--      return false;
--    }
--  }
--  -- Assume equality for cyclic structures. The algorithm for detecting cyclic
--  -- structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.

--  -- Initializing stack of traversed objects.
--  -- It's done here since we only need them for objects and arrays comparison.
--  aStack = aStack || [];
--  bStack = bStack || [];
--  local length = aStack.length;
--  while (length--) {
--    -- Linear search. Performance is inversely proportional to the number of
--    -- unique nested structures.
--    if (aStack[length] === a) return bStack[length] === b;
--  }

--  -- Add the first object to the stack of traversed objects.
--  aStack.push(a);
--  bStack.push(b);

--  -- Recursively compare objects and arrays.
--  if (areArrays) {
--    -- Compare array lengths to determine if a deep comparison is necessary.
--    length = a.length;
--    if (length !== b.length) return false;
--    -- Deep compare the contents, ignoring non-numeric properties.
--    while (length--) {
--      if (!eq(a[length], b[length], aStack, bStack)) return false;
--    }
--  } else {
--    -- Deep compare objects.
--    local keys = underscore.keys(a), key;
--    length = keys.length;
--    -- Ensure that both objects contain the same number of properties before comparing deep equality.
--    if (underscore.keys(b).length !== length) return false;
--    while (length--) {
--      -- Deep compare each member
--      key = keys[length];
--      if (!(underscore.has(b, key) && eq(a[key], b[key], aStack, bStack))) return false;
--    }
--  }
--  -- Remove the first object from the stack of traversed objects.
--  aStack.pop();
--  bStack.pop();
--  return true;
end

-- Perform a deep comparison to check if two objects are equal.
underscore.isEqual = function(a, b)
--  return eq(a, b);
end

-- Is a given array, string, or object empty?
-- An "empty" object has no enumerable own-properties.
underscore.isEmpty = function(obj)
--  if (obj == null) return true;
--  if (isArrayLike(obj) && (underscore.isArray(obj) || underscore.isString(obj) || underscore.isArguments(obj))) return obj.length === 0;
--  return underscore.keys(obj).length === 0;
end

-- Is a given value an array?
-- Delegates to ECMA5's native Array.isArray
--underscore.isArray = nativeIsArray || function(obj)
--  return toString.call(obj) === '[object Array]';
--end

-- Is a given value an table?
underscore.isTable = function(obj)
	return type(obj) == "table"
end

-- Add some isType methods: isArguments, isFunction, isString, isNumber, isDate, isRegExp, isError.
--underscore.each(['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp', 'Error'], function(name)
--  _['is' + name] = function(obj)
--    return toString.call(obj) === '[object ' + name + ']';
--  };
--});

-- Is a given value an function?
underscore.isFunction = function(obj)
	return type(obj) == "function"
end

-- Is a given object a finite number?
underscore.isFinite = function(obj)
	return obj == 1/0
end

-- Is the given value `NaN`? (NaN is the only number which does not equal itself).
underscore.isNaN = function(obj)
	return obj == 0/0
end

-- Is a given value a boolean?
underscore.isBoolean = function(obj)
	return type(obj) == "boolean"
end

-- Is a given value equal to nil?
underscore.isNil = function(obj)
	return obj == nil
end

-- Shortcut function for checking if an object has a given property directly
-- on itself (in other words, not on a prototype).
underscore.has = function(obj, key)
	return obj and obj[key] ~= nil
end

-- Utility Functions
-- -----------------

-- Keep the identity function around for default iteratees.
underscore.identity = function(value)
	return value
end

-- Predicate-generating functions. Often useful outside of Underscore.
underscore.constant = function(value)
	return function()
		return value
	end
end

underscore.noop = function()
end

underscore.property = property

-- Generates a function for a given object that returns a given property.
underscore.propertyOf = function(obj)
	if obj then
		return obj and obj[key]
	else
		return underscore.noop
	end
end

-- Returns a predicate for checking whether an object has a given set of
-- `key:value` pairs.
underscore.matcher = function(attrs)
--	attrs = underscore.extendOwn({}, attrs)
	return function(obj)
		return underscore.isMatch(obj, attrs)
	end
end
underscore.matches = underscore.matcher

-- Run a function **n** times.
underscore.times = function(n, iteratee, context)
--  local accum = Array(Math.max(0, n));
--  iteratee = optimizeCb(iteratee, context, 1);
--  for (local i = 0; i < n; i++) accum[i] = iteratee(i);
--  return accum;
end

-- Return a random integer between min and max (inclusive).
underscore.random = function(min, max)
--  if (max == null) {
--    max = min;
--    min = 0;
--  }
--  return min + Math.floor(Math.random() * (max - min + 1));
end

-- A (possibly faster) way to get the current timestamp as an integer.
--underscore.now = Date.now || function()
--  return new Date().getTime();
--end

 -- List of HTML entities for escaping.
local escapeMap = {
	['&'] = '&amp;',
	['<'] = '&lt;',
	['>'] = '&gt;',
	['"'] = '&quot;',
	["'"] = '&#x27;',
	['`'] = '&#x60;'
}
local unescapeMap = underscore.invert(escapeMap)

-- Functions for escaping and unescaping strings to/from HTML interpolation.
local createEscaper = function(map)
	local escaper = function(match)
		return map[match]
	end
	local pattern = ""
	for k, _ in pairs(map) do
		pattern = pattern .. '(' .. string.gsub(k, '([^%w])', '%%%1') .. ')|'
	end
	return function(str)
		return string.gsub(str, pattern, escaper)
	end
--  local escaper = function(match)
--    return map[match];
--  };
--  -- Regexes for identifying a key that needs to be escaped
--  local source = '(?:' + underscore.keys(map).join('|') + ')';
--  local testRegexp = RegExp(source);
--  local replaceRegexp = RegExp(source, 'g');
--  return function(string)
--    string = string == null ? '' : '' + string;
--    return testRegexp.test(string) ? string.replace(replaceRegexp, escaper) : string;
--  };
end
underscore.escape = createEscaper(escapeMap)
underscore.unescape = createEscaper(unescapeMap)

-- If the value of the named `property` is a function then invoke it with the
-- `object` as context; otherwise, return it.
underscore.result = function(object, property, fallback)
	local value = obj and obj[property] or fallback
	return underscore.isFunction(value) and value(object) or value
--  local value = object == null ? void 0 : object[property];
--  if (value === void 0) {
--    value = fallback;
--  }
--  return underscore.isFunction(value) ? value.call(object) : value;
end

-- Generate a unique integer id (unique within the entire client session).
-- Useful for temporary DOM ids.
local idCounter = 0
underscore.uniqueId = function(prefix)
	idCounter = idCounter + 1
	return (prefix or '') .. idCounter
--  local id = ++idCounter + '';
--  return prefix ? prefix + id : id;
end

-- By default, Underscore uses ERB-style template delimiters, change the
-- following template settings to use alternative delimiters.
underscore.templateSettings = {
--  evaluate    : /<%([\s\S]+?)%>/g,
--  interpolate : /<%=([\s\S]+?)%>/g,
--  escape      : /<%-([\s\S]+?)%>/g
}

-- When customizing `templateSettings`, if you don't want to define an
-- interpolation, evaluation or escaping regex, we need one that is
-- guaranteed not to match.
--local noMatch = /(.)^/;

-- Certain characters need to be escaped so that they can be put into a
-- string literal.
local escapes = {
--  "'":      "'",
--  '\\':     '\\',
--  '\r':     'r',
--  '\n':     'n',
--  '\u2028': 'u2028',
--  '\u2029': 'u2029'
}

--local escaper = /\\|'|\r|\n|\u2028|\u2029/g;

local escapeChar = function(match)
--  return '\\' + escapes[match];
end

-- JavaScript micro-templating, similar to John Resig's implementation.
-- Underscore templating handles arbitrary delimiters, preserves whitespace,
-- and correctly escapes quotes within interpolated code.
-- NB: `oldSettings` only exists for backwards compatibility.
underscore.template = function(text, settings, oldSettings)
--  if (!settings && oldSettings) settings = oldSettings;
--  settings = underscore.defaults({}, settings, underscore.templateSettings);

--  -- Combine delimiters into one regular expression via alternation.
--  local matcher = RegExp([
--    (settings.escape || noMatch).source,
--    (settings.interpolate || noMatch).source,
--    (settings.evaluate || noMatch).source
--  ].join('|') + '|$', 'g');

--  -- Compile the template source, escaping string literals appropriately.
--  local index = 0;
--  local source = "__p+='";
--  text.replace(matcher, function(match, escape, interpolate, evaluate, offset)
--    source += text.slice(index, offset).replace(escaper, escapeChar);
--    index = offset + match.length;

--    if (escape) {
--      source += "'+\n((__t=(" + escape + "))==null?'':underscore.escape(__t))+\n'";
--    } else if (interpolate) {
--      source += "'+\n((__t=(" + interpolate + "))==null?'':__t)+\n'";
--    } else if (evaluate) {
--      source += "';\n" + evaluate + "\n__p+='";
--    }

--    -- Adobe VMs need the match returned to produce the correct offest.
--    return match;
--  });
--  source += "';\n";

--  -- If a localiable is not specified, place data values in local scope.
--  if (!settings.localiable) source = 'with(obj||{}){\n' + source + '}\n';

--  source = "local __t,__p='',__j=Array.prototype.join," +
--    "print=function(){__p+=__j.call(arguments,'');};\n" +
--    source + 'return __p;\n';

--  try {
--    local render = new Function(settings.localiable || 'obj', '_', source);
--  } catch (e) {
--    e.source = source;
--    throw e;
--  }

--  local template = function(data)
--    return render.call(this, data, _);
--  };

--  -- Provide the compiled source as a convenience for precompilation.
--  local argument = settings.localiable || 'obj';
--  template.source = 'function(' + argument + '){\n' + source + '}';

--  return template;
end

-- Add a "chain" function. Start chaining a wrapped Underscore object.
underscore.chain = function(obj)
--  local instance = _(obj);
--  instance._chain = true;
--  return instance;
end

-- OOP
-- ---------------
-- If Underscore is called as a function, it returns a wrapped object that
-- can be used OO-style. This wrapper holds altered versions of all the
-- underscore functions. Wrapped objects may be chained.

-- Helper function to continue chaining intermediate results.
local result = function(instance, obj)
--  return instance._chain ? _(obj).chain() : obj;
end

-- Add your own custom functions to the Underscore object.
underscore.mixin = function(obj)
--  underscore.each(underscore.functions(obj), function(name)
--    local func = _[name] = obj[name];
--    underscore.prototype[name] = restArgs(function(args)
--      args.unshift(this._wrapped);
--      return result(this, func.apply(_, args));
--    });
--  });
end

-- Add all of the Underscore functions to the wrapper object.
underscore.mixin(underscore)

-- Add all mutator Array functions to the wrapper.
--underscore.each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name)
--  local method = ArrayProto[name];
--  underscore.prototype[name] = function()
--    local obj = this._wrapped;
--    method.apply(obj, arguments);
--    if ((name === 'shift' || name === 'splice') && obj.length === 0) delete obj[0];
--    return result(this, obj);
--  };
--});

-- Add all accessor Array functions to the wrapper.
--underscore.each(['concat', 'join', 'slice'], function(name)
--  local method = ArrayProto[name];
--  underscore.prototype[name] = function()
--    return result(this, method.apply(this._wrapped, arguments));
--  };
--});

return underscore