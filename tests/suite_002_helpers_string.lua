return {
    -- Tests for string helper functions.
    -- config = none,
    tests = {
        T00201 = {
            description = "string.begins_with - 'Peace begins with a smile.' begins with 'Peace'",
            run = function()
                return string.begins_with("Peace begins with a smile.", "Peace")
            end,
            expected = true
        },
        T00202 = {
            description = "string.begins_with - 'Peace begins with a smile.' begins not with 'peace'",
            run = function()
                return string.begins_with("Peace begins with a smile.", "peace")
            end,
            expected = false
        },
        T00203 = {
            description = "string.ends_with - 'Peace begins with a smile.' ends with 'smile.'",
            run = function()
                return string.ends_with("Peace begins with a smile.", "smile.")
            end,
            expected = true
        },
        T00204 = {
            description = "string.ends_with - 'Peace begins with a smile.' ends not with 'smile'",
            run = function()
                return string.ends_with("Peace begins with a smile.", "smile")
            end,
            expected = false
        },
        T00205 = {
            description = "string.is_nil_or_empty - string is empty",
            run = function()
                return string.is_nil_or_empty("")
            end,
            expected = true
        },
        T00206 = {
            description = "string.is_nil_or_empty - string is nil",
            run = function()
                return string.is_nil_or_empty(nil)
            end,
            expected = true
        },
        T00207 = {
            description = "string.is_nil_or_empty - string is not nil or empty",
            run = function()
                return string.is_nil_or_empty("Peace.")
            end,
            expected = false
        },
        T00208 = {
            description = "string.begins_with - with empty prefix",
            run = function()
                return string.begins_with("some string", "")
            end,
            expected = true
        },
        T00209 = {
            description = "string.ends_with - with prefix longer than string",
            run = function()
                return string.ends_with("short", "longer_string")
            end,
            expected = false
        },
        T0020A = {
            description = "string.begins_with - with empty string",
            run = function()
                return string.begins_with("", "not empty")
            end,
            expected = false
        },
        T0020B = {
            description = "string.lower (library) - simple test case",
            run = function()
                return string.lower("PodScript is CoOl!1!")
            end,
            expected = "podscript is cool!1!"
        },
        T0020C = {
            description = "string.gsup (library) - replace multiple spaces",
            run = function()
                return string.gsub("The  anwser is 42! ", " ", "_")
            end,
            expected = "The__anwser_is_42!_"
        },
        T0020D = {
            description = "string.trim - remove leading and trailing spaces",
            run = function()
                return string.trim("  The  anwser is 42! ")
            end,
            expected = "The  anwser is 42!"
        },
    },
}
