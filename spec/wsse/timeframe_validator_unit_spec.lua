local wsse_timeframe_validator = require "kong.plugins.wsse.timeframe_validator"
local date = require "date"

describe("wsse timeframe validator", function()

    local timeframe_validator = wsse_timeframe_validator()

    describe("#validate", function()

        it("raises error when timestamp string is not in valid format", function()
            assert.has_error(function() timeframe_validator:validate("not valid timeframe string") end, {msg = "Timeframe is invalid."})
        end)

        local formats = {
            date(false):fmt('%Y-%m-%dT%H:%M:%S%z'),
            date(true):fmt('%Y-%m-%dT%H:%M:%SZ'),
            date(true):fmt('%Y-%m-%dT%H:%M:%\fZ'),
            date(true):addhours(2):fmt('%Y-%m-%dT%H:%M:%S+02:00'),
            date(true):addhours(-2):fmt('%Y-%m-%dT%H:%M:%S-02:00'),
        }

        for i, format in ipairs(formats) do
            it("should not raise error for format #" .. i .. " (" .. format .. ")", function()
                assert.has_no.errors(function() timeframe_validator:validate(format) end)
            end)
        end

        it("raises error when the given timestamp is more than 5 minutes ahead", function()
            local five_minutes_from_now = date(true):addseconds(301):fmt('${iso}Z')
            assert.has_error(function() timeframe_validator:validate(five_minutes_from_now) end, {msg = "Timeframe is invalid."})
        end)

        it("raises error when the given timestamp is more than 5 minutes behind", function()
            local five_minutes_from_now = date(true):addseconds(-301):fmt('${iso}Z')
            assert.has_error(function() timeframe_validator:validate(five_minutes_from_now) end, {msg = "Timeframe is invalid."})
        end)

        it("returns true when validation succeeds", function()
            local valid_timestamp = date(true):addseconds(-10):fmt('${iso}Z')
            assert.True(timeframe_validator:validate(valid_timestamp))
        end)

        it("returns true when created date is greater than actual date more then treshold but less than 1 hour plus treshold and actual date is daylight saving day", function()
            local valid_timestamp = date(2017,10,29,1,59,17):fmt('${iso}Z')
            local now = os.time{year = 2017, month = 10, day = 29, hour = 4, min = 1, sec = 35}
            local old_time = os.time

            os.time = function()
                return now
            end

            assert.True(timeframe_validator:validate(valid_timestamp))

            os.time = old_time
        end)

        it("raises error when created date is greater than actual date more then treshold plus 1 hour and actual date is daylight saving day", function()
            local invalid_timestamp = date(2017,10,29,1,59,17):fmt('${iso}Z')
            local now = os.time{year = 2017, month = 10, day = 29, hour = 4, min = 5, sec = 35}
            local old_time = os.time

            os.time = function()
                return now
            end

            assert.has.error(function() timeframe_validator:validate(invalid_timestamp) end, {msg = "Timeframe is invalid."})

            os.time = old_time
        end)

        it("not raises error when timeframe is not valid with non strict mode", function ()
            local invalid_timestamp = date(2017,10,29,1,59,17):fmt('${iso}Z')

            assert.has_no.error(function() timeframe_validator:validate(invalid_timestamp, false) end)
        end)

    end)

end)
