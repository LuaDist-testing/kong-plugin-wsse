local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"
local responses = require "kong.tools.responses"
local wsse_lib = require "kong.plugins.wsse.wsse_lib"
local KeyDb = require "kong.plugins.wsse.key_db"

local WsseHandler = BasePlugin:extend()

WsseHandler.PRIORITY = 2000

function WsseHandler:new()
    WsseHandler.super.new(self, "wsse")
end

function WsseHandler:access(conf)
    WsseHandler.super.access(self)
    local wsse_header_string = ngx.req.get_headers()["X-WSSE"]

    if (wsse_header_string) then
        ngx.req.set_header(constants.HEADERS.ANONYMOUS, nil)
        local wsse = wsse_lib:new(KeyDb(), conf.timeframe_validation_treshhold_in_minutes)
        local success, error = pcall(function()
            wsse:authenticate(wsse_header_string)
        end)

        if not success then
            return responses.send(401, error)
        end
    elseif (conf.anonymous == nil) then
        return responses.send(401, "WSSE header not found!")
    else
        ngx.req.set_header(constants.HEADERS.ANONYMOUS, true)
    end
end

return WsseHandler
