local s = "003"
return {
    -- Tests for table utility functions.
    -- config = none,
    suite = s,
    tests = {
        [s .. "01"] = {
            description = "table.append - append two tables",
            run = function()
                local target = { "a", "b" }
                local source = { "c", "d" }
                table.append(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b", "c", "d" })
        },
        [s .. "02"] = {
            description = "table.append - append to an empty table",
            run = function()
                local target = {}
                local source = { "a", "b" }
                table.append(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b" })
        },
        [s .. "03"] = {
            description = "table.append - append nil source",
            run = function()
                local target = { "a", "b" }
                table.append(target, nil)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b" })
        },
        [s .. "04"] = {
            description = "table.contains - value is present",
            run = function()
                return table.contains({ "a", "b", "c" }, "b")
            end,
            expected = true
        },
        [s .. "05"] = {
            description = "table.contains - value is not present",
            run = function()
                return table.contains({ "a", "b", "c" }, "d")
            end,
            expected = false
        },
        [s .. "06"] = {
            description = "table.contains - table is nil",
            run = function()
                return table.contains(nil, "a")
            end,
            expected = false
        },
        [s .. "07"] = {
            description = "table.get_or_default - key exists",
            run = function()
                return table.get_or_default({ key = "value" }, "key", "default")
            end,
            expected = "value"
        },
        [s .. "08"] = {
            description = "table.get_or_default - key does not exist",
            run = function()
                return table.get_or_default({ key = "value" }, "other_key", "default")
            end,
            expected = "default"
        },
        [s .. "09"] = {
            description = "table.get_or_default - table is nil",
            run = function()
                return table.get_or_default(nil, "key", "default")
            end,
            expected = "default"
        },
        [s .. "10"] = {
            description = "table.is_nil_or_empty - table is nil",
            run = function()
                return table.is_nil_or_empty(nil)
            end,
            expected = true
        },
        [s .. "11"] = {
            description = "table.is_nil_or_empty - table is empty",
            run = function()
                return table.is_nil_or_empty({})
            end,
            expected = true
        },
        [s .. "12"] = {
            description = "table.is_nil_or_empty - table is not empty",
            run = function()
                return table.is_nil_or_empty({ "a" })
            end,
            expected = false
        },
        [s .. "13"] = {
            description = "table.merge - merge two tables",
            run = function()
                local target = { a = 1, b = 2 }
                local source = { c = 3, d = 4 }
                table.merge(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ a = 1, b = 2, c = 3, d = 4 })
        },
        [s .. "14"] = {
            description = "table.merge - overwrite existing key",
            run = function()
                local target = { a = 1, b = 2 }
                local source = { b = 99, c = 3 }
                table.merge(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ a = 1, b = 99, c = 3 })
        },
        [s .. "15"] = {
            description = "table.size - size of a sequential table",
            run = function()
                return table.size({ "a", "b", "c" })
            end,
            expected = 3
        },
        [s .. "16"] = {
            description = "table.size - size of a table with string keys",
            run = function()
                return table.size({ a = 1, b = 2 })
            end,
            expected = 2
        },
        [s .. "17"] = {
            description = "table.size - size of an empty table",
            run = function()
                return table.size({})
            end,
            expected = 0
        },
        [s .. "18"] = {
            description = "table.remove_duplicates - double a",
            run = function()
                return table.to_string(table.remove_duplicates({ "a", "a" }))
            end,
            expected = table.to_string({ "a" })
        },
        [s .. "19"] = {
            description = "table.remove_duplicates - double a and one b",
            run = function()
                return table.to_string(table.remove_duplicates({ "a", "b", "a" }))
            end,
            expected = table.to_string({ "a", "b" })
        },
        [s .. "20"] = {
            description = "table.remove_duplicates - triple a, one b and two c",
            run = function()
                return table.to_string(table.remove_duplicates({ "a", "b", "c", "c", "a" }))
            end,
            expected = table.to_string({ "a", "b", "c" })
        },
        [s .. "21"] = {
            description = "table.contains - value present in and an integer",
            run = function()
                return table.contains({ false, 1, "2", 3, 4 }, 3)
            end,
            expected = true
        },
        [s .. "22"] = {
            description = "table.has_key - key exists",
            run = function()
                return table.has_key({ key = "value" }, "key")
            end,
            expected = true
        },
        [s .. "23"] = {
            description = "table.has_key - key does not exist",
            run = function()
                return table.has_key({ key = "value" }, "other_key")
            end,
            expected = false
        },
        [s .. "24"] = {
            description = "table.has_key - table is nil",
            run = function()
                return table.has_key(nil, "key")
            end,
            expected = false
        },
        [s .. "25"] = {
            description = "table.remove_duplicates - empty table",
            run = function()
                return table.to_string(table.remove_duplicates({}))
            end,
            expected = table.to_string({})
        },
        [s .. "26"] = {
            description = "table.remove_duplicates - nil table",
            run = function()
                return table.to_string(table.remove_duplicates(nil))
            end,
            expected = table.to_string({})
        },
        [s .. "27"] = {
            description = "table.remove_duplicates - already unique",
            run = function()
                return table.to_string(table.remove_duplicates({ "x", "y", "z" }))
            end,
            expected = table.to_string({ "x", "y", "z" })
        },
        [s .. "28"] = {
            description = "table.create - preallocated table length and insertion",
            run = function()
                local t = table.create(10, 5)
                local initial_len = #t
                t[#t + 1] = "first"
                t[#t + 1] = "second"
                return initial_len == 0 and #t == 2 and t[1] == "first" and t[2] == "second"
            end,
            expected = true
        },
        [s .. "29"] = {
            description = "table.sub - default arguments",
            run = function()
                return table.to_string(table.sub({ "a", "b", "c" }))
            end,
            expected = table.to_string({ "a", "b", "c" })
        },
        [s .. "30"] = {
            description = "table.sub - specific start and end",
            run = function()
                return table.to_string(table.sub({ "a", "b", "c", "d" }, 2, 3))
            end,
            expected = table.to_string({ "b", "c" })
        },
        [s .. "31"] = {
            description = "table.sub - negative start",
            run = function()
                return table.to_string(table.sub({ "a", "b", "c", "d" }, -2))
            end,
            expected = table.to_string({ "c", "d" })
        },
        [s .. "32"] = {
            description = "table.sub - negative end",
            run = function()
                return table.to_string(table.sub({ "a", "b", "c", "d" }, 1, -2))
            end,
            expected = table.to_string({ "a", "b", "c" })
        },
        [s .. "33"] = {
            description = "table.sub - out of bounds positive",
            run = function()
                return table.to_string(table.sub({ "a", "b" }, 1, 5))
            end,
            expected = table.to_string({ "a", "b" })
        },
        [s .. "34"] = {
            description = "table.sub - out of bounds negative",
            run = function()
                return table.to_string(table.sub({ "a", "b" }, -5, -4))
            end,
            expected = table.to_string({})
        },
        [s .. "35"] = {
            description = "table.sub - zero index",
            run = function()
                return table.to_string(table.sub({ "a", "b" }, 0, 1))
            end,
            expected = table.to_string({ "a" })
        },
        [s .. "36"] = {
            description = "table.sub - empty table",
            run = function()
                return table.to_string(table.sub({}))
            end,
            expected = table.to_string({})
        },
        [s .. "37"] = {
            description = "table.sub - error on nil table",
            run = function()
                local status, err = pcall(table.sub, nil)
                return status == false and string.find(err, "table.sub expects a table") ~= nil
            end,
            expected = true
        },
    },
}
