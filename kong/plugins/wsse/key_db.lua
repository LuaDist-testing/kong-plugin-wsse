local singletons = require "kong.singletons"
local Object = require("kong.plugins.wsse.classic")

local KeyDb = Object:extend()

function KeyDb.find_by_username(username)
    if username == nil then
        error("Username is required!")
    end

    local rows, err = singletons.dao.wsse_keys:find_all {key = username}
    if err or rows[1] == nil then
        error("Username could not be found!")
    end

    return rows[1]['secret']
end

return KeyDb