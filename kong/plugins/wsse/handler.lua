local constants = require "kong.constants"
local responses = require "kong.tools.responses"
local BasePlugin = require "kong.plugins.base_plugin"
local ConsumerDb = require "kong.plugins.wsse.consumer_db"
local KeyDb = require "kong.plugins.wsse.key_db"
local Logger = require "logger"
local Wsse = require "kong.plugins.wsse.wsse_lib"

local WsseHandler = BasePlugin:extend()

WsseHandler.PRIORITY = 1006

local function set_consumer(consumer, wsse_key)
    ngx.req.set_header(constants.HEADERS.CONSUMER_ID, consumer.id)
    ngx.req.set_header(constants.HEADERS.CONSUMER_CUSTOM_ID, consumer.custom_id)
    ngx.req.set_header(constants.HEADERS.CONSUMER_USERNAME, consumer.username)
    ngx.ctx.authenticated_consumer = consumer

    if wsse_key then
        ngx.req.set_header(constants.HEADERS.CREDENTIAL_USERNAME, wsse_key.username)
        ngx.req.set_header(constants.HEADERS.ANONYMOUS, nil)
        ngx.ctx.authenticated_credential = wsse_key
    else
        ngx.req.set_header(constants.HEADERS.ANONYMOUS, true)
    end
end

local function do_authentication(wsse_header_string, timeframe_validation_treshhold_in_minutes, consumer_db)
  local wsse_key
  local wsse = Wsse:new(KeyDb(), timeframe_validation_treshhold_in_minutes)

  local success, err = pcall(function()
    wsse_key = wsse:authenticate(wsse_header_string)
  end)

  if not success then
    Logger.getInstance(ngx):logInfo({status = 401, msg = err.msg})
    return responses.send(401, err.msg)
  else
    Logger.getInstance(ngx):logInfo({msg = "WSSE authentication was successful."})
    local consumer = consumer_db.find_by_id(wsse_key.consumer_id)
    set_consumer(consumer, wsse_key)
  end
end

function WsseHandler:new()
    WsseHandler.super.new(self, "wsse")
end

function WsseHandler:access(conf)
    WsseHandler.super.access(self)

    if ngx.ctx.authenticated_credential and conf.anonymous ~= nil then
        -- we're already authenticated, and we're configured for using anonymous,
        -- hence we're in a logical OR between auth methods and we're already done.
        return
    end

    local wsse_header_string = ngx.req.get_headers()["X-WSSE"]
    local consumer_db = ConsumerDb()

    local success, err = pcall(function()
        if (wsse_header_string) then
            do_authentication(wsse_header_string, conf.timeframe_validation_treshhold_in_minutes, consumer_db)
        elseif (conf.anonymous == nil) then
            local error_message = "WSSE authentication header not found!"
            Logger.getInstance(ngx):logInfo({status = 401, msg = error_message})
            return responses.send(401, error_message)
        else
            local consumer = consumer_db.find_by_id(conf.anonymous, true)
            set_consumer(consumer)
            Logger.getInstance(ngx):logInfo({msg = "WSSE authentication skipped."})
        end
    end)

    if not success then
        error(err)
        Logger.getInstance(ngx).logError({
            msg = err.msg
        })
        return responses.send(500, "Unexpected error occurred.")
    end
end

return WsseHandler
