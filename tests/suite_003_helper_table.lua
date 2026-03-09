return {
    -- Tests for table helper functions.
    -- config = none,
    tests = {
        T00301 = {
            description = "table.append - append two tables",
            run = function()
                local target = { "a", "b" }
                local source = { "c", "d" }
                table.append(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b", "c", "d" })
        },
        T00302 = {
            description = "table.append - append to an empty table",
            run = function()
                local target = {}
                local source = { "a", "b" }
                table.append(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b" })
        },
        T00303 = {
            description = "table.append - append nil source",
            run = function()
                local target = { "a", "b" }
                table.append(target, nil)
                return table.to_string(target)
            end,
            expected = table.to_string({ "a", "b" })
        },
        T00304 = {
            description = "table.contains - value is present",
            run = function()
                return table.contains({ "a", "b", "c" }, "b")
            end,
            expected = true
        },
        T00305 = {
            description = "table.contains - value is not present",
            run = function()
                return table.contains({ "a", "b", "c" }, "d")
            end,
            expected = false
        },
        T00306 = {
            description = "table.contains - table is nil",
            run = function()
                return table.contains(nil, "a")
            end,
            expected = false
        },
        T00307 = {
            description = "table.get_or_default - key exists",
            run = function()
                return table.get_or_default({ key = "value" }, "key", "default")
            end,
            expected = "value"
        },
        T00308 = {
            description = "table.get_or_default - key does not exist",
            run = function()
                return table.get_or_default({ key = "value" }, "other_key", "default")
            end,
            expected = "default"
        },
        T00309 = {
            description = "table.get_or_default - table is nil",
            run = function()
                return table.get_or_default(nil, "key", "default")
            end,
            expected = "default"
        },
        T0030A = {
            description = "table.is_nil_or_empty - table is nil",
            run = function()
                return table.is_nil_or_empty(nil)
            end,
            expected = true
        },
        T0030B = {
            description = "table.is_nil_or_empty - table is empty",
            run = function()
                return table.is_nil_or_empty({})
            end,
            expected = true
        },
        T0030C = {
            description = "table.is_nil_or_empty - table is not empty",
            run = function()
                return table.is_nil_or_empty({ "a" })
            end,
            expected = false
        },
        T0030D = {
            description = "table.merge - merge two tables",
            run = function()
                local target = { a = 1, b = 2 }
                local source = { c = 3, d = 4 }
                table.merge(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ a = 1, b = 2, c = 3, d = 4 })
        },
        T0030E = {
            description = "table.merge - overwrite existing key",
            run = function()
                local target = { a = 1, b = 2 }
                local source = { b = 99, c = 3 }
                table.merge(target, source)
                return table.to_string(target)
            end,
            expected = table.to_string({ a = 1, b = 99, c = 3 })
        },
        T0030F = {
            description = "table.size - size of a sequential table",
            run = function()
                return table.size({ "a", "b", "c" })
            end,
            expected = 3
        },
        T00310 = {
            description = "table.size - size of a table with string keys",
            run = function()
                return table.size({ a = 1, b = 2 })
            end,
            expected = 2
        },
        T00311 = {
            description = "table.size - size of an empty table",
            run = function()
                return table.size({})
            end,
            expected = 0
        }
    },
}
