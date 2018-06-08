local singletons = require "kong.singletons"
local Object = require("classic")
local Logger = require "logger"

local KeyDb = Object:extend()

local function load_credential(username)
    local rows, err = singletons.dao.wsse_keys:find_all {key = username}
    if err then
        return nil, err
    end
    return rows[1]
end

function KeyDb.find_by_username(username)
    if username == nil then
        Logger.getInstance(ngx):logWarning({msg = "Username is required."})
        error({msg = "Username is required."})
    end

    local wsse_cache_key = singletons.dao.wsse_keys:cache_key(username)
    local wsse_key, err = singletons.cache:get(wsse_cache_key, nil, load_credential, username)

    if err then
        Logger.getInstance(ngx):logError(err)
        error({msg = "WSSE key could not be loaded from DB."})
    end

    if wsse_key == nil then
        Logger.getInstance(ngx):logWarning({msg = "WSSE key can not be found."})
        error({msg = "WSSE key can not be found."})
    end

    return wsse_key
end

return KeyDb